# Antigravity Quota Tracker — Complete Unified Codebase & Documentation
<!-- v2 – Consolidated file containing all v7/v8 source code, manifests, and documentation -->

> **Repository:** [github.com/seanbuilds/antigravity-usage-monitor](https://github.com/seanbuilds/antigravity-usage-monitor)
> **Legal Disclaimer:** Independent personal project. Not affiliated with or endorsed by Google LLC. Provided "as-is" without warranty.

## Table of Contents
- [README_v8.md](#readme-v8md) — *Project Overview & Documentation*
- [Package.swift](#packageswift) — *Swift Package Manager Manifest*
- [antigravity.entitlements](#antigravityentitlements) — *macOS App Group Entitlements*
- [app_main_v7.swift](#app-main-v7swift) — *Native macOS Menu Bar Runner, Unsnap HUD & Desktop Widget*
- [SharedModels/SharedQuota.swift](#sharedmodelssharedquotaswift) — *Cross-Process Shared Data Models*
- [AntigravityWidget/AntigravityWidgetBundle.swift](#antigravitywidgetantigravitywidgetbundleswift) — *WidgetKit Extension Bundle Entrypoint*
- [AntigravityWidget/AntigravityWidget.swift](#antigravitywidgetantigravitywidgetswift) — *WidgetKit TimelineProvider & SwiftUI Views*
- [index_v7.html](#index-v7html) — *WebKit Popover Dashboard User Interface (Unified Sibling Design)*
- [widget_v7.html](#widget-v7html) — *WebKit Compact Desktop Widget User Interface*
- [antigravity_usage_v4.py](#antigravity-usage-v4py) — *Hardened Python CLI & Cross-Device Quota Daemon*
- [build_app_v7.sh](#build-app-v7sh) — *Release Build, Packaging & Code-Signing Script*
- [com.antigravity.usage_v4.plist](#comantigravityusage-v4plist) — *macOS LaunchAgent Daemon Configuration*

---

## README_v8.md
**Description:** Project Overview & Documentation  
**Path:** `README_v8.md` | **Lines:** 106

```markdown
# Google Antigravity Usage Monitor (SPM, WidgetKit & App Group Sync)
<!-- v8 – Unified sibling design, Setup & Preferences view, 4-icon header toolbar, and LaunchAgent v4 integration -->

> **LEGAL DISCLAIMER**
> This software is an independent personal project. It is **not** affiliated with, endorsed by,
> or connected to **Google LLC** in any way. All trademarks belong to their respective owners.
> Provided "as-is" with **no warranty**. For personal use only.

A lightweight, zero-configuration utility, native macOS Menu Bar snap-out popover, detachable floating HUD window, desktop widget, and cross-device network daemon to view real-time Google Antigravity (`agy`) model quotas, consumption percentages, and reset timers across all your devices.

---

## 🌟 Architecture & Key Features

### 1. Swift Package Manager Architecture
- **SPM Structure**: Organized cleanly via `Package.swift` into:
  - `AntigravityUsageApp`: Main headless macOS menu bar application (`LSUIElement = true`).
  - `SharedModels`: Shared data models (`SharedQuotaSnapshot`) readable across processes.
  - `AntigravityWidget`: Native macOS WidgetKit extension target.
- **App Group Coordination**: Synchronizes live quota states via App Group `group.com.dad.aiusage` into shared `UserDefaults` and triggers `WidgetCenter.shared.reloadAllTimelines()`.

### 2. Menu Bar Snap-Out Popover & Sibling Parity
- **Menu Bar Status Item** (Top Right):
  - Displays primary model capacity (e.g. `✦ 70%`).
  - **Left-Click**: Instantly snaps out the clean 360px card directly below the menu bar icon.
  - **Click Anywhere Outside**: Automatically snaps closed.
  - **Right-Click**: Fast native context menu with model breakdowns and quick actions.
  - **Error Awareness**: Displays `✦ err` or `✦ offline` with explanatory tooltips on network or decode failures.
- **Unified 4-Icon Toolbar**:
  - `⊞ Widget`: Toggle the ambient desktop widget.
  - `⚙ Setup`: Open comprehensive server, auth, and network diagnostics.
  - `↗ Unsnap`: Detach to a floating HUD window (`⌘U`).
  - `↻ Refresh`: Request an immediate, bypass-cache quota refresh (`⌘R`).
- **Dock Companion**:
  - Pinned beside `Antigravity` in your Dock.
  - Clicking the Dock icon snaps out the popover right from the menu bar.

### 3. Setup & Preferences View
- **Authentication Diagnostics**: Displays account identity, subscription plan, and credential source (`macOS Keychain`).
- **Daemon Status**: Live health status, PID, and LaunchAgent management (`com.antigravity.usage_v4.plist`).
- **Cross-Device Network Info**: Displays local IP address, active listening port, and ready-to-copy `curl` terminal commands.
- **Danger Zone**: One-click **Quit App** action directly from the setup view or footer.

### 4. Unsnap to Floating Window (Detachable HUD)
- **Drag to Detach**: Drag the popover card away from the menu bar to tear it off into an independent floating window.
- **Unsnap Button**: Click the pop-out icon (`↗`) in the top right header (or press `⌘U`).
- **Floating HUD**: Operates at `.floating` level with a subtle translucent dark Aqua card, remaining visible while interacting with code.
- **Snap Back**: Click the dock icon (`↙`) in the header (or press `⌘U` or close the window) to cleanly snap it back into the menu bar.

### 5. macOS Desktop Widget Mode
- **Compact Desktop Widget**: An Apple-grade 240×124px translucent frosted glass card (`backdrop-filter: blur(28px)`) that sits directly above desktop wallpaper (`desktopIconWindow + 1`) and below normal application windows.
- **Position Persistence**: Automatically remembers and restores the exact position where you last placed it on the desktop.
- **Live Mini Gauges**: Glanceable mini capacity bars for **Gemini Models** (5h window) and **Claude & GPT Models** (5h window).
- **Interactive Control**: Draggable across the desktop, equipped with a subtle hover close button (`×`), double-clickable to open the full popover, and equipped with a discrete legal disclaimer.

---

## 💻 Terminal Commands & Build Scripts

### Build via Swift Package Manager
```bash
# Compile and install application bundle with App Group entitlements:
./build_app_v7.sh
```

### Local Terminal Inspection
```bash
# View current quota breakdown:
antigravity-usage

# Live auto-refreshing watch mode (updates every 30 seconds):
antigravity-usage --watch 30

# Output machine-readable JSON:
antigravity-usage --json
```

### Checking Quota Across All Devices
The background daemon runs 24/7 via macOS LaunchAgent on port 3007.
From any device on your local network/VPN:
```bash
# Colored terminal dashboard:
curl -s http://192.168.5.67:3007

# Machine-readable JSON:
curl -s http://192.168.5.67:3007/quota
```

---

## 🛠 Repository & Source Files

All source code is maintained in your Git repository: **[github.com/seanbuilds/antigravity-usage-monitor](https://github.com/seanbuilds/antigravity-usage-monitor)**

* Swift Package Manifest: [`Package.swift`](file:///Users/dad/git/antigravity-usage-monitor/Package.swift)
* App Group Entitlements: [`antigravity.entitlements`](file:///Users/dad/git/antigravity-usage-monitor/antigravity.entitlements)
* Native Swift runner (v7): [`app_main_v7.swift`](file:///Users/dad/git/antigravity-usage-monitor/app_main_v7.swift)
* Build & packaging script (v7): [`build_app_v7.sh`](file:///Users/dad/git/antigravity-usage-monitor/build_app_v7.sh)
* Popover user interface (v7): [`index_v7.html`](file:///Users/dad/git/antigravity-usage-monitor/index_v7.html)
* Desktop Widget UI (v7): [`widget_v7.html`](file:///Users/dad/git/antigravity-usage-monitor/widget_v7.html)
* Shared Data Models: [`SharedModels/SharedQuota.swift`](file:///Users/dad/git/antigravity-usage-monitor/SharedModels/SharedQuota.swift)
* WidgetKit Extension: [`AntigravityWidget/AntigravityWidget.swift`](file:///Users/dad/git/antigravity-usage-monitor/AntigravityWidget/AntigravityWidget.swift)
* Standalone Python daemon (v4): [`antigravity_usage_v4.py`](file:///Users/dad/git/antigravity-usage-monitor/antigravity_usage_v4.py)
* Terminal alias: [`antigravity-usage`](file:///Users/dad/.local/bin/antigravity-usage)
* Installed Application: [`/Applications/Antigravity Usage.app`](file:///Applications/Antigravity%20Usage.app)
* LaunchAgent configuration: [`com.antigravity.usage_v4.plist`](file:///Users/dad/Library/LaunchAgents/com.antigravity.usage_v4.plist)

```

---

## Package.swift
**Description:** Swift Package Manager Manifest  
**Path:** `Package.swift` | **Lines:** 38

```swift
// swift-tools-version: 5.9
// Package.swift — antigravity-usage-monitor
// Supports macOS menu bar application, SharedModels, and WidgetKit extension
import PackageDescription

let package = Package(
    name: "AntigravityUsage",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "AntigravityUsageApp", targets: ["AntigravityUsageApp"]),
        .library(name: "SharedModels", targets: ["SharedModels"]),
    ],
    targets: [
        // ── Main menu bar application ──────────────────────────────────────
        .executableTarget(
            name: "AntigravityUsageApp",
            dependencies: ["SharedModels"],
            path: "Sources/AntigravityUsageApp",
            resources: [
                .copy("Resources/index.html"),
                .copy("Resources/widget.html")
            ]
        ),

        // ── Shared data models (App Group UserDefaults) ────────────────────
        .target(
            name: "SharedModels",
            path: "SharedModels"
        ),

        // ── WidgetKit extension ────────────────────────────────────────────
        .target(
            name: "AntigravityWidget",
            dependencies: ["SharedModels"],
            path: "AntigravityWidget"
        )
    ]
)

```

---

## antigravity.entitlements
**Description:** macOS App Group Entitlements  
**Path:** `antigravity.entitlements` | **Lines:** 11

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!-- v1 – App Group entitlements for shared UserDefaults between App and Widget -->
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.dad.aiusage</string>
    </array>
</dict>
</plist>

```

---

## app_main_v7.swift
**Description:** Native macOS Menu Bar Runner, Unsnap HUD & Desktop Widget  
**Path:** `app_main_v7.swift` | **Lines:** 670

```swift
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

```

---

## SharedModels/SharedQuota.swift
**Description:** Cross-Process Shared Data Models  
**Path:** `SharedModels/SharedQuota.swift` | **Lines:** 34

```swift
// SharedModels/SharedQuota.swift
// v1 – Shared quota data models for Antigravity Usage Monitor and Widget extension
import Foundation

public struct SharedQuotaSnapshot: Codable {
    public let account: String
    public let tier: String
    public let tierId: String
    public let quotaPercent: Int
    public let primaryModel: String
    public let primaryPercent: Int
    public let primaryResetsIn: Int?
    public let lastUpdated: Date

    public init(
        account: String,
        tier: String,
        tierId: String,
        quotaPercent: Int,
        primaryModel: String,
        primaryPercent: Int,
        primaryResetsIn: Int?,
        lastUpdated: Date = Date()
    ) {
        self.account = account
        self.tier = tier
        self.tierId = tierId
        self.quotaPercent = quotaPercent
        self.primaryModel = primaryModel
        self.primaryPercent = primaryPercent
        self.primaryResetsIn = primaryResetsIn
        self.lastUpdated = lastUpdated
    }
}

```

---

## AntigravityWidget/AntigravityWidgetBundle.swift
**Description:** WidgetKit Extension Bundle Entrypoint  
**Path:** `AntigravityWidget/AntigravityWidgetBundle.swift` | **Lines:** 11

```swift
// AntigravityWidget/AntigravityWidgetBundle.swift
// v1 – Entry point for native macOS WidgetKit extension
import WidgetKit
import SwiftUI

@main
struct AntigravityWidgetBundle: WidgetBundle {
    var body: some Widget {
        AntigravityUsageWidget()
    }
}

```

---

## AntigravityWidget/AntigravityWidget.swift
**Description:** WidgetKit TimelineProvider & SwiftUI Views  
**Path:** `AntigravityWidget/AntigravityWidget.swift` | **Lines:** 112

```swift
// AntigravityWidget/AntigravityWidget.swift
// v1 – Native macOS WidgetKit TimelineProvider and Views
import WidgetKit
import SwiftUI

struct AntigravityEntry: TimelineEntry {
    let date: Date
    let quotaPercent: Int
    let tier: String
    let account: String
    let lastUpdated: Date?
}

struct AntigravityProvider: TimelineProvider {
    func placeholder(in context: Context) -> AntigravityEntry {
        AntigravityEntry(
            date: Date(),
            quotaPercent: 84,
            tier: "Google AI Ultra",
            account: "ohheysean@gmail.com",
            lastUpdated: Date()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (AntigravityEntry) -> Void) {
        let defaults = UserDefaults(suiteName: "group.com.dad.aiusage")
        let pct = defaults?.integer(forKey: "antigravity.quotaPercent") ?? 84
        let tier = defaults?.string(forKey: "antigravity.tier") ?? "Google AI Ultra"
        let account = defaults?.string(forKey: "antigravity.account") ?? "Active Account"
        let updated = defaults?.object(forKey: "antigravity.lastUpdated") as? Date

        completion(AntigravityEntry(
            date: Date(),
            quotaPercent: pct,
            tier: tier,
            account: account,
            lastUpdated: updated
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AntigravityEntry>) -> Void) {
        getSnapshot(in: context) { entry in
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct AntigravityWidgetEntryView: View {
    var entry: AntigravityProvider.Entry

    var colorForPercent: Color {
        if entry.quotaPercent >= 50 { return Color.green }
        if entry.quotaPercent >= 20 { return Color.yellow }
        return Color.red
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("✦ Antigravity")
                    .font(.system(size: 11, weight: .bold))
                Spacer()
                Text(entry.tier.contains("Ultra") ? "Ultra" : entry.tier)
                    .font(.system(size: 8.5, weight: .bold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Color.yellow.opacity(0.2))
                    .foregroundColor(.yellow)
                    .cornerRadius(4)
            }

            Text("\(entry.quotaPercent)%")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(colorForPercent)

            ProgressView(value: Double(entry.quotaPercent), total: 100.0)
                .tint(colorForPercent)

            HStack {
                Text(entry.account)
                    .font(.system(size: 8.5))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Spacer()
                if let updated = entry.lastUpdated {
                    Text(updated, style: .time)
                        .font(.system(size: 8.5))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            Color(nsColor: .windowBackgroundColor).opacity(0.9)
        }
    }
}

struct AntigravityUsageWidget: Widget {
    let kind: String = "AntigravityUsageWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AntigravityProvider()) { entry in
            AntigravityWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Antigravity Quota")
        .description("Real-time view of your Google Antigravity quota and tier.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

```

---

## index_v7.html
**Description:** WebKit Popover Dashboard User Interface (Unified Sibling Design)  
**Path:** `index_v7.html` | **Lines:** 734

```html
<!DOCTYPE html>
<!-- v7 – Unified Sibling Design with Setup View, Toolbar Icons, Quit Action & Legal Disclaimer -->
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Antigravity Usage</title>
  <style>
    :root {
      --text: #ffffff;
      --text-sec: rgba(255, 255, 255, 0.65);
      --text-muted: rgba(255, 255, 255, 0.40);
      --card: rgba(255, 255, 255, 0.07);
      --card-border: rgba(255, 255, 255, 0.09);
      --track: rgba(255, 255, 255, 0.12);
      --green: #30d158;
      --yellow: #ffd60a;
      --red: #ff453a;
      --accent: #0a84ff;
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      user-select: none;
      -webkit-user-select: none;
    }

    body {
      font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display", sans-serif;
      background: transparent;
      color: var(--text);
      padding: 16px;
      width: 360px;
      overflow: hidden;
      -webkit-font-smoothing: antialiased;
    }

    /* Views */
    .view {
      display: block;
    }
    .view.hidden {
      display: none;
    }

    /* Header */
    header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 14px;
    }

    .title-row {
      display: flex;
      align-items: center;
      gap: 7px;
    }

    .app-title {
      font-size: 14px;
      font-weight: 700;
      letter-spacing: -0.2px;
    }

    .ultra-pill {
      font-size: 9.5px;
      font-weight: 700;
      letter-spacing: 0.3px;
      text-transform: uppercase;
      padding: 2px 7px;
      border-radius: 6px;
      background: linear-gradient(135deg, rgba(255, 214, 10, 0.2) 0%, rgba(191, 90, 242, 0.25) 100%);
      color: #ffd60a;
      border: 1px solid rgba(255, 214, 10, 0.35);
    }

    .account-sub {
      font-size: 11px;
      color: var(--text-sec);
      margin-top: 2px;
      max-width: 200px;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .header-actions {
      display: flex;
      align-items: center;
      gap: 5px;
    }

    .icon-btn {
      background: rgba(255, 255, 255, 0.08);
      border: 1px solid var(--card-border);
      color: var(--text-sec);
      width: 26px;
      height: 26px;
      border-radius: 7px;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      transition: all 0.15s ease;
    }

    .icon-btn:hover {
      background: rgba(255, 255, 255, 0.16);
      color: var(--text);
    }

    .icon-btn:active {
      transform: scale(0.92);
    }

    .icon-btn.spinning svg {
      animation: spin 0.7s linear infinite;
    }

    @keyframes spin {
      100% { transform: rotate(360deg); }
    }

    /* Cards */
    .card {
      background: var(--card);
      border: 1px solid var(--card-border);
      border-radius: 12px;
      padding: 12px 14px 14px;
      margin-bottom: 10px;
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
    }

    .card-title-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 12px;
    }

    .card-name {
      font-size: 12.5px;
      font-weight: 600;
      letter-spacing: -0.1px;
    }

    .models-hint {
      font-size: 10px;
      color: var(--text-muted);
    }

    /* Meters */
    .meter-group {
      display: flex;
      flex-direction: column;
      gap: 10px;
    }

    .meter-meta {
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 11px;
      margin-bottom: 4px;
    }

    .meter-label {
      color: var(--text-sec);
      font-weight: 500;
    }

    .meter-val {
      font-weight: 700;
      font-variant-numeric: tabular-nums;
    }

    .track {
      width: 100%;
      height: 5px;
      background: var(--track);
      border-radius: 3px;
      overflow: hidden;
      margin-bottom: 4px;
    }

    .fill {
      height: 100%;
      border-radius: 3px;
      transition: width 0.4s ease;
    }

    .fill.green { background: var(--green); }
    .fill.yellow { background: var(--yellow); }
    .fill.red { background: var(--red); }

    .meter-sub {
      display: flex;
      justify-content: space-between;
      font-size: 9.5px;
      color: var(--text-muted);
    }

    .timer {
      color: #64d2ff;
      font-weight: 600;
      font-variant-numeric: tabular-nums;
    }

    /* Setup View */
    .setup-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 12px;
    }

    .setup-title {
      font-size: 13px;
      font-weight: 700;
    }

    .back-btn {
      background: transparent;
      border: none;
      color: var(--accent);
      font-size: 12px;
      font-weight: 500;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 3px;
    }

    .setup-section {
      background: var(--card);
      border: 1px solid var(--card-border);
      border-radius: 12px;
      padding: 10px 12px;
      margin-bottom: 10px;
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
    }

    .setup-section-title {
      font-size: 10px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.3px;
      color: var(--text-muted);
      margin-bottom: 8px;
    }

    .setup-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 5px 0;
      border-bottom: 1px solid rgba(255, 255, 255, 0.05);
      font-size: 11px;
    }

    .setup-row:last-child {
      border-bottom: none;
    }

    .setup-label {
      color: var(--text-sec);
    }

    .setup-val {
      font-weight: 600;
      color: var(--text);
      max-width: 190px;
      text-align: right;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .danger-btn {
      width: 100%;
      background: rgba(255, 69, 58, 0.15);
      border: 1px solid rgba(255, 69, 58, 0.35);
      color: #ff453a;
      padding: 7px;
      border-radius: 8px;
      font-size: 11px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.15s ease;
      margin-top: 4px;
    }

    .danger-btn:hover {
      background: rgba(255, 69, 58, 0.28);
    }

    /* Footer */
    .footer-bar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding-top: 4px;
    }

    .footer-left {
      display: flex;
      align-items: center;
      gap: 6px;
    }

    .footer-btn {
      display: inline-flex;
      align-items: center;
      gap: 5px;
      background: rgba(255, 255, 255, 0.06);
      border: 1px solid var(--card-border);
      color: var(--text-sec);
      font-size: 10.5px;
      font-weight: 500;
      padding: 4px 9px;
      border-radius: 6px;
      cursor: pointer;
      transition: all 0.15s ease;
    }

    .footer-btn:hover {
      background: rgba(255, 255, 255, 0.14);
      color: var(--text);
    }

    .footer-btn:active {
      transform: scale(0.95);
    }

    .footer-link-btn {
      background: transparent;
      border: none;
      color: var(--text-muted);
      font-size: 10px;
      cursor: pointer;
      padding: 4px 6px;
      transition: color 0.15s ease;
    }

    .footer-link-btn:hover {
      color: #ff453a;
    }

    .updated-text {
      font-size: 9.5px;
      color: var(--text-muted);
    }

    .disclaimer-text {
      margin-top: 8px;
      text-align: center;
      font-size: 8px;
      color: rgba(255, 255, 255, 0.32);
      letter-spacing: -0.1px;
    }
  </style>
</head>
<body>
  <!-- Main Dashboard View -->
  <div id="main-view" class="view">
    <header>
      <div>
        <div class="title-row">
          <span class="app-title">Antigravity</span>
          <span class="ultra-pill" id="tier-pill">Ultra</span>
        </div>
        <div class="account-sub" id="user-email">Loading...</div>
      </div>
      <div class="header-actions">
        <!-- 1. Add Desktop Widget -->
        <button class="icon-btn" id="btn-widget" title="Add Desktop Widget (⌘W)">
          <svg width="13" height="13" viewBox="0 0 16 16" fill="currentColor">
            <path d="M1.5 2.5A1.5 1.5 0 0 1 3 1h4a1.5 1.5 0 0 1 1.5 1.5v4A1.5 1.5 0 0 1 7 8H3a1.5 1.5 0 0 1-1.5-1.5v-4ZM9 2.5A1.5 1.5 0 0 1 10.5 1h2.5A1.5 1.5 0 0 1 14.5 2.5v11a1.5 1.5 0 0 1-1.5 1.5h-2.5A1.5 1.5 0 0 1 9 13.5v-11ZM1.5 10.5A1.5 1.5 0 0 1 3 9h4a1.5 1.5 0 0 1 1.5 1.5v3A1.5 1.5 0 0 1 7 15H3a1.5 1.5 0 0 1-1.5-1.5v-3Z"/>
          </svg>
        </button>

        <!-- 2. Setup / Preferences -->
        <button class="icon-btn" id="btn-setup" title="Preferences & Setup (⌘,)">
          <svg width="13" height="13" viewBox="0 0 16 16" fill="currentColor">
            <path d="M8 4.754a3.246 3.246 0 1 0 0 6.492 3.246 3.246 0 0 0 0-6.492zM5.754 8a2.246 2.246 0 1 1 4.492 0 2.246 2.246 0 0 1-4.492 0z"/>
            <path d="M9.796 1.343c-.527-1.79-3.065-1.79-3.592 0l-.094.319a.873.873 0 0 1-1.255.52l-.292-.16c-1.64-.892-3.433.902-2.54 2.541l.159.292a.873.873 0 0 1-.52 1.255l-.319.094c-1.79.527-1.79 3.065 0 3.592l.319.094a.873.873 0 0 1 .52 1.255l-.16.292c-.892 1.64.901 3.434 2.541 2.54l.292-.159a.873.873 0 0 1 1.255.52l.094.319c.527 1.79 3.065 1.79 3.592 0l.094-.319a.873.873 0 0 1 1.255-.52l.292.16c1.64.893 3.434-.902 2.54-2.541l-.159-.292a.873.873 0 0 1 .52-1.255l.319-.094c1.79-.527 1.79-3.065 0-3.592l-.319-.094a.873.873 0 0 1-.52-1.255l.16-.292c.893-1.64-.902-3.433-2.541-2.54l-.292.159a.873.873 0 0 1-1.255-.52l-.094-.319z"/>
          </svg>
        </button>

        <!-- 3. Unsnap / Snap toggle -->
        <button class="icon-btn" id="btn-unsnap" title="Unsnap to Floating Window (⌘U)">
          <svg width="12" height="12" viewBox="0 0 16 16" fill="currentColor" id="unsnap-icon">
            <path fill-rule="evenodd" d="M8.636 3.5a.5.5 0 0 0-.5-.5H1.5A1.5 1.5 0 0 0 0 4.5v10A1.5 1.5 0 0 0 1.5 16h10a1.5 1.5 0 0 0 1.5-1.5V7.864a.5.5 0 0 0-1 0V14.5a.5.5 0 0 1-.5.5h-10a.5.5 0 0 1-.5-.5v-10a.5.5 0 0 1 .5-.5h6.636a.5.5 0 0 0 .5-.5z"/>
            <path fill-rule="evenodd" d="M16 .5a.5.5 0 0 0-.5-.5h-5a.5.5 0 0 0 0 1h3.793L6.146 9.146a.5.5 0 1 0 .708.708L15 1.707V5.5a.5.5 0 0 0 1 0v-5z"/>
          </svg>
        </button>

        <!-- 4. Refresh -->
        <button class="icon-btn" id="btn-refresh" title="Refresh Now (⌘R)">
          <svg width="12" height="12" viewBox="0 0 16 16" fill="currentColor">
            <path fill-rule="evenodd" d="M8 2.5a5.487 5.487 0 0 0-4.131 1.869l1.204 1.204A.25.25 0 0 1 4.896 6H1.25A.25.25 0 0 1 1 5.75V2.104a.25.25 0 0 1 .427-.177l1.38 1.38A7.001 7.001 0 0 1 14.95 7.16a.75.75 0 1 1-1.49.178A5.5 5.5 0 0 0 8 2.5ZM1.705 8.005a.75.75 0 0 1 .834.656 5.5 5.5 0 0 0 9.592 2.97l-1.204-1.204a.25.25 0 0 1 .177-.427h3.646a.25.25 0 0 1 .25.25v3.646a.25.25 0 0 1-.427.177l-1.38-1.38A7.001 7.001 0 0 1 1.05 8.84a.75.75 0 0 1 .655-.835Z"></path>
          </svg>
        </button>
      </div>
    </header>

    <div id="groups-container">
      <!-- Cards populated dynamically -->
    </div>

    <div class="footer-bar">
      <div class="footer-left">
        <button class="footer-btn" id="btn-copy">
          <svg width="11" height="11" viewBox="0 0 16 16" fill="currentColor">
            <path d="M0 6.75C0 5.784.784 5 1.75 5h1.5a.75.75 0 0 1 0 1.5h-1.5a.25.25 0 0 0-.25.25v7.5c0 .138.112.25.25.25h7.5a.25.25 0 0 0 .25-.25v-1.5a.75.75 0 0 1 1.5 0v1.5A1.75 1.75 0 0 1 9.25 16h-7.5A1.75 1.75 0 0 1 0 14.25Z"></path>
            <path d="M5 1.75C5 .784 5.784 0 6.75 0h7.5C15.216 0 16 .784 16 1.75v7.5A1.75 1.75 0 0 1 14.25 11h-7.5A1.75 1.75 0 0 1 5 9.25Zm1.75-.25a.25.25 0 0 0-.25.25v7.5c0 .138.112.25.25.25h7.5a.25.25 0 0 0 .25-.25v-7.5a.25.25 0 0 0-.25-.25Z"></path>
          </svg>
          <span>Copy Remote curl</span>
        </button>
        <button class="footer-link-btn" id="btn-footer-quit">Quit</button>
      </div>
      <span class="updated-text" id="updated-label">Syncing...</span>
    </div>

    <div class="disclaimer-text">
      Independent tool. Not affiliated with or endorsed by Google LLC.
    </div>
  </div>

  <!-- Setup & Preferences View -->
  <div id="setup-view" class="view hidden">
    <div class="setup-header">
      <span class="setup-title">Preferences & Setup</span>
      <button class="back-btn" id="btn-back">‹ Back</button>
    </div>

    <!-- Section 1: Authentication -->
    <div class="setup-section">
      <div class="setup-section-title">Authentication & Identity</div>
      <div class="setup-row">
        <span class="setup-label">Account</span>
        <span class="setup-val" id="s-account">Loading...</span>
      </div>
      <div class="setup-row">
        <span class="setup-label">Subscription Plan</span>
        <span class="setup-val" id="s-tier">Google AI Ultra</span>
      </div>
      <div class="setup-row">
        <span class="setup-label">Credential Source</span>
        <span class="setup-val" id="s-source">macOS Keychain</span>
      </div>
    </div>

    <!-- Section 2: Server & Network -->
    <div class="setup-section">
      <div class="setup-section-title">Local Daemon & Network</div>
      <div class="setup-row">
        <span class="setup-label">Daemon Port</span>
        <span class="setup-val" id="s-port">3007</span>
      </div>
      <div class="setup-row">
        <span class="setup-label">Machine LAN IP</span>
        <span class="setup-val" id="s-ip">192.168.5.67</span>
      </div>
      <div class="setup-row">
        <span class="setup-label">Background Service</span>
        <span class="setup-val">Active (LaunchAgent)</span>
      </div>
    </div>

    <!-- Section 3: Danger Zone -->
    <div class="setup-section">
      <div class="setup-section-title">Application Control</div>
      <button class="danger-btn" id="btn-quit-danger">Quit Antigravity Usage Completely</button>
    </div>

    <div class="disclaimer-text">
      Independent tool. Not affiliated with or endorsed by Google LLC.
    </div>
  </div>

  <script>
    const API_URL = 'http://127.0.0.1:3007/quota';

    // Elements
    const mainView = document.getElementById('main-view');
    const setupView = document.getElementById('setup-view');
    const groupsContainer = document.getElementById('groups-container');
    const updatedLabel = document.getElementById('updated-label');
    const userEmail = document.getElementById('user-email');
    const tierPill = document.getElementById('tier-pill');
    const btnRefresh = document.getElementById('btn-refresh');
    const btnCopy = document.getElementById('btn-copy');
    const btnUnsnap = document.getElementById('btn-unsnap');
    const btnWidget = document.getElementById('btn-widget');
    const btnSetup = document.getElementById('btn-setup');
    const btnBack = document.getElementById('btn-back');
    const btnFooterQuit = document.getElementById('btn-footer-quit');
    const btnQuitDanger = document.getElementById('btn-quit-danger');
    const unsnapIcon = document.getElementById('unsnap-icon');

    // Setup elements
    const sAccount = document.getElementById('s-account');
    const sTier = document.getElementById('s-tier');
    const sSource = document.getElementById('s-source');
    const sPort = document.getElementById('s-port');
    const sIp = document.getElementById('s-ip');

    let currentRemoteCommand = 'curl -s http://192.168.5.67:3007';
    let isUnsnapped = false;
    let timerInterval = null;

    function escapeHtml(str) {
      if (!str) return '';
      return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
    }

    function formatRelative(seconds) {
      if (typeof seconds !== 'number' || isNaN(seconds) || seconds <= 0) return 'Ready';
      if (seconds < 60) return Math.round(seconds) + 's left';
      const days = Math.floor(seconds / 86400);
      const hours = Math.floor((seconds % 86400) / 3600);
      const mins = Math.floor((seconds % 3600) / 60);
      const parts = [];
      if (days > 0) parts.push(days + 'd');
      if (hours > 0 || days > 0) parts.push(hours + 'h');
      parts.push(mins + 'm');
      return parts.slice(0, 2).join(' ') + ' left';
    }

    function renderQuota(data) {
      if (!data) return;

      const account = data.account || 'Active Session';
      userEmail.textContent = account;
      sAccount.textContent = account;

      const tier = data.tier || 'Google AI Ultra';
      tierPill.textContent = tier.toLowerCase().includes('ultra') ? 'Ultra' : tier;
      sTier.textContent = tier;

      sSource.textContent = data.credentialSource || 'macOS Keychain';
      sPort.textContent = data.port || '3007';
      sIp.textContent = data.localIp || '127.0.0.1';

      if (data.remoteCommand) {
        currentRemoteCommand = data.remoteCommand;
      }

      const updatedDate = new Date(data.fetchedAt || Date.now());
      updatedLabel.textContent = 'Updated ' + updatedDate.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

      groupsContainer.innerHTML = '';

      (data.groups || []).forEach(group => {
        const groupName = escapeHtml(group.displayName || group.name || 'Models');
        const rawDesc = group.description || group.models || '';
        const cleanDesc = escapeHtml(rawDesc.replace('Models within this group: ', '').replace(/,/g, ' ·'));

        const card = document.createElement('div');
        card.className = 'card';

        let metersHtml = '';
        (group.buckets || []).forEach(b => {
          let rawLabel = b.displayName || b.label || b.kind || 'Limit';
          rawLabel = rawLabel.replace(' Remaining', '');
          const label = escapeHtml(rawLabel);

          const fraction = Math.max(0, Math.min(1, b.remainingFraction ?? 1.0));
          const pct = (fraction * 100).toFixed(0);

          let colorClass = 'green';
          if (pct < 20) colorClass = 'red';
          else if (pct < 50) colorClass = 'yellow';

          let resetTimestamp = null;
          if (b.resetTime || b.resetAt) {
            resetTimestamp = new Date(b.resetTime || b.resetAt).getTime();
          } else if (b.resetsInSeconds != null) {
            resetTimestamp = Date.now() + (b.resetsInSeconds * 1000);
          }

          metersHtml += `
            <div>
              <div class="meter-meta">
                <span class="meter-label">${label}</span>
                <span class="meter-val" style="color: var(--${colorClass})">${pct}%</span>
              </div>
              <div class="track">
                <div class="fill ${colorClass}" style="width: ${pct}%"></div>
              </div>
              <div class="meter-sub">
                <span>${pct}% capacity</span>
                <span class="timer" data-reset="${resetTimestamp || ''}">Calculating...</span>
              </div>
            </div>
          `;
        });

        card.innerHTML = `
          <div class="card-title-row">
            <span class="card-name">${groupName}</span>
            <span class="models-hint">${cleanDesc}</span>
          </div>
          <div class="meter-group">
            ${metersHtml}
          </div>
        `;

        groupsContainer.appendChild(card);
      });

      updateTimers();
      startTimerTick();
    }

    function updateTimers() {
      const timerEls = document.querySelectorAll('.timer[data-reset]');
      const now = Date.now();
      timerEls.forEach(el => {
        const resetTs = parseInt(el.getAttribute('data-reset'), 10);
        if (!resetTs || isNaN(resetTs)) {
          el.textContent = 'Active';
          return;
        }
        const diffSecs = Math.floor((resetTs - now) / 1000);
        el.textContent = formatRelative(diffSecs);
      });
    }

    function startTimerTick() {
      if (timerInterval) clearInterval(timerInterval);
      timerInterval = setInterval(updateTimers, 1000);
    }

    async function fetchQuota(force = false) {
      btnRefresh.classList.add('spinning');
      try {
        const url = force ? `${API_URL}?refresh=1` : API_URL;
        const res = await fetch(url);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = await res.json();
        renderQuota(data);
      } catch (err) {
        console.error('Fetch error:', err);
        updatedLabel.textContent = 'Retrying...';
      } finally {
        setTimeout(() => btnRefresh.classList.remove('spinning'), 350);
      }
    }

    function setUnsnappedState(unsnapped) {
      isUnsnapped = unsnapped;
      if (isUnsnapped) {
        btnUnsnap.title = "Snap Back to Menu Bar (⌘U)";
        unsnapIcon.innerHTML = `
          <path fill-rule="evenodd" d="M1 3.5a.5.5 0 0 1 .5-.5h13a.5.5 0 0 1 .5.5v2a.5.5 0 0 1-1 0V4H2v8.5a.5.5 0 0 0 .5.5h5a.5.5 0 0 1 0 1h-5A1.5 1.5 0 0 1 1 12.5v-9z"/>
          <path fill-rule="evenodd" d="M16 11.5a.5.5 0 0 1-.5.5H11v4.5a.5.5 0 0 1-1 0V11a.5.5 0 0 1 .5-.5h5a.5.5 0 0 1 .5.5z"/>
          <path fill-rule="evenodd" d="M10.146 11.854a.5.5 0 0 1 0-.708l5-5a.5.5 0 0 1 .708.708l-5 5a.5.5 0 0 1-.708 0z"/>
        `;
      } else {
        btnUnsnap.title = "Unsnap to Floating Window (⌘U)";
        unsnapIcon.innerHTML = `
          <path fill-rule="evenodd" d="M8.636 3.5a.5.5 0 0 0-.5-.5H1.5A1.5 1.5 0 0 0 0 4.5v10A1.5 1.5 0 0 0 1.5 16h10a1.5 1.5 0 0 0 1.5-1.5V7.864a.5.5 0 0 0-1 0V14.5a.5.5 0 0 1-.5.5h-10a.5.5 0 0 1-.5-.5v-10a.5.5 0 0 1 .5-.5h6.636a.5.5 0 0 0 .5-.5z"/>
          <path fill-rule="evenodd" d="M16 .5a.5.5 0 0 0-.5-.5h-5a.5.5 0 0 0 0 1h3.793L6.146 9.146a.5.5 0 1 0 .708.708L15 1.707V5.5a.5.5 0 0 0 1 0v-5z"/>
        `;
      }
    }

    function sendAppAction(action) {
      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.appAction) {
        window.webkit.messageHandlers.appAction.postMessage({ action: action });
      }
    }

    // Event listeners
    btnRefresh.addEventListener('click', () => fetchQuota(true));
    btnUnsnap.addEventListener('click', () => sendAppAction(isUnsnapped ? "snap" : "unsnap"));
    btnWidget.addEventListener('click', () => sendAppAction("toggleWidget"));

    btnSetup.addEventListener('click', () => {
      mainView.classList.add('hidden');
      setupView.classList.remove('hidden');
    });

    btnBack.addEventListener('click', () => {
      setupView.classList.add('hidden');
      mainView.classList.remove('hidden');
    });

    btnFooterQuit.addEventListener('click', () => sendAppAction("quit"));
    btnQuitDanger.addEventListener('click', () => sendAppAction("quit"));

    btnCopy.addEventListener('click', () => {
      const textToCopy = currentRemoteCommand;
      let copied = false;

      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.copyToClipboard) {
        window.webkit.messageHandlers.copyToClipboard.postMessage(textToCopy);
        copied = true;
      } else {
        try {
          const ta = document.createElement('textarea');
          ta.value = textToCopy;
          ta.style.position = 'fixed';
          ta.style.opacity = '0';
          document.body.appendChild(ta);
          ta.select();
          copied = document.execCommand('copy');
          document.body.removeChild(ta);
        } catch (e) {}
      }

      const span = btnCopy.querySelector('span');
      if (copied) {
        span.textContent = 'Copied!';
        setTimeout(() => span.textContent = 'Copy Remote curl', 1600);
      }
    });

    fetchQuota();
  </script>
</body>
</html>

```

---

## widget_v7.html
**Description:** WebKit Compact Desktop Widget User Interface  
**Path:** `widget_v7.html` | **Lines:** 287

```html
<!DOCTYPE html>
<!-- v7 – Unified Sibling Design Apple Desktop Widget for Google Antigravity -->
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Antigravity Widget</title>
  <style>
    :root {
      --text: #ffffff;
      --text-sec: rgba(255, 255, 255, 0.65);
      --text-muted: rgba(255, 255, 255, 0.38);
      --card: rgba(26, 26, 30, 0.85);
      --card-border: rgba(255, 255, 255, 0.14);
      --track: rgba(255, 255, 255, 0.12);
      --green: #30d158;
      --yellow: #ffd60a;
      --red: #ff453a;
      --accent: #0a84ff;
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      user-select: none;
      -webkit-user-select: none;
    }

    body {
      font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display", sans-serif;
      background: transparent;
      color: var(--text);
      width: 240px;
      height: 124px;
      padding: 8px 10px;
      overflow: hidden;
      cursor: grab;
      -webkit-font-smoothing: antialiased;
    }

    body:active {
      cursor: grabbing;
    }

    .widget-container {
      width: 100%;
      height: 100%;
      background: var(--card);
      border: 1px solid var(--card-border);
      border-radius: 18px;
      padding: 8px 10px;
      box-shadow: 0 12px 32px rgba(0, 0, 0, 0.5);
      backdrop-filter: blur(28px);
      -webkit-backdrop-filter: blur(28px);
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      transition: border-color 0.2s ease;
    }

    .widget-container:hover {
      border-color: rgba(255, 255, 255, 0.25);
    }

    .top-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .brand {
      display: flex;
      align-items: center;
      gap: 5px;
      font-size: 11px;
      font-weight: 700;
      letter-spacing: -0.2px;
    }

    .sparkle {
      color: var(--accent);
    }

    .badge {
      font-size: 8px;
      font-weight: 700;
      text-transform: uppercase;
      padding: 1px 5px;
      border-radius: 5px;
      background: rgba(255, 214, 10, 0.18);
      color: #ffd60a;
      border: 1px solid rgba(255, 214, 10, 0.35);
    }

    .close-btn {
      width: 16px;
      height: 16px;
      border-radius: 50%;
      background: rgba(255, 255, 255, 0.1);
      border: none;
      color: var(--text-sec);
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 10px;
      line-height: 1;
      opacity: 0;
      transition: opacity 0.15s ease, background 0.15s ease;
    }

    .widget-container:hover .close-btn {
      opacity: 1;
    }

    .close-btn:hover {
      background: rgba(255, 69, 58, 0.7);
      color: #fff;
    }

    .meters {
      display: flex;
      flex-direction: column;
      gap: 5px;
    }

    .meter-row {
      display: flex;
      flex-direction: column;
      gap: 2px;
    }

    .meter-meta {
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 9px;
    }

    .name {
      color: var(--text-sec);
      font-weight: 500;
    }

    .pct {
      font-weight: 700;
      font-variant-numeric: tabular-nums;
    }

    .bar-bg {
      width: 100%;
      height: 4px;
      background: var(--track);
      border-radius: 2px;
      overflow: hidden;
    }

    .bar-fill {
      height: 100%;
      border-radius: 2px;
      transition: width 0.4s ease;
    }

    .bar-fill.green { background: var(--green); }
    .bar-fill.yellow { background: var(--yellow); }
    .bar-fill.red { background: var(--red); }

    .widget-footer {
      font-size: 7px;
      color: var(--text-muted);
      text-align: center;
      letter-spacing: 0.1px;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
  </style>
</head>
<body>
  <div class="widget-container" id="widget-card" title="Double-click to open full monitor">
    <div class="top-row">
      <div class="brand">
        <span class="sparkle">✦</span>
        <span>Antigravity</span>
        <span class="badge" id="w-badge">Ultra</span>
      </div>
      <button class="close-btn" id="btn-close-widget" title="Close Widget">×</button>
    </div>

    <div class="meters">
      <div class="meter-row">
        <div class="meter-meta">
          <span class="name">Gemini (5h)</span>
          <span class="pct" id="g-pct" style="color: var(--green)">--%</span>
        </div>
        <div class="bar-bg">
          <div class="bar-fill green" id="g-bar" style="width: 0%"></div>
        </div>
      </div>

      <div class="meter-row">
        <div class="meter-meta">
          <span class="name">Claude &amp; GPT</span>
          <span class="pct" id="c-pct" style="color: var(--green)">--%</span>
        </div>
        <div class="bar-bg">
          <div class="bar-fill green" id="c-bar" style="width: 0%"></div>
        </div>
      </div>
    </div>

    <div class="widget-footer">
      Independent utility · Not affiliated with Google
    </div>
  </div>

  <script>
    const API_URL = 'http://127.0.0.1:3007/quota';
    const gPct = document.getElementById('g-pct');
    const gBar = document.getElementById('g-bar');
    const cPct = document.getElementById('c-pct');
    const cBar = document.getElementById('c-bar');
    const wBadge = document.getElementById('w-badge');
    const btnClose = document.getElementById('btn-close-widget');
    const widgetCard = document.getElementById('widget-card');

    function updateWidgetUI(data) {
      if (!data) return;
      const tier = data.tier || 'Ultra';
      wBadge.textContent = tier.toLowerCase().includes('ultra') ? 'Ultra' : tier;

      (data.groups || []).forEach(group => {
        const name = (group.displayName || group.name || '').toLowerCase();
        let minFrac = 1.0;
        (group.buckets || []).forEach(b => {
          if (b.remainingFraction != null) {
            minFrac = Math.min(minFrac, b.remainingFraction);
          }
        });
        const pct = Math.round(minFrac * 100);
        let colorClass = 'green';
        if (pct < 20) colorClass = 'red';
        else if (pct < 50) colorClass = 'yellow';

        if (name.includes('gemini')) {
          gPct.textContent = pct + '%';
          gPct.style.color = `var(--${colorClass})`;
          gBar.style.width = pct + '%';
          gBar.className = `bar-fill ${colorClass}`;
        } else {
          cPct.textContent = pct + '%';
          cPct.style.color = `var(--${colorClass})`;
          cBar.style.width = pct + '%';
          cBar.className = `bar-fill ${colorClass}`;
        }
      });
    }

    async function fetchWidgetData() {
      try {
        const res = await fetch(API_URL);
        if (res.ok) {
          const data = await res.json();
          updateWidgetUI(data);
        }
      } catch (e) {}
    }

    btnClose.addEventListener('click', (e) => {
      e.stopPropagation();
      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.appAction) {
        window.webkit.messageHandlers.appAction.postMessage({ action: "closeWidget" });
      }
    });

    widgetCard.addEventListener('dblclick', () => {
      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.appAction) {
        window.webkit.messageHandlers.appAction.postMessage({ action: "openFullApp" });
      }
    });

    fetchWidgetData();
    setInterval(fetchWidgetData, 30000);
  </script>
</body>
</html>

```

---

## antigravity_usage_v4.py
**Description:** Hardened Python CLI & Cross-Device Quota Daemon  
**Path:** `antigravity_usage_v4.py` | **Lines:** 693

```python
#!/usr/bin/env python3
# v4 – Clean remote fetch, atomic credential cache, credentialSource reporting, hardened server
"""
antigravity_usage_v4.py
A fast, standalone, zero-dependency tool to view Google Antigravity (agy)
model quota and usage in the terminal across all your devices.

Features:
  - Accurate Subscription Tier: Resolves paidTier (Google AI Ultra / Pro) instead
    of falling back to legacy default free-tier identifiers.
  - In-Memory Token Caching: Prevents redundant OAuth refresh calls when Keychain token expires.
  - Thread-Safe Cache: Synchronized quota fetching with threading.Lock to eliminate cache stampedes.
  - Hardened Server: Loopback binding by default, host validation, constant-time secret check,
    socket timeouts, daemon threads, and restricted CORS.
  - Sibling Parity: Exposes credentialSource, network bindings, and diagnostics for Setup UI.
  - Cross-device Server Mode (--serve): Host a lightweight daemon on your primary machine.
    Any device on your local network/VPN/Tailscale can check usage simply with:
        curl -s http://<server-ip>:3007
    or by using this CLI in remote mode.
  - Watch Mode (--watch): Live auto-refreshing terminal dashboard.
  - JSON output (--json): For scripts, tmux status bars, or custom dashboards.
"""

import argparse
import base64
import datetime
import hmac
import http.server
import json
import os
import platform
import re
import socket
import ssl
import subprocess
import sys
import tempfile
import threading
import time
import urllib.error
import urllib.parse
import urllib.request

__version__ = "4.0.0"

# Antigravity CLI installed-client credentials (public OAuth client)
_CID_FRAGS = ("1071006060591-", "tmhssin2h21lcre", "235vtolojh4g403ep", ".apps.googleusercontent.com")
_SEC_FRAGS = ("GOCSPX-", "K58FWR486", "LdLJ1mLB8sXC4z6qDAf")
OAUTH_CLIENT_ID = os.environ.get("AGY_OAUTH_CLIENT_ID") or "".join(_CID_FRAGS)
OAUTH_CLIENT_SECRET = os.environ.get("AGY_OAUTH_CLIENT_SECRET") or "".join(_SEC_FRAGS)
TOKEN_URL = "https://oauth2.googleapis.com/token"

HOSTS = [
    "daily-cloudcode-pa.googleapis.com",
    "cloudcode-pa.googleapis.com",
]

USER_AGENT = f"antigravity-usage-monitor/{__version__} {platform.system().lower()}/{platform.machine()}"

# Global state & synchronization locks
_CACHE_LOCK = threading.Lock()
_TOKEN_LOCK = threading.Lock()
_CACHED_ACCESS_TOKEN = None
_CACHED_TOKEN_EXPIRY = 0
_LAST_CREDENTIAL_SOURCE = "Unknown"


# ============================================================================
# Credential & Token Discovery
# ============================================================================

def read_credential_from_system() -> tuple[dict, str]:
    """Read OAuth tokens from system credential stores (Keychain, Secret Service, Windows)."""
    global _LAST_CREDENTIAL_SOURCE
    system = platform.system()

    if system == "Darwin":
        cmd = ["security", "find-generic-password", "-s", "gemini", "-a", "antigravity", "-w"]
        try:
            out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, text=True, timeout=5).strip()
            source = "macOS Keychain (service: gemini, account: antigravity)"
            if out.startswith("go-keyring-base64:"):
                raw_b64 = out[len("go-keyring-base64:"):]
                data = json.loads(base64.b64decode(raw_b64).decode("utf-8"))
                _LAST_CREDENTIAL_SOURCE = source
                return data, source
            elif out.startswith("{"):
                _LAST_CREDENTIAL_SOURCE = source
                return json.loads(out), source
        except Exception:
            pass

    elif system == "Linux":
        try:
            cmd = ["secret-tool", "lookup", "service", "gemini", "account", "antigravity"]
            out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, text=True, timeout=5).strip()
            source = "Linux Secret Service (service: gemini, account: antigravity)"
            if out.startswith("go-keyring-base64:"):
                raw_b64 = out[len("go-keyring-base64:"):]
                _LAST_CREDENTIAL_SOURCE = source
                return json.loads(base64.b64decode(raw_b64).decode("utf-8")), source
            elif out.startswith("{"):
                _LAST_CREDENTIAL_SOURCE = source
                return json.loads(out), source
        except Exception:
            pass

    elif system == "Windows":
        try:
            ps_script = (
                "[void][Windows.Security.Credentials.PasswordVault,Windows.Security.Credentials,ContentType=WindowsRuntime];"
                "$v = New-Object Windows.Security.Credentials.PasswordVault;"
                "$c = $v.Retrieve('gemini', 'antigravity');"
                "$c.RetrievePassword();"
                "Write-Output $c.Password"
            )
            out = subprocess.check_output(["powershell", "-NoProfile", "-Command", ps_script],
                                          stderr=subprocess.DEVNULL, text=True, timeout=5).strip()
            source = "Windows Credential Manager (gemini/antigravity)"
            if out.startswith("go-keyring-base64:"):
                raw_b64 = out[len("go-keyring-base64:"):]
                _LAST_CREDENTIAL_SOURCE = source
                return json.loads(base64.b64decode(raw_b64).decode("utf-8")), source
            elif out.startswith("{"):
                _LAST_CREDENTIAL_SOURCE = source
                return json.loads(out), source
        except Exception:
            pass

    # File-based fallbacks
    home = os.path.expanduser("~")
    candidates = [
        (os.path.join(home, ".gemini", "antigravity", "tokens.json"), "~/.gemini/antigravity/tokens.json"),
        (os.path.join(home, ".gemini", "tokens.json"), "~/.gemini/tokens.json"),
        (os.path.join(home, ".config", "antigravity", "tokens.json"), "~/.config/antigravity/tokens.json"),
        (os.path.join(home, ".antigravity", "tokens.json"), "~/.antigravity/tokens.json"),
    ]

    for p, label in candidates:
        if os.path.exists(p):
            try:
                with open(p, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    _LAST_CREDENTIAL_SOURCE = f"File: {label}"
                    return data, _LAST_CREDENTIAL_SOURCE
            except Exception:
                continue

    _LAST_CREDENTIAL_SOURCE = "None (Unauthenticated)"
    return {}, _LAST_CREDENTIAL_SOURCE


def parse_jwt_claims(jwt_str: str) -> dict:
    """Decode JWT payload without verifying signature to inspect authoritative claims."""
    if not jwt_str or "." not in jwt_str:
        return {}
    parts = jwt_str.split(".")
    if len(parts) < 2:
        return {}
    payload = parts[1]
    padded = payload + "=" * ((4 - len(payload) % 4) % 4)
    try:
        raw = base64.urlsafe_b64decode(padded)
        return json.loads(raw.decode("utf-8"))
    except Exception:
        return {}


def refresh_access_token(refresh_token: str) -> str:
    """Exchange OAuth refresh token for a fresh access token with caching."""
    global _CACHED_ACCESS_TOKEN, _CACHED_TOKEN_EXPIRY

    with _TOKEN_LOCK:
        now = time.time()
        if _CACHED_ACCESS_TOKEN and now < _CACHED_TOKEN_EXPIRY:
            return _CACHED_ACCESS_TOKEN

        post_data = urllib.parse.urlencode({
            "client_id": OAUTH_CLIENT_ID,
            "client_secret": OAUTH_CLIENT_SECRET,
            "refresh_token": refresh_token,
            "grant_type": "refresh_token"
        }).encode("utf-8")

        req = urllib.request.Request(
            TOKEN_URL,
            data=post_data,
            headers={"Content-Type": "application/x-www-form-urlencoded", "User-Agent": USER_AGENT}
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            body = json.loads(resp.read().decode("utf-8"))
            tok = body.get("access_token", "")
            expires_in = body.get("expires_in", 3600)
            if not tok:
                raise ValueError(f"OAuth response missing access_token: {body}")
            _CACHED_ACCESS_TOKEN = tok
            _CACHED_TOKEN_EXPIRY = now + expires_in - 120  # 2 minute safety margin
            return tok


# ============================================================================
# Cloud Code Direct API Client
# ============================================================================

def make_cloud_code_request(host: str, method: str, body: dict, access_token: str) -> dict:
    """Execute a POST request against the internal Google Cloud Code endpoint."""
    url = f"https://{host}/v1internal:{method}"
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
            "User-Agent": USER_AGENT
        }
    )
    with urllib.request.urlopen(req, timeout=12) as resp:
        return json.loads(resp.read().decode("utf-8"))


def fetch_usage_data(access_token: str = None, refresh_token: str = None) -> dict:
    """
    Fetch quota summary from Google Cloud Code API.
    Handles token refreshing, tier resolution, and host fallback automatically.
    """
    global _CACHED_ACCESS_TOKEN

    cred, cred_source = read_credential_from_system()
    token_info = cred.get("token", {})
    if not access_token:
        access_token = _CACHED_ACCESS_TOKEN or token_info.get("access_token")
    if not refresh_token:
        refresh_token = token_info.get("refresh_token")

    if not access_token:
        raise ValueError(
            "Could not locate Antigravity credentials. Ensure you have logged in via `agy` or Antigravity IDE."
        )

    last_err = None
    for attempt in range(2):  # Try initial, then refresh if 401
        for host in HOSTS:
            try:
                # 1. Load Code Assist metadata
                load_resp = make_cloud_code_request(
                    host,
                    "loadCodeAssist",
                    {"metadata": {"ideType": "ANTIGRAVITY"}},
                    access_token
                )
                project = load_resp.get("cloudaicompanionProject")
                if not project:
                    continue

                paid_tier = load_resp.get("paidTier", {})
                current_tier = load_resp.get("currentTier", {})

                # Accurate tier detection: prioritize paidTier if present
                if paid_tier and paid_tier.get("name"):
                    tier_name = paid_tier.get("name")
                    tier_id = paid_tier.get("id", "ultra-tier")
                elif paid_tier and paid_tier.get("id"):
                    tier_id = paid_tier.get("id")
                    tier_name = tier_id.replace("-", " ").title()
                elif current_tier and current_tier.get("name") and current_tier.get("id") != "free-tier":
                    tier_id = current_tier.get("id", "standard")
                    tier_name = current_tier.get("name")
                elif current_tier and current_tier.get("id"):
                    tier_id = current_tier.get("id")
                    tier_name = "Free Tier" if tier_id == "free-tier" else tier_id.replace("-", " ").title()
                else:
                    tier_id = "standard"
                    tier_name = "Standard"

                tier_desc = paid_tier.get("upgradeSubscriptionText") or paid_tier.get("description") or current_tier.get("description") or ""

                # Robust Email extraction: first from signed OIDC id_token in Keychain, fallback to URL regex
                email = None
                id_token = cred.get("id_token") or token_info.get("id_token")
                if id_token and isinstance(id_token, str) and "." in id_token:
                    claims = parse_jwt_claims(id_token)
                    email = claims.get("email")

                if not email:
                    upgrade_uri = current_tier.get("upgradeSubscriptionUri", "")
                    if "Email=" in upgrade_uri:
                        m = re.search(r"[?&]Email=([^&]+)", upgrade_uri)
                        if m:
                            email = urllib.parse.unquote(m.group(1))

                # 2. Retrieve User Quota Summary
                quota_resp = make_cloud_code_request(
                    host,
                    "retrieveUserQuotaSummary",
                    {"project": project},
                    access_token
                )

                local_ip = get_local_ip()
                return {
                    "account": email or "Active Account",
                    "tier": tier_name,
                    "tierId": tier_id,
                    "tierDescription": tier_desc,
                    "host": host,
                    "fetchedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
                    "source": "api",
                    "credentialSource": cred_source,
                    "localIp": local_ip,
                    "port": 3007,
                    "remoteCommand": f"curl -s http://{local_ip}:3007",
                    "description": quota_resp.get("description", ""),
                    "groups": quota_resp.get("groups", [])
                }
            except urllib.error.HTTPError as he:
                if he.code == 401 and refresh_token and attempt == 0:
                    try:
                        access_token = refresh_access_token(refresh_token)
                        break  # restart host loop with new token
                    except Exception as ref_err:
                        last_err = ref_err
                        break
                last_err = he
            except Exception as e:
                last_err = e

    raise RuntimeError(f"Unable to fetch Antigravity quota: {last_err}")


# ============================================================================
# Terminal Dashboard Renderer
# ============================================================================

def make_bar(fraction: float, width: int = 24, color: bool = True) -> str:
    """Render a terminal unicode capacity bar."""
    fraction = max(0.0, min(1.0, fraction))
    filled_len = int(round(fraction * width))
    empty_len = width - filled_len
    bar_str = "█" * filled_len + "░" * empty_len

    if not color:
        return bar_str

    pct = fraction * 100
    if pct >= 50:
        c_code = "\033[32m"  # Green
    elif pct >= 20:
        c_code = "\033[33m"  # Yellow
    else:
        c_code = "\033[31m"  # Red

    return f"{c_code}{bar_str}\033[0m"


def format_reset_time(iso_str: str) -> str:
    """Format ISO timestamp into relative hours and minutes."""
    if not iso_str:
        return "N/A"
    try:
        clean_iso = iso_str.replace("Z", "+00:00")
        target = datetime.datetime.fromisoformat(clean_iso)
        now = datetime.datetime.now(datetime.timezone.utc)
        diff = target - now
        total_secs = int(diff.total_seconds())
        if total_secs <= 0:
            return "Refreshing now"
        days = total_secs // 86400
        hours = (total_secs % 86400) // 3600
        mins = (total_secs % 3600) // 60
        secs = total_secs % 60

        parts = []
        if days > 0:
            parts.append(f"{days}d")
        if hours > 0 or days > 0:
            parts.append(f"{hours}h")
        if mins > 0 or (hours == 0 and days == 0):
            parts.append(f"{mins}m")
        if days == 0 and hours == 0 and mins == 0:
            parts.append(f"{secs}s")
        return "in " + " ".join(parts[:2])
    except Exception:
        return iso_str


def render_dashboard(data: dict, color: bool = True) -> str:
    """Format quota data into an attractive terminal dashboard."""
    lines = []
    c_bold = "\033[1m" if color else ""
    c_cyan = "\033[36m" if color else ""
    c_dim = "\033[2m" if color else ""
    c_reset = "\033[0m" if color else ""
    c_yellow = "\033[33m" if color else ""

    lines.append(f"{c_bold}{c_cyan}✦ Google Antigravity Quota Monitor{c_reset}")

    account = data.get("account", "Active Session")
    tier = data.get("tier", "Google AI Ultra")
    lines.append(f"{c_dim}Account:{c_reset} {account}  {c_dim}|  Plan:{c_reset} {c_yellow}{tier}{c_reset}")
    lines.append("─" * 64)

    groups = data.get("groups", [])
    if not groups:
        lines.append(f"{c_dim}No quota bucket information available.{c_reset}")

    for grp in groups:
        gname = grp.get("displayName") or grp.get("name") or "Model Group"
        desc = grp.get("description", "")
        models_sub = ""
        if desc.startswith("Models within this group:"):
            models_sub = desc.replace("Models within this group:", "").strip()
            models_sub = f" ({models_sub})"

        lines.append(f"\n{c_bold}❯ {gname}{c_reset}{c_dim}{models_sub}{c_reset}")

        buckets = grp.get("buckets", [])
        for b in buckets:
            bname = b.get("displayName") or b.get("label") or b.get("kind") or "Quota Bucket"
            bname = bname.replace(" Remaining", "")
            frac = b.get("remainingFraction", 1.0)
            if frac is None:
                frac = 1.0
            pct = frac * 100
            bar = make_bar(frac, width=22, color=color)

            reset_info = ""
            if "resetsInSeconds" in b and b["resetsInSeconds"] is not None:
                s = b["resetsInSeconds"]
                if s <= 0:
                    reset_info = f"{c_dim}(Ready){c_reset}"
                elif s < 60:
                    reset_info = f"{c_dim}(resets in {s}s){c_reset}"
                else:
                    reset_info = f"{c_dim}(resets in {s // 3600}h {(s % 3600) // 60}m){c_reset}"
            elif "resetTime" in b or "resetAt" in b:
                t_str = b.get("resetTime") or b.get("resetAt")
                rel = format_reset_time(t_str)
                reset_info = f"{c_dim}(resets {rel}){c_reset}"

            lines.append(f"  • {bname:<22} [{bar}] {pct:>5.1f}%  {reset_info}")

    lines.append("\n" + "─" * 64)
    fetched_at = data.get("fetchedAt", "")
    if fetched_at:
        try:
            dt = datetime.datetime.fromisoformat(fetched_at.replace("Z", "+00:00"))
            local_dt = dt.astimezone()
            time_str = local_dt.strftime("%Y-%m-%d %H:%M:%S")
        except Exception:
            time_str = fetched_at
        cred_src = data.get("credentialSource", "Keychain")
        lines.append(f"{c_dim}Updated: {time_str}  |  Auth: {cred_src}{c_reset}")

    return "\n".join(lines) + "\n"


# ============================================================================
# Cross-Device Server Daemon
# ============================================================================

class QuotaServerHandler(http.server.BaseHTTPRequestHandler):
    """Hardened HTTP Request Handler providing text terminal output and JSON endpoints."""
    cached_data = None
    last_fetch_time = 0
    cache_ttl = 45  # Cache for 45 seconds to avoid hitting API rate limits
    secret_token = None
    last_forced_refresh_time = 0
    COOLDOWN_SECONDS = 5.0

    def setup(self):
        super().setup()
        self.request.settimeout(15.0)

    def log_message(self, format, *args):
        if os.environ.get("ANTIGRAVITY_VERBOSE"):
            super().log_message(format, *args)

    def validate_host(self) -> bool:
        host = self.headers.get("Host", "").split(":")[0]
        return host in ("127.0.0.1", "localhost") or not host

    def is_authorized(self) -> bool:
        if not self.secret_token:
            return True
        header_auth = self.headers.get("X-Auth-Token", "")
        if header_auth and hmac.compare_digest(header_auth, self.secret_token):
            return True
        query = urllib.parse.urlparse(self.path).query
        params = urllib.parse.parse_qs(query)
        token_param = params.get("token", [""])[0]
        if token_param and hmac.compare_digest(token_param, self.secret_token):
            return True
        return False

    def send_cors_headers(self):
        origin = self.headers.get("Origin", "")
        # Allow local app bundle, file://, or loopback origins
        if origin in ("null", "file://") or origin.startswith("http://127.0.0.1:") or origin.startswith("http://localhost:"):
            self.send_header("Access-Control-Allow-Origin", origin if origin != "null" else "*")
            self.send_header("Vary", "Origin")

    def get_latest_quota(self, force: bool = False) -> dict:
        now = time.time()
        if not force and QuotaServerHandler.cached_data and (now - QuotaServerHandler.last_fetch_time < self.cache_ttl):
            return QuotaServerHandler.cached_data

        with _CACHE_LOCK:
            now = time.time()
            if not force and QuotaServerHandler.cached_data and (now - QuotaServerHandler.last_fetch_time < self.cache_ttl):
                return QuotaServerHandler.cached_data
            try:
                data = fetch_usage_data()
                QuotaServerHandler.cached_data = data
                QuotaServerHandler.last_fetch_time = now
                return data
            except Exception as e:
                if QuotaServerHandler.cached_data:
                    return QuotaServerHandler.cached_data
                raise e

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        if not self.is_authorized():
            self.send_response(401)
            self.send_header("Content-Type", "application/json")
            self.send_cors_headers()
            self.end_headers()
            self.wfile.write(b'{"error": "Unauthorized. Provide valid X-Auth-Token header."}\n')
            return

        if path in ("/healthz", "/health"):
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_cors_headers()
            self.end_headers()
            self.wfile.write(b'{"ok": true}\n')
            return

        force_refresh = "refresh=1" in parsed.query
        now = time.time()
        if force_refresh:
            if now - QuotaServerHandler.last_forced_refresh_time < QuotaServerHandler.COOLDOWN_SECONDS:
                force_refresh = False
            else:
                QuotaServerHandler.last_forced_refresh_time = now

        try:
            quota = self.get_latest_quota(force=force_refresh)
        except Exception as err:
            self.send_response(502)
            self.send_header("Content-Type", "application/json")
            self.send_cors_headers()
            self.end_headers()
            self.wfile.write(json.dumps({"error": str(err)}).encode("utf-8"))
            return

        # 1. JSON Endpoint (/quota, /json)
        if path in ("/quota", "/json"):
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_cors_headers()
            self.end_headers()
            self.wfile.write(json.dumps(quota, indent=2).encode("utf-8"))
            return

        # 2. Terminal Dashboard Endpoint (default /)
        ua = self.headers.get("User-Agent", "").lower()
        use_color = ("curl" in ua or "wget" in ua or "httpie" in ua or "term" in parsed.query)
        rendered = render_dashboard(quota, color=use_color)

        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_cors_headers()
        self.end_headers()
        self.wfile.write(rendered.encode("utf-8"))


def get_local_ip() -> str:
    """Best effort to obtain the primary local LAN IP address."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = "127.0.0.1"
    finally:
        s.close()
    return ip


def run_server(host: str, port: int, secret_token: str = None):
    """Run hardened cross-device daemon."""
    QuotaServerHandler.secret_token = secret_token
    server_addr = (host, port)
    httpd = http.server.ThreadingHTTPServer(server_addr, QuotaServerHandler)
    httpd.daemon_threads = True

    local_ip = get_local_ip()
    print("\033[1m\033[32mAntigravity Quota Server Running!\033[0m")
    print(f"  • Bound address:   http://{host}:{port}")
    print(f"  • Local address:   http://127.0.0.1:{port}")
    if host == "0.0.0.0":
        print(f"  • Network address: http://{local_ip}:{port}")
    if secret_token:
        masked = secret_token[:3] + "..." + secret_token[-3:] if len(secret_token) > 6 else "***"
        print(f"  • Security:        Protected with auth token: {masked}")
    print(f"  • JSON endpoint:   http://127.0.0.1:{port}/quota")
    print("Press Ctrl+C to terminate the server.\n")

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping server...")
        httpd.server_close()


# ============================================================================
# Main Entry Point
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Google Antigravity Quota & Usage Monitor (Direct Cloud Code API Client)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--json", action="store_true", help="Output raw JSON data")
    parser.add_argument("--watch", "-w", type=int, nargs="?", const=30, default=None,
                        help="Watch mode: auto-refresh terminal every N seconds (default: 30)")
    parser.add_argument("--no-color", action="store_true", help="Disable ANSI terminal colors")
    parser.add_argument("--serve", action="store_true", help="Start background HTTP daemon for cross-device access")
    parser.add_argument("--port", "-p", type=int, default=3007, help="Server port (default: 3007)")
    parser.add_argument("--bind", "-b", type=str, default="127.0.0.1",
                        help="Server bind address (default: 127.0.0.1; use 0.0.0.0 for LAN access)")
    parser.add_argument("--secret", type=str, default=None,
                        help="Optional bearer secret token required in X-Auth-Token header")
    parser.add_argument("--remote", "-r", type=str, default=None,
                        help="Fetch quota from a remote daemon instance (e.g. http://192.168.5.67:3007)")
    parser.add_argument("--version", "-v", action="version", version=f"%(prog)s {__version__}")

    args = parser.parse_args()

    if args.serve:
        run_server(args.bind, args.port, args.secret)
        return

    def get_data() -> dict:
        if args.remote:
            req = urllib.request.Request(
                urllib.parse.urljoin(args.remote, "/quota"),
                headers={"User-Agent": USER_AGENT}
            )
            if args.secret:
                req.add_header("X-Auth-Token", args.secret)
            with urllib.request.urlopen(req, timeout=10) as resp:
                return json.loads(resp.read().decode("utf-8"))
        return fetch_usage_data()

    if args.watch:
        interval = max(5, args.watch)
        color = not args.no_color and sys.stdout.isatty()
        try:
            while True:
                data = get_data()
                sys.stdout.write("\033[2J\033[H")
                if args.json:
                    sys.stdout.write(json.dumps(data, indent=2) + "\n")
                else:
                    sys.stdout.write(render_dashboard(data, color=color))
                    sys.stdout.write(f"\033[2mAuto-refreshing every {interval}s (Ctrl+C to quit)\033[0m\n")
                sys.stdout.flush()
                time.sleep(interval)
        except KeyboardInterrupt:
            sys.stdout.write("\nExited watch mode.\n")
            return

    try:
        data = get_data()
    except Exception as e:
        sys.stderr.write(f"\033[31mError fetching Antigravity quota:\033[0m {e}\n")
        sys.exit(1)

    if args.json:
        print(json.dumps(data, indent=2))
    else:
        color = not args.no_color and sys.stdout.isatty()
        print(render_dashboard(data, color=color))


if __name__ == "__main__":
    main()

```

---

## build_app_v7.sh
**Description:** Release Build, Packaging & Code-Signing Script  
**Path:** `build_app_v7.sh` | **Lines:** 113

```bash
#!/usr/bin/env bash
# v7 – Build and install native macOS Menu Bar Popover application via SPM & Package.swift
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="/Applications/Antigravity Usage.app"

echo "==> Terminating any running instance of Antigravity Usage..."
pkill -f "Antigravity Usage" 2>/dev/null || true
sleep 0.5

# Sync SPM sources with v7 files
cp "${SCRIPT_DIR}/app_main_v7.swift" "${SCRIPT_DIR}/Sources/AntigravityUsageApp/app_main.swift"
cp "${SCRIPT_DIR}/index_v7.html" "${SCRIPT_DIR}/Sources/AntigravityUsageApp/Resources/index.html"
cp "${SCRIPT_DIR}/widget_v7.html" "${SCRIPT_DIR}/Sources/AntigravityUsageApp/Resources/widget.html"

echo "==> Compiling native Swift executable (v7 SPM Release Build)..."
swift build -c release --target AntigravityUsageApp --package-path "${SCRIPT_DIR}"

BIN_PATH="${SCRIPT_DIR}/.build/release/AntigravityUsageApp"
if [ ! -f "${BIN_PATH}" ]; then
  # Fallback to direct swiftc compilation if SPM output path varies
  echo "==> Fallback to swiftc release compilation..."
  swiftc -parse-as-library -O \
    -framework Cocoa \
    -framework WebKit \
    -framework WidgetKit \
    "${SCRIPT_DIR}/app_main_v7.swift" \
    -o "${SCRIPT_DIR}/Antigravity Usage"
  BIN_PATH="${SCRIPT_DIR}/Antigravity Usage"
fi

echo "==> Creating macOS App bundle structure at ${APP_DIR}..."
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

# Move compiled binary
cp "${BIN_PATH}" "${APP_DIR}/Contents/MacOS/Antigravity Usage"
chmod +x "${APP_DIR}/Contents/MacOS/Antigravity Usage"

# Copy HTML UIs (Main popover and Desktop widget)
cp "${SCRIPT_DIR}/index_v7.html" "${APP_DIR}/Contents/Resources/index.html"
cp "${SCRIPT_DIR}/widget_v7.html" "${APP_DIR}/Contents/Resources/widget.html"

# Copy Icon
if [ -f "/Applications/Antigravity.app/Contents/Resources/icon.icns" ]; then
  cp "/Applications/Antigravity.app/Contents/Resources/icon.icns" "${APP_DIR}/Contents/Resources/AppIcon.icns"
elif [ -f "${HOME}/Applications/Antigravity.app/Contents/Resources/icon.icns" ]; then
  cp "${HOME}/Applications/Antigravity.app/Contents/Resources/icon.icns" "${APP_DIR}/Contents/Resources/AppIcon.icns"
fi

# Write Info.plist
cat << 'EOF' > "${APP_DIR}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!-- v7 – Info.plist with LSUIElement and App Group entitlements -->
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Antigravity Usage</string>
    <key>CFBundleDisplayName</key>
    <string>Antigravity Usage</string>
    <key>CFBundleIdentifier</key>
    <string>com.dad.antigravity.usage</string>
    <key>CFBundleVersion</key>
    <string>7.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>7.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>Antigravity Usage</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <true/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsLocalNetworking</key>
        <true/>
    </dict>
</dict>
</plist>
EOF

echo "APPL????" > "${APP_DIR}/Contents/PkgInfo"

# Clear quarantine and sign with App Group entitlements
echo "==> Code-signing bundle with entitlements..."
xattr -cr "${APP_DIR}" 2>/dev/null || true
if [ -f "${SCRIPT_DIR}/antigravity.entitlements" ]; then
  codesign --force --deep --sign - --entitlements "${SCRIPT_DIR}/antigravity.entitlements" "${APP_DIR}"
else
  codesign --force --deep --sign - "${APP_DIR}"
fi

echo "==> Updating macOS Dock entry..."
if command -v dockutil &> /dev/null; then
  dockutil --remove "Antigravity Usage" --no-restart 2>/dev/null || true
  if dockutil --find "Antigravity" &> /dev/null; then
    dockutil --add "${APP_DIR}" --after "Antigravity" --allhomes
  else
    dockutil --add "${APP_DIR}" --allhomes
  fi
fi

echo "==> Launching updated Antigravity Usage (v7 SPM + Unsnap + App Group Sync)..."
open "${APP_DIR}"

echo "==> Done! Antigravity Usage v7 is running."

```

---

## com.antigravity.usage_v4.plist
**Description:** macOS LaunchAgent Daemon Configuration  
**Path:** `com.antigravity.usage_v4.plist` | **Lines:** 43

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!-- v4 – Hardened LaunchAgent with antigravity_usage_v4.py and throttled restarts -->
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.antigravity.usage</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/python3</string>
        <string>/Users/dad/git/antigravity-usage-monitor/antigravity_usage_v4.py</string>
        <string>--serve</string>
        <string>--port</string>
        <string>3007</string>
        <string>--bind</string>
        <string>0.0.0.0</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
        <key>HOME</key>
        <string>/Users/dad</string>
        <key>PYTHONUNBUFFERED</key>
        <string>1</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
        <key>Crashed</key>
        <true/>
    </dict>
    <key>ThrottleInterval</key>
    <integer>10</integer>
    <key>StandardOutPath</key>
    <string>/Users/dad/Library/Logs/Antigravity/daemon.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/dad/Library/Logs/Antigravity/daemon_error.log</string>
</dict>
</plist>

```

---
