// v3 – Native macOS Menu Bar Popover Snap-out Architecture
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
    let groups: [Group]?
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSPopoverDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var webView: WKWebView!
    var latestQuota: QuotaData?
    var pollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure background daemon is running on port 3007
        ensureDaemonRunning()

        // 1. Configure WKWebView
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 440, height: 610), configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")

        // 2. Configure Native Popover (Snap-to-Menu-Bar)
        popover = NSPopover()
        popover.appearance = NSAppearance(named: .darkAqua)
        popover.behavior = .transient // Closes automatically when clicking outside
        popover.animates = true       // Smooth native snap-out animation
        popover.contentSize = NSSize(width: 440, height: 610)
        popover.delegate = self

        let popoverVC = NSViewController()
        popoverVC.view = webView
        popover.contentViewController = popoverVC

        // Load index.html from bundle
        if let resourcePath = Bundle.main.path(forResource: "index", ofType: "html") {
            let fileUrl = URL(fileURLWithPath: resourcePath)
            webView.loadFileURL(fileUrl, allowingReadAccessTo: fileUrl.deletingLastPathComponent())
        } else {
            let devUrl = URL(fileURLWithPath: "/Users/dad/git/antigravity-usage-monitor/index_v3.html")
            webView.loadFileURL(devUrl, allowingReadAccessTo: devUrl.deletingLastPathComponent())
        }

        // 3. Configure Status Bar Item
        setupStatusBar()

        // 4. Configure Application Menus
        setupMainMenu()

        // 5. Initial Quota Fetch and 30s Polling
        fetchLatestQuota()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.fetchLatestQuota()
        }

        // Initial launch: Snap out popover immediately ("tada")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.snapOutPopover()
        }
    }

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "✦ 94%"
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
            togglePopover(sender)
        }
    }

    func snapOutPopover() {
        guard let button = statusItem.button else { return }
        if !popover.isShown {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            webView.evaluateJavaScript("fetchQuota(false)", completionHandler: nil)
        }
    }

    @objc func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            snapOutPopover()
        }
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
                    let pctStr = String(format: "%.1f%%", frac * 100)
                    let subItem = NSMenuItem(title: "\(gName) (\(bName)): \(pctStr)", action: nil, keyEquivalent: "")
                    subItem.isEnabled = false
                    menu.addItem(subItem)
                }
            }
            menu.addItem(NSMenuItem.separator())
        }

        let snapItem = NSMenuItem(title: "Snap Out Dashboard", action: #selector(togglePopover(_:)), keyEquivalent: "s")
        snapItem.target = self
        menu.addItem(snapItem)

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
                // Ignore parse errors on periodic poll
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
        let tierName = quota.tier ?? "Google AI Ultra"
        statusItem.button?.toolTip = "Antigravity Quota (\(tierName)): \(pct)% remaining (Click to snap out)"
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

        NSApp.mainMenu = mainMenu
    }

    func ensureDaemonRunning() {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "curl -s --connect-timeout 1 http://127.0.0.1:3007/healthz || launchctl load ~/Library/LaunchAgents/com.antigravity.usage.plist 2>/dev/null"]
        task.launch()
    }

    // Dock click reopen handler: snaps out popover directly from menu bar
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        snapOutPopover()
        return true
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
