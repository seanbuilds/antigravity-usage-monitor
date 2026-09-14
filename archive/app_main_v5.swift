// v5 – Native macOS Menu Bar Popover with Unsnap & Desktop Widget
import Cocoa
import WebKit

struct QuotaData: Decodable {
    struct Group: Decodable {
        let displayName: String?
        let name: String?
        let description: String?
        let models: String?
        struct Bucket: Decodable {
            let displayName: String?
            let label: String?
            let kind: String?
            let window: String?
            let remainingFraction: Double?
            let resetsInSeconds: Int?
            let resetTime: String?
            let resetAt: String?
        }
        let buckets: [Bucket]?
    }
    let account: String?
    let tier: String?
    let tierDescription: String?
    let remoteCommand: String?
    let localIp: String?
    let groups: [Group]?
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSPopoverDelegate, NSWindowDelegate, WKScriptMessageHandler {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var webView: WKWebView!
    var detachedWindow: NSPanel?
    var isUnsnapped: Bool = false

    // Desktop Widget
    var widgetWindow: NSPanel?
    var widgetWebView: WKWebView?
    var isWidgetVisible: Bool = false

    var latestQuota: QuotaData?
    var latestRawJson: String?
    var pollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        ensureDaemonRunning()

        // 1. Configure Main Dashboard WKWebView
        let popoverWidth: CGFloat = 360
        let popoverHeight: CGFloat = 430

        let contentController = WKUserContentController()
        contentController.add(self, name: "copyToClipboard")
        contentController.add(self, name: "appAction")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: popoverWidth, height: popoverHeight), configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")

