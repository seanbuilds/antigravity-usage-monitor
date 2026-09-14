// v7 – Hardened Native macOS Menu Bar Popover, Unsnap HUD & Desktop Widget with App Group sync
import Cocoa
import WebKit
import WidgetKit

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
    let port: Int?
    let credentialSource: String?
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

        // Load index.html strictly from App bundle (no hardcoded dev paths)
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

        // Snap out popover immediately on launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.snapOutPopover()
        }
    }

    func loadMainHTML() {
        guard let resourcePath = Bundle.main.path(forResource: "index", ofType: "html") else {
            fatalError("index.html not found in bundle — please rebuild the app bundle.")
        }
        let fileUrl = URL(fileURLWithPath: resourcePath)
        webView.loadFileURL(fileUrl, allowingReadAccessTo: fileUrl.deletingLastPathComponent())
    }

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "✦ --%"
            button.toolTip = "Antigravity Quota (Click to open dashboard)"
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

    nonisolated func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return true
    }

    nonisolated func detachableWindow(for popover: NSPopover) -> NSWindow? {
        if Thread.isMainThread {
            return MainActor.assumeIsolated {
                return self.detachToWindow()
            }
        } else {
            return DispatchQueue.main.sync {
                return self.detachToWindow()
            }
        }
    }

    @discardableResult
    func detachToWindow() -> NSWindow {
        if let existing = detachedWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return existing
        }

        isUnsnapped = true

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

        webView.evaluateJavaScript("setUnsnappedState(true)", completionHandler: nil)

        return panel
    }

    func snapBackToPopover() {
        guard isUnsnapped else { return }
        isUnsnapped = false

        if let win = detachedWindow {
            win.orderOut(nil)
            detachedWindow = nil
        }

        popover.contentViewController?.view = webView
        webView.evaluateJavaScript("setUnsnappedState(false)", completionHandler: nil)

        snapOutPopover()
    }

    func windowWillClose(_ notification: Notification) {
        if let win = notification.object as? NSPanel {
            if win == detachedWindow {
                snapBackToPopover()
            } else if win == widgetWindow {
                saveWidgetPosition(win)
                isWidgetVisible = false
            }
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

        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        var targetFrame = NSRect(x: screenFrame.maxX - widgetWidth - 30, y: screenFrame.minY + 40, width: widgetWidth, height: widgetHeight)

        // Restore saved position if available
        if let saved = UserDefaults.standard.string(forKey: "antigravity.widgetFrame") {
            let restored = NSRectFromString(saved)
            if restored.width > 0 && restored.height > 0 {
                targetFrame = restored
            }
        }

        let panel = NSPanel(
            contentRect: targetFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Desktop widget level: sits right above desktop icons, below regular application windows
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.delegate = self

        let widgetController = WKUserContentController()
        widgetController.add(self, name: "appAction")

        let config = WKWebViewConfiguration()
        config.userContentController = widgetController

        let wWebView = WKWebView(frame: NSRect(x: 0, y: 0, width: targetFrame.width, height: targetFrame.height), configuration: config)
        wWebView.autoresizingMask = [.width, .height]
        wWebView.setValue(false, forKey: "drawsBackground")

        let vc = NSViewController()
        vc.view = wWebView
        panel.contentViewController = vc

        guard let resPath = Bundle.main.path(forResource: "widget", ofType: "html") else {
            fatalError("widget.html not found in bundle — please rebuild the app bundle.")
        }
        let fileUrl = URL(fileURLWithPath: resPath)
        wWebView.loadFileURL(fileUrl, allowingReadAccessTo: fileUrl.deletingLastPathComponent())

        widgetWindow = panel
        widgetWebView = wWebView
        isWidgetVisible = true
        panel.makeKeyAndOrderFront(nil)

        if let jsonStr = latestRawJson {
            wWebView.evaluateJavaScript("updateWidgetUI(\(jsonStr))", completionHandler: nil)
        }
    }

    func closeDesktopWidget() {
        if let win = widgetWindow {
            saveWidgetPosition(win)
            win.orderOut(nil)
        }
        isWidgetVisible = false
    }

    private func saveWidgetPosition(_ panel: NSPanel) {
        UserDefaults.standard.set(NSStringFromRect(panel.frame), forKey: "antigravity.widgetFrame")
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
                case "quit":
                    NSApplication.shared.terminate(nil)
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

        if isUnsnapped {
            let snapItem = NSMenuItem(title: "Snap Back to Menu Bar", action: #selector(snapMenuAction), keyEquivalent: "u")
            snapItem.target = self
            menu.addItem(snapItem)
        } else {
            let unsnapItem = NSMenuItem(title: "Unsnap to Floating Window", action: #selector(unsnapMenuAction), keyEquivalent: "u")
            unsnapItem.target = self
            menu.addItem(unsnapItem)
        }

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
    // Data Fetching & App Group Sync
    // ========================================================================

    func fetchLatestQuota(force: Bool = false) {
        guard let url = URL(string: force ? "http://127.0.0.1:3007/quota?refresh=1" : "http://127.0.0.1:3007/quota") else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self?.statusItem.button?.title = "✦ offline"
                    self?.statusItem.button?.toolTip = "Antigravity Quota (Daemon offline — retrying...)"
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
                    self?.syncToAppGroup(decoded)
                }
            } catch {
                DispatchQueue.main.async {
                    self?.statusItem.button?.title = "✦ err"
                    self?.statusItem.button?.toolTip = "Antigravity Quota Parse Error: \(error.localizedDescription)"
                }
            }
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

    func syncToAppGroup(_ quota: QuotaData) {
        let pct = computeDisplayPercent(for: quota)
        if let defaults = UserDefaults(suiteName: "group.com.dad.aiusage") {
            defaults.set(pct, forKey: "antigravity.quotaPercent")
            defaults.set(Date(), forKey: "antigravity.lastUpdated")
            defaults.set(quota.tier ?? "Google AI Ultra", forKey: "antigravity.tier")
            defaults.set(quota.account ?? "Active Account", forKey: "antigravity.account")
            WidgetCenter.shared.reloadTimelines(ofKind: "AntigravityUsageWidget")
        }
    }

    func computeDisplayPercent(for quota: QuotaData) -> Int {
        var minFraction = 1.0
        var primaryFraction: Double?

        for grp in quota.groups ?? [] {
            let isGemini = (grp.displayName ?? grp.name ?? "").lowercased().contains("gemini")
            for b in grp.buckets ?? [] {
                if let frac = b.remainingFraction {
                    minFraction = min(minFraction, frac)
                    if isGemini && (b.window == "5h" || (b.displayName ?? "").contains("Five Hour")) {
                        primaryFraction = frac
                    }
                }
            }
        }
        let effective = primaryFraction ?? minFraction
        return Int(round(effective * 100))
    }

    func updateStatusBarTitle(with quota: QuotaData) {
        let pct = computeDisplayPercent(for: quota)
        statusItem.button?.title = "✦ \(pct)%"
        let tierName = quota.tier ?? "Google AI Ultra"
        statusItem.button?.toolTip = "Antigravity Quota (\(tierName)): \(pct)% primary capacity (Click to open)"
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
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", "curl -s --connect-timeout 1 http://127.0.0.1:3007/healthz || launchctl load ~/Library/LaunchAgents/com.antigravity.usage_v4.plist 2>/dev/null"]
        task.terminationHandler = { _ in }
        do {
            try task.run()
        } catch {
            NSLog("[Antigravity] Failed to run daemon check process: \(error)")
        }
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
