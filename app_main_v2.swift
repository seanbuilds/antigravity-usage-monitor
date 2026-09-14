// v2 – Native macOS Swift runner with live Menu Bar status item & Dock integration
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
    let groups: [Group]?
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    var statusItem: NSStatusItem!
    var latestQuota: QuotaData?
    var pollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure background daemon is active
        ensureDaemonRunning()

        // 1. Configure Window
        let rect = NSRect(x: 0, y: 0, width: 480, height: 660)
        window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Antigravity Usage"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(red: 0.05, green: 0.07, blue: 0.09, alpha: 1.0)
        window.minSize = NSSize(width: 420, height: 500)
        window.delegate = self

        // 2. Configure WKWebView
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        webView = WKWebView(frame: window.contentView!.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground") // Transparent background

        window.contentView?.addSubview(webView)

        // Load index.html from app bundle Resources or local fallback
        if let resourcePath = Bundle.main.path(forResource: "index", ofType: "html") {
            let fileUrl = URL(fileURLWithPath: resourcePath)
            webView.loadFileURL(fileUrl, allowingReadAccessTo: fileUrl.deletingLastPathComponent())
        } else {
            let devUrl = URL(fileURLWithPath: "/Users/dad/git/antigravity-usage-monitor/index_v1.html")
            webView.loadFileURL(devUrl, allowingReadAccessTo: devUrl.deletingLastPathComponent())
        }

        // 3. Setup Menu Bar Status Item
        setupStatusBar()

        // 4. Setup Main App Menu
        setupMainMenu()

        // 5. Initial background quota poll & schedule timer
        fetchLatestQuota()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.fetchLatestQuota()
        }

        // Activate and show window on launch
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "✦ 95%"
            button.toolTip = "Antigravity Quota Monitor (Click to toggle window)"
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
            toggleWindow()
        }
    }

    func toggleWindow() {
        if window.isVisible && NSApp.isActive {
            window.orderOut(nil)
        } else {
            positionWindowNearStatusBar()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            // Trigger web view refresh
            webView.evaluateJavaScript("fetchQuota(false)", completionHandler: nil)
        }
    }

    func positionWindowNearStatusBar() {
        guard let button = statusItem.button, let buttonWindow = button.window, let screen = buttonWindow.screen else {
            window.center()
            return
        }

        let buttonFrameOnScreen = buttonWindow.convertToScreen(button.frame)
        let visibleFrame = screen.visibleFrame

        var targetX = buttonFrameOnScreen.midX - (window.frame.width / 2.0)
        let targetY = buttonFrameOnScreen.minY - window.frame.height - 4.0

        // Clamp to screen bounds
        if targetX + window.frame.width > visibleFrame.maxX {
            targetX = visibleFrame.maxX - window.frame.width - 12.0
        }
        if targetX < visibleFrame.minX {
            targetX = visibleFrame.minX + 12.0
        }

        window.setFrameOrigin(NSPoint(x: targetX, y: max(targetY, visibleFrame.minY + 10.0)))
    }

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

        menu.addItem(NSMenuItem.separator())

        if let groups = latestQuota?.groups, !groups.isEmpty {
            for grp in groups {
                let gName = grp.displayName ?? grp.name ?? "Models"
                for b in grp.buckets ?? [] {
                    let bName = b.displayName ?? b.label ?? b.kind ?? "Limit"
                    let frac = b.remainingFraction ?? 1.0
                    let pctStr = String(format: "%.1f%%", frac * 100)
                    let subItem = NSMenuItem(title: "\(gName) (\(bName)): \(pctStr)", action: nil, keyEquivalent: "")
                    subItem.isEnabled = false
                    menu.addItem(subItem)
                }
            }
            menu.addItem(NSMenuItem.separator())
        }

        let openItem = NSMenuItem(title: "Open Dashboard Window", action: #selector(openWindowFromMenu), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)

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

    @objc func openWindowFromMenu() {
        toggleWindow()
    }

    @objc func refreshDataFromMenu() {
        fetchLatestQuota(force: true)
        webView.evaluateJavaScript("fetchQuota(true)", completionHandler: nil)
    }

    @objc func copyRemoteCmd() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("curl -s http://192.168.4.98:3007", forType: .string)
    }

    func fetchLatestQuota(force: Bool = false) {
        guard let url = URL(string: force ? "http://127.0.0.1:3007/quota?refresh=1" : "http://127.0.0.1:3007/quota") else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else { return }
            do {
                let decoded = try JSONDecoder().decode(QuotaData.self, from: data)
                DispatchQueue.main.async {
                    self?.latestQuota = decoded
                    self?.updateStatusBarTitle(with: decoded)
                }
            } catch {
                // Ignore parse errors on poll
            }
        }.resume()
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
        statusItem.button?.toolTip = "Antigravity Quota: \(pct)% remaining (Click to view)"
    }

    func setupMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        appMenu.addItem(withTitle: "About Antigravity Usage", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())

        let reloadItem = NSMenuItem(title: "Refresh Data", action: #selector(refreshDataFromMenu), keyEquivalent: "r")
        reloadItem.target = self
        appMenu.addItem(reloadItem)
        appMenu.addItem(NSMenuItem.separator())

        appMenu.addItem(withTitle: "Hide Antigravity Usage", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [NSEvent.ModifierFlags.command, NSEvent.ModifierFlags.option]
        appMenu.addItem(hideOthers)
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Antigravity Usage", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let windowMenuItem = NSMenuItem()
        mainMenu.addItem(windowMenuItem)
        let windowMenu = NSMenu(title: "Window")
        windowMenuItem.submenu = windowMenu
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")

        NSApp.mainMenu = mainMenu
    }

    func ensureDaemonRunning() {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "curl -s --connect-timeout 1 http://127.0.0.1:3007/healthz || launchctl load ~/Library/LaunchAgents/com.antigravity.usage.plist 2>/dev/null"]
        task.launch()
    }

    // Dock click reopen handler: unminimize or show
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            window.center()
            window.makeKeyAndOrderFront(nil)
        } else {
            window.orderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
        return true
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Hide window instead of terminating so Menu Bar icon remains live
        window.orderOut(nil)
        return false
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