        // 2. Configure Native Popover
        popover = NSPopover()
        popover.appearance = NSAppearance(named: .darkAqua)
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: popoverWidth, height: popoverHeight)
        popover.delegate = self

        let popoverVC = NSViewController()
        popoverVC.view = webView
        popover.contentViewController = popoverVC

        // Load index.html
        loadMainHTML()

        // 3. Status Bar Item
        setupStatusBar()

        // 4. Main Menu
        setupMainMenu()

        // 5. System Sleep / Wake Observer
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        // 6. Common RunLoop Mode Polling Timer (30s)
        fetchLatestQuota()
        let timer = Timer(timeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetchLatestQuota()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer

        // Snap out popover immediately on first launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.snapOutPopover()
        }
    }

    func loadMainHTML() {
        if let resourcePath = Bundle.main.path(forResource: "index", ofType: "html") {
            let fileUrl = URL(fileURLWithPath: resourcePath)
            webView.loadFileURL(fileUrl, allowingReadAccessTo: fileUrl.deletingLastPathComponent())
        } else {
            let devUrl = URL(fileURLWithPath: "/Users/dad/git/antigravity-usage-monitor/index_v5.html")
            webView.loadFileURL(devUrl, allowingReadAccessTo: devUrl.deletingLastPathComponent())
        }
    }

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "✦ --%"
            button.toolTip = "Antigravity Quota (Click to snap out dashboard)"
            button.target = self
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showContextMenu()
        } else {
            if isUnsnapped, let win = detachedWindow, win.isVisible {
                win.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            } else {
                togglePopover(sender)
            }
        }
    }

    // ========================================================================
    // Popover & Unsnap / Detach Architecture
    // ========================================================================

    func snapOutPopover() {
        guard let button = statusItem.button else { return }
        if isUnsnapped {
            detachedWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        if !popover.isShown {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            pushQuotaToWebView()
        }
    }

    @objc func togglePopover(_ sender: Any?) {
        if isUnsnapped {
            if let win = detachedWindow {
                if win.isVisible {
                    win.orderOut(nil)
                } else {
                    win.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
            return
        }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            snapOutPopover()
        }
    }

    // Native Drag-to-detach Delegate
    nonisolated func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return true
    }

    nonisolated func detachableWindow(for popover: NSPopover) -> NSWindow? {
        return MainActor.assumeIsolated {
            return self.detachToWindow()
        }
    }

    // Detach into floating window
    @discardableResult
    func detachToWindow() -> NSWindow {
        if let existing = detachedWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return existing
        }

        isUnsnapped = true

        // Create detached window
        let winWidth: CGFloat = 360
        let winHeight: CGFloat = 430

        var origin = NSPoint(x: 250, y: 350)
        if let button = statusItem.button, let win = button.window {
            let buttonRect = win.convertToScreen(button.bounds)
            origin = NSPoint(x: max(20, buttonRect.origin.x - (winWidth / 2)), y: max(40, buttonRect.origin.y - winHeight - 10))
        }

        let panel = NSPanel(
            contentRect: NSRect(origin: origin, size: NSSize(width: winWidth, height: winHeight)),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.backgroundColor = NSColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 0.95)
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.delegate = self

        // Reparent webView into detached window
        popover.contentViewController?.view = NSView()
        if popover.isShown {
            popover.close()
        }

        let contentVC = NSViewController()
        contentVC.view = webView
        panel.contentViewController = contentVC

        detachedWindow = panel
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Notify HTML UI of unsnapped state
        webView.evaluateJavaScript("setUnsnappedState(true)", completionHandler: nil)

        return panel
    }

    // Snap back into menu bar popover
    func snapBackToPopover() {
        guard isUnsnapped else { return }
        isUnsnapped = false

        if let win = detachedWindow {
            win.orderOut(nil)
            detachedWindow = nil
        }

        // Reparent webView back to popover
        popover.contentViewController?.view = webView
        webView.evaluateJavaScript("setUnsnappedState(false)", completionHandler: nil)

        // Snap out popover immediately
        snapOutPopover()
    }

    func windowWillClose(_ notification: Notification) {
        if let win = notification.object as? NSPanel, win == detachedWindow {
            snapBackToPopover()
        }
    }

    // ========================================================================
    // Desktop Widget Mode
    // ========================================================================

    func toggleDesktopWidget() {
        if isWidgetVisible {
            closeDesktopWidget()
        } else {
            showDesktopWidget()
        }
    }

    func showDesktopWidget() {
        if let win = widgetWindow {
            win.makeKeyAndOrderFront(nil)
            isWidgetVisible = true
            return
        }

        let widgetWidth: CGFloat = 240
        let widgetHeight: CGFloat = 124

        // Position on bottom right of main screen by default
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = NSPoint(x: screenFrame.maxX - widgetWidth - 30, y: screenFrame.minY + 40)

        let panel = NSPanel(
            contentRect: NSRect(origin: origin, size: NSSize(width: widgetWidth, height: widgetHeight)),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false

        let widgetController = WKUserContentController()
        widgetController.add(self, name: "appAction")

        let config = WKWebViewConfiguration()
        config.userContentController = widgetController

        let wWebView = WKWebView(frame: NSRect(x: 0, y: 0, width: widgetWidth, height: widgetHeight), configuration: config)
        wWebView.autoresizingMask = [.width, .height]
        wWebView.setValue(false, forKey: "drawsBackground")

        let vc = NSViewController()
        vc.view = wWebView
        panel.contentViewController = vc

        // Load widget.html
        if let resPath = Bundle.main.path(forResource: "widget", ofType: "html") {
            let fileUrl = URL(fileURLWithPath: resPath)
            wWebView.loadFileURL(fileUrl, allowingReadAccessTo: fileUrl.deletingLastPathComponent())
        } else {
            let devUrl = URL(fileURLWithPath: "/Users/dad/git/antigravity-usage-monitor/widget_v5.html")
            wWebView.loadFileURL(devUrl, allowingReadAccessTo: devUrl.deletingLastPathComponent())
        }

        widgetWindow = panel
        widgetWebView = wWebView
        isWidgetVisible = true
        panel.makeKeyAndOrderFront(nil)

        // Push current quota immediately to widget
        if let jsonStr = latestRawJson {
            wWebView.evaluateJavaScript("updateWidgetUI(\(jsonStr))", completionHandler: nil)
        }
    }

    func closeDesktopWidget() {
        widgetWindow?.orderOut(nil)
        isWidgetVisible = false
    }

    // ========================================================================
    // WKScriptMessageHandler (Native Bridge)
    // ========================================================================

    nonisolated func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        MainActor.assumeIsolated {
            if message.name == "copyToClipboard", let text = message.body as? String {
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(text, forType: .string)
            } else if message.name == "appAction", let dict = message.body as? [String: Any], let action = dict["action"] as? String {
                switch action {
                case "unsnap":
                    self.detachToWindow()
                case "snap":
                    self.snapBackToPopover()
                case "toggleWidget":
                    self.toggleDesktopWidget()
                case "closeWidget":
                    self.closeDesktopWidget()
                case "openFullApp":
                    self.snapOutPopover()
                default:
                    break
                }
            }
        }
    }

    // ========================================================================
    // Context Menu
    // ========================================================================

    func showContextMenu() {
        let menu = NSMenu()
        menu.delegate = self

        let titleItem = NSMenuItem(title: "Google Antigravity Quota", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        if let acc = latestQuota?.account {
            let accItem = NSMenuItem(title: "Account: \(acc)", action: nil, keyEquivalent: "")
            accItem.isEnabled = false
            menu.addItem(accItem)
        }

        if let tier = latestQuota?.tier {
            let tierItem = NSMenuItem(title: "Plan: \(tier)", action: nil, keyEquivalent: "")
            tierItem.isEnabled = false
            menu.addItem(tierItem)
        }

        menu.addItem(NSMenuItem.separator())

        if let groups = latestQuota?.groups, !groups.isEmpty {
            for grp in groups {
                let gName = grp.displayName ?? grp.name ?? "Models"
                for b in grp.buckets ?? [] {
                    let bName = b.displayName ?? b.label ?? b.kind ?? "Limit"
                    let frac = b.remainingFraction ?? 1.0
                    let pctStr = String(format: "%.0f%%", frac * 100)
                    let subItem = NSMenuItem(title: "\(gName) (\(bName)): \(pctStr)", action: nil, keyEquivalent: "")
                    subItem.isEnabled = false
                    menu.addItem(subItem)
                }
            }
            menu.addItem(NSMenuItem.separator())
        }

        // Unsnap / Snap option
        if isUnsnapped {
            let snapItem = NSMenuItem(title: "Snap Back to Menu Bar", action: #selector(snapMenuAction), keyEquivalent: "u")
            snapItem.target = self
            menu.addItem(snapItem)
        } else {
            let unsnapItem = NSMenuItem(title: "Unsnap to Floating Window", action: #selector(unsnapMenuAction), keyEquivalent: "u")
            unsnapItem.target = self
            menu.addItem(unsnapItem)
        }

        // Desktop Widget option
        let widgetItemTitle = isWidgetVisible ? "Hide Desktop Widget" : "Add Desktop Widget"
        let widgetItem = NSMenuItem(title: widgetItemTitle, action: #selector(widgetMenuAction), keyEquivalent: "w")
        widgetItem.target = self
        if isWidgetVisible {
            widgetItem.state = .on
        }
        menu.addItem(widgetItem)

        menu.addItem(NSMenuItem.separator())

        let refreshItem = NSMenuItem(title: "Refresh Now", action: #selector(refreshDataFromMenu), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        let copyItem = NSMenuItem(title: "Copy Remote Device curl Command", action: #selector(copyRemoteCmd), keyEquivalent: "c")
        copyItem.target = self
        menu.addItem(copyItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Antigravity Usage", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
    }

    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
    }

    @objc func unsnapMenuAction() {
        detachToWindow()
    }

    @objc func snapMenuAction() {
        snapBackToPopover()
    }

    @objc func widgetMenuAction() {
        toggleDesktopWidget()
    }

    @objc func refreshDataFromMenu() {
        fetchLatestQuota(force: true)
        webView.evaluateJavaScript("fetchQuota(true)", completionHandler: nil)
        widgetWebView?.evaluateJavaScript("fetchWidgetData()", completionHandler: nil)
    }

    @objc func copyRemoteCmd() {
        let cmd = latestQuota?.remoteCommand ?? "curl -s http://192.168.5.67:3007"
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(cmd, forType: .string)
    }

    // ========================================================================
    // Data Fetching & Sync
    // ========================================================================

    func fetchLatestQuota(force: Bool = false) {
        guard let url = URL(string: force ? "http://127.0.0.1:3007/quota?refresh=1" : "http://127.0.0.1:3007/quota") else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self?.statusItem.button?.toolTip = "Antigravity Quota (Offline - Retrying...)"
                }
                return
            }
            do {
                let jsonString = String(data: data, encoding: .utf8)
                let decoded = try JSONDecoder().decode(QuotaData.self, from: data)
                DispatchQueue.main.async {
                    self?.latestRawJson = jsonString
                    self?.latestQuota = decoded
                    self?.updateStatusBarTitle(with: decoded)
                    self?.pushQuotaToWidget(jsonString)
                }
            } catch {}
        }.resume()
    }

    func pushQuotaToWebView() {
        if let rawJson = latestRawJson {
            webView.evaluateJavaScript("renderQuota(\(rawJson))", completionHandler: nil)
        } else {
            webView.evaluateJavaScript("fetchQuota(false)", completionHandler: nil)
        }
    }

    func pushQuotaToWidget(_ rawJson: String?) {
        guard let json = rawJson, isWidgetVisible else { return }
        widgetWebView?.evaluateJavaScript("updateWidgetUI(\(json))", completionHandler: nil)
    }

    func updateStatusBarTitle(with quota: QuotaData) {
        var minFraction = 1.0
        for grp in quota.groups ?? [] {
            for b in grp.buckets ?? [] {
                if let frac = b.remainingFraction {
                    minFraction = min(minFraction, frac)
                }
            }
        }
        let pct = Int(round(minFraction * 100))
        statusItem.button?.title = "✦ \(pct)%"
        let tierName = quota.tier ?? "Google AI Ultra"
        statusItem.button?.toolTip = "Antigravity Quota (\(tierName)): \(pct)% remaining (Click to open)"
    }

    @objc func systemDidWake() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.fetchLatestQuota(force: true)
        }
    }

    func setupMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        appMenu.addItem(withTitle: "About Antigravity Usage", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())

        let unsnapItem = NSMenuItem(title: "Unsnap / Snap Window", action: #selector(toggleUnsnapMode), keyEquivalent: "u")
        unsnapItem.target = self
        appMenu.addItem(unsnapItem)

        let widgetItem = NSMenuItem(title: "Toggle Desktop Widget", action: #selector(widgetMenuAction), keyEquivalent: "w")
        widgetItem.target = self
        appMenu.addItem(widgetItem)

        let reloadItem = NSMenuItem(title: "Refresh Data", action: #selector(refreshDataFromMenu), keyEquivalent: "r")
        reloadItem.target = self
        appMenu.addItem(reloadItem)
        appMenu.addItem(NSMenuItem.separator())

        appMenu.addItem(withTitle: "Quit Antigravity Usage", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        NSApp.mainMenu = mainMenu
    }

    @objc func toggleUnsnapMode() {
        if isUnsnapped {
            snapBackToPopover()
        } else {
            detachToWindow()
        }
    }

    func ensureDaemonRunning() {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "curl -s --connect-timeout 1 http://127.0.0.1:3007/healthz || launchctl load ~/Library/LaunchAgents/com.antigravity.usage.plist 2>/dev/null"]
        task.launch()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if isUnsnapped, let win = detachedWindow {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            snapOutPopover()
        }
        return true
    }
}

@main
struct AppLauncher {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
