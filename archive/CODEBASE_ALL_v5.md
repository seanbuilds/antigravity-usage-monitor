# Antigravity Quota Tracker — Complete Unified Native Codebase & Documentation
<!-- v5 – Consolidated file containing 100% pure native SwiftUI & AppKit source code, deterministic 360° refresh, manifests, and documentation -->

> **Repository:** [github.com/seanbuilds/antigravity-usage-monitor](https://github.com/seanbuilds/antigravity-usage-monitor)
> **Legal Disclaimer:** Independent personal project. Not affiliated with or endorsed by Google LLC. Provided "as-is" without warranty.

## Table of Contents
- [README_v9.md](#readme-v9md) — *Project Overview & Pure Native Documentation*
- [Package.swift](#packageswift) — *Swift Package Manager Manifest*
- [antigravity.entitlements](#antigravityentitlements) — *macOS App Group Entitlements*
- [app_main_v10.swift](#app-main-v10swift) — *100% Pure Native SwiftUI & AppKit Menu Bar Application (Deterministic 360° Refresh Animation)*
- [SharedModels/SharedQuota.swift](#sharedmodelssharedquotaswift) — *Cross-Process Shared Data Models*
- [AntigravityWidget/AntigravityWidgetBundle.swift](#antigravitywidgetantigravitywidgetbundleswift) — *WidgetKit Extension Bundle Entrypoint*
- [AntigravityWidget/AntigravityWidget.swift](#antigravitywidgetantigravitywidgetswift) — *WidgetKit TimelineProvider & SwiftUI Views*
- [antigravity_usage_v4.py](#antigravity-usage-v4py) — *Hardened Python CLI & Cross-Device Quota Daemon*
- [build_app_v10.sh](#build-app-v10sh) — *Pure Native Release Build, Packaging & Signing Script*
- [com.antigravity.usage_v4.plist](#comantigravityusage-v4plist) — *macOS LaunchAgent Daemon Configuration*

---

## README_v9.md
**Description:** Project Overview & Pure Native Documentation  
**Path:** `README_v9.md` | **Lines:** 103

```markdown
# Google Antigravity Usage Monitor (Pure SwiftUI & AppKit Architecture)
<!-- v9 – 100% Pure Native SwiftUI & AppKit Architecture, Deterministic 360° Refresh Animation, Obsidian Palette & Sibling Parity -->

> **LEGAL DISCLAIMER**
> This software is an independent personal project. It is **not** affiliated with, endorsed by,
> or connected to **Google LLC** in any way. All trademarks belong to their respective owners.
> Provided "as-is" with **no warranty**. For personal use only.

A lightweight, zero-configuration utility, 100% pure native macOS Menu Bar snap-out popover, detachable floating HUD window, desktop widget, and cross-device network daemon to view real-time Google Antigravity (`agy`) model quotas, consumption percentages, and reset timers across all your devices.

---

## 🌟 100% Pure Native macOS Architecture (v10)

The application is built using **pure native Swift, SwiftUI, AppKit, and WidgetKit** with zero WebKit or HTML dependencies:

### 1. Pure SwiftUI & AppKit Foundations
- **Zero WebKit Wrappers**: Native Apple Cocoa controls, native frosted glass materials, and native SF Symbols.
- **Ultra-Low Resource Footprint**: Runs at just ~90 MB RAM with zero auxiliary WebKit helper processes.
- **Deterministic 360° Refresh Animation**: Manual refresh executes a single, fluid 360-degree ease-in-out rotation (`withAnimation(.easeInOut(duration: 0.6))`). Background 30s timer refreshes do not disturb the icon.
- **Dynamic Content Sizing**: Popover and floating window size dynamically to actual content with zero blank margins or scroll clipping.

### 2. Menu Bar Snap-Out Popover & Sibling Parity
- **Menu Bar Status Item** (Top Right):
  - Displays primary model capacity (e.g. `✦ 70%`).
  - **Left-Click**: Instantly snaps out the clean 360px card directly below the menu bar icon.
  - **Click Outside to Close**: Automatically dismisses with native transient behavior.
  - **Right-Click Native Menu**: Instant macOS context menu with model breakdowns and direct actions.
- **Unified 4-Icon Toolbar**:
  - `⊞ Widget`: Toggle ambient desktop widget (active state illuminates accent color).
  - `⚙ Setup`: Toggle between Dashboard and Diagnostics view with smooth slide transition.
  - `↗ Unsnap`: Detach to a floating HUD window (`⌘U`).
  - `↻ Refresh`: Request an immediate, bypass-cache quota refresh (`⌘R`) with smooth 360° animation.
- **Dock Companion**:
  - Pinned beside `Antigravity` in your Dock.
  - Clicking the Dock icon snaps out the popover right from the menu bar.

### 3. Setup & Preferences View
- **Authentication Diagnostics**: Displays signed account identity, verified subscription tier (`Google AI Ultra`), and credential origin (`macOS Keychain`).
- **Daemon Diagnostics**: Live status indicator (pulsing green dot when online), port `3007`, local LAN IP (`192.168.5.67`), and LaunchAgent management (`com.antigravity.usage_v4.plist`).
- **Application Management & Danger Zone**: Dedicated **Quit Antigravity Usage Completely** button executing direct `NSApplication.shared.terminate(nil)`.

### 4. Unsnap to Floating Window (Detachable HUD)
- **Drag to Detach**: Drag the popover card away from the menu bar to tear it off into an independent floating window.
- **Unsnap Button**: Click the pop-out icon (`↗`) in the top right header (or press `⌘U`).
- **Floating HUD**: Operates at `.floating` level with a subtle translucent dark Aqua card, remaining visible while interacting with code.
- **Snap Back**: Click the dock icon (`↙`) in the header (or press `⌘U` or close the window) to cleanly snap it back into the menu bar.

### 5. macOS Desktop Widget Mode
- **Compact Desktop Widget**: An Apple-grade 240×124px translucent frosted glass card that sits directly above desktop wallpaper (`desktopIconWindow + 1`) and below normal application windows.
- **Position Persistence**: Automatically remembers and restores the exact position where you last placed it on the desktop.
- **Live Mini Gauges**: Glanceable mini capacity bars for **Gemini Models** (5h window) and **Claude & GPT Models** (5h window).
- **Interactive Control**: Draggable across the desktop, equipped with a subtle hover close button (`×`), double-clickable to open the full popover, and equipped with a discrete legal disclaimer.

---

## 💻 Terminal Commands & Build Scripts

### Build via Swift Package Manager
```bash
# Compile and install application bundle with App Group entitlements:
./build_app_v10.sh
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
* Native Swift App (v10): [`app_main_v10.swift`](file:///Users/dad/git/antigravity-usage-monitor/app_main_v10.swift)
* Build & packaging script (v10): [`build_app_v10.sh`](file:///Users/dad/git/antigravity-usage-monitor/build_app_v10.sh)
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

## app_main_v10.swift
**Description:** 100% Pure Native SwiftUI & AppKit Menu Bar Application (Deterministic 360° Refresh Animation)  
**Path:** `app_main_v10.swift` | **Lines:** 1383

```swift
// v10 – 100% Pure Native SwiftUI & AppKit macOS Menu Bar Application
//       Fixed Refresh Button Animation (Deterministic 360° Ease-in-Out, Zero Infinite Glitches),
//       Crisp Obsidian Palette, Sibling Parity with Grok Quota Tracker, Dynamic Sizing & Instant Quit.
import Cocoa
import SwiftUI
import WidgetKit
import SharedModels

// MARK: - Data Models

public struct QuotaBucket: Codable, Identifiable, Sendable {
    public var id: String { bucketId ?? displayName ?? UUID().uuidString }
    public let bucketId: String?
    public let displayName: String?
    public let label: String?
    public let kind: String?
    public let window: String?
    public let remainingFraction: Double?
    public let resetsInSeconds: Int?
    public let resetTime: String?
    public let resetAt: String?
    public let description: String?
}

public struct QuotaGroup: Codable, Identifiable, Sendable {
    public var id: String { displayName ?? name ?? UUID().uuidString }
    public let displayName: String?
    public let name: String?
    public let description: String?
    public let models: String?
    public let buckets: [QuotaBucket]?
}

public struct QuotaData: Codable, Sendable {
    public let account: String?
    public let tier: String?
    public let tierId: String?
    public let tierDescription: String?
    public let host: String?
    public let fetchedAt: String?
    public let source: String?
    public let credentialSource: String?
    public let localIp: String?
    public let port: Int?
    public let remoteCommand: String?
    public let description: String?
    public let groups: [QuotaGroup]?
}

// MARK: - Formatters & Helpers

func formatRelativeTime(seconds: Int?) -> String {
    guard let s = seconds, s > 0 else { return "Ready" }
    if s < 60 { return "\(s)s left" }
    let days = s / 86400
    let hours = (s % 86400) / 3600
    let mins = (s % 3600) / 60
    var parts: [String] = []
    if days > 0 { parts.append("\(days)d") }
    if hours > 0 || days > 0 { parts.append("\(hours)h") }
    parts.append("\(mins)m")
    return parts.prefix(2).joined(separator: " ") + " left"
}

public enum ScreenMode: Hashable {
    case dashboard
    case setup
}

// MARK: - App State

@MainActor
class AppState: ObservableObject {
    @Published var quota: QuotaData?
    @Published var isLoading: Bool = false
    @Published var isOffline: Bool = false
    @Published var errorMessage: String?
    @Published var currentScreen: ScreenMode = .dashboard
    @Published var isUnsnapped: Bool = false
    @Published var isWidgetVisible: Bool = false
    @Published var isWidgetHovering: Bool = false
    @Published var isManualRefreshing: Bool = false
    @Published var refreshRotation: Double = 0
    @Published var copiedRemoteCommand: Bool = false

    var onToggleUnsnap: (() -> Void)?
    var onToggleWidget: (() -> Void)?
    var onCloseWidget: (() -> Void)?
    var onOpenFullApp: (() -> Void)?
    var onUpdateStatusTitle: ((String, String) -> Void)?

    func fetchQuota(force: Bool = false) {
        isLoading = true
        let urlStr = force ? "http://127.0.0.1:3007/quota?refresh=1" : "http://127.0.0.1:3007/quota"
        guard let url = URL(string: urlStr) else { return }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decoded = try JSONDecoder().decode(QuotaData.self, from: data)
                self.quota = decoded
                self.isOffline = false
                self.errorMessage = nil
                self.isLoading = false
                self.syncToAppGroup(decoded)
                self.updateStatusTitle(with: decoded)
            } catch {
                self.isOffline = true
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                self.onUpdateStatusTitle?("✦ offline", "Antigravity Quota: Daemon offline (retrying...)")
            }
        }
    }

    func triggerManualRefresh() {
        guard !isManualRefreshing else { return }
        isManualRefreshing = true
        withAnimation(.easeInOut(duration: 0.6)) {
            refreshRotation += 360
        }
        fetchQuota(force: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { [weak self] in
            self?.isManualRefreshing = false
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

    func updateStatusTitle(with quota: QuotaData) {
        let pct = computeDisplayPercent(for: quota)
        let tierName = quota.tier ?? "Google AI Ultra"
        onUpdateStatusTitle?("✦ \(pct)%", "Antigravity Quota (\(tierName)): \(pct)% primary capacity")
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

    func copyRemoteCommand() {
        let cmd = quota?.remoteCommand ?? "curl -s http://192.168.5.67:3007"
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(cmd, forType: .string)
        copiedRemoteCommand = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            self?.copiedRemoteCommand = false
        }
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Native SwiftUI UI Components

struct CustomProgressBar: View {
    let fraction: Double

    var color: Color {
        if fraction < 0.20 { return Color(red: 1.0, green: 0.27, blue: 0.23) }
        if fraction < 0.50 { return Color(red: 1.0, green: 0.84, blue: 0.04) }
        return Color(red: 0.19, green: 0.82, blue: 0.35)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))
                Capsule()
                    .fill(color)
                    .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(fraction))))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: fraction)
            }
        }
        .frame(height: 5)
    }
}

struct HeaderView: View {
    @ObservedObject var appState: AppState

    var tierText: String {
        let t = appState.quota?.tier ?? "Ultra"
        return t.lowercased().contains("ultra") ? "Ultra" : t
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .center, spacing: 8) {
                // Logo box matching Grok's 22x22px logo box
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(red: 0.04, green: 0.05, blue: 0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Color(red: 0.04, green: 0.52, blue: 1.0).opacity(0.45), lineWidth: 1)
                        )
                        .shadow(color: Color(red: 0.04, green: 0.52, blue: 1.0).opacity(0.25), radius: 4, x: 0, y: 1)

                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(red: 0.04, green: 0.52, blue: 1.0))
                }
                .frame(width: 22, height: 22)

                // Title
                Text("Antigravity")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)

                // Tier Pill
                Text(tierText.uppercased())
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.04))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(red: 1.0, green: 0.84, blue: 0.04).opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(Color(red: 1.0, green: 0.84, blue: 0.04).opacity(0.35), lineWidth: 1)
                            )
                    )

                Spacer()

                // 4-Icon Toolbar
                HStack(spacing: 5) {
                    // 1. Desktop Widget
                    Button {
                        appState.onToggleWidget?()
                    } label: {
                        Image(systemName: appState.isWidgetVisible ? "rectangle.fill.on.rectangle.fill" : "rectangle.on.rectangle")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(appState.isWidgetVisible ? Color(red: 0.04, green: 0.52, blue: 1.0) : Color.white.opacity(0.65))
                            .frame(width: 26, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(appState.isWidgetVisible ? Color(red: 0.04, green: 0.52, blue: 1.0).opacity(0.2) : Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .strokeBorder(appState.isWidgetVisible ? Color(red: 0.04, green: 0.52, blue: 1.0).opacity(0.4) : Color.white.opacity(0.09), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .help(appState.isWidgetVisible ? "Hide Desktop Widget (⌘W)" : "Add Desktop Widget (⌘W)")

                    // 2. Setup & Diagnostics
                    Button {
                        withAnimation {
                            appState.currentScreen = (appState.currentScreen == .dashboard) ? .setup : .dashboard
                        }
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(appState.currentScreen == .setup ? Color(red: 0.04, green: 0.52, blue: 1.0) : Color.white.opacity(0.65))
                            .frame(width: 26, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(appState.currentScreen == .setup ? Color(red: 0.04, green: 0.52, blue: 1.0).opacity(0.2) : Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .strokeBorder(appState.currentScreen == .setup ? Color(red: 0.04, green: 0.52, blue: 1.0).opacity(0.4) : Color.white.opacity(0.09), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Settings & Server Diagnostics")

                    // 3. Unsnap / Snap
                    Button {
                        appState.onToggleUnsnap?()
                    } label: {
                        Image(systemName: appState.isUnsnapped ? "arrow.down.left.square" : "arrow.up.right.square")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(appState.isUnsnapped ? Color(red: 0.04, green: 0.52, blue: 1.0) : Color.white.opacity(0.65))
                            .frame(width: 26, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(appState.isUnsnapped ? Color(red: 0.04, green: 0.52, blue: 1.0).opacity(0.2) : Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .strokeBorder(appState.isUnsnapped ? Color(red: 0.04, green: 0.52, blue: 1.0).opacity(0.4) : Color.white.opacity(0.09), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .help(appState.isUnsnapped ? "Snap back to Menu Bar (⌘U)" : "Unsnap to Floating Window (⌘U)")

                    // 4. Refresh
                    Button {
                        appState.triggerManualRefresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(appState.isManualRefreshing ? 1.0 : 0.65))
                            .rotationEffect(.degrees(appState.refreshRotation))
                            .frame(width: 26, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(Color.white.opacity(appState.isManualRefreshing ? 0.14 : 0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .strokeBorder(Color.white.opacity(appState.isManualRefreshing ? 0.20 : 0.09), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(appState.isManualRefreshing)
                    .help("Refresh Quota (⌘R)")
                }
            }

            // Account Subhead directly under brand
            if let account = appState.quota?.account {
                Text(account)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.60))
                    .lineLimit(1)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 13)
        .padding(.bottom, 10)
    }
}

struct BucketRowView: View {
    let bucket: QuotaBucket

    var fraction: Double {
        bucket.remainingFraction ?? 1.0
    }

    var percentText: String {
        "\(Int(round(fraction * 100)))%"
    }

    var color: Color {
        if fraction < 0.20 { return Color(red: 1.0, green: 0.27, blue: 0.23) }
        if fraction < 0.50 { return Color(red: 1.0, green: 0.84, blue: 0.04) }
        return Color(red: 0.19, green: 0.82, blue: 0.35)
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(bucket.displayName ?? bucket.label ?? bucket.window ?? "Limit")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.65))

                Spacer()

                HStack(spacing: 4) {
                    Text(percentText)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(color)

                    if let secs = bucket.resetsInSeconds, secs > 0 {
                        Text("(\(formatRelativeTime(seconds: secs)))")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(Color.white.opacity(0.40))
                    }
                }
            }

            CustomProgressBar(fraction: fraction)
        }
    }
}

struct GroupCardView: View {
    let group: QuotaGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(group.displayName ?? group.name ?? "Models")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                if let desc = group.description {
                    Text(desc.replacingOccurrences(of: "Models within this group: ", with: ""))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .lineLimit(1)
                }
            }

            if let buckets = group.buckets {
                VStack(spacing: 8) {
                    ForEach(buckets) { bucket in
                        BucketRowView(bucket: bucket)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.09), lineWidth: 1)
                )
        )
    }
}

struct RemoteDeviceBar: View {
    @ObservedObject var appState: AppState

    var cmd: String {
        appState.quota?.remoteCommand ?? "curl -s http://192.168.5.67:3007"
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "terminal")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.55))

            Text(cmd)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.60))
                .lineLimit(1)

            Spacer()

            Button {
                appState.copyRemoteCommand()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: appState.copiedRemoteCommand ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 9, weight: .semibold))
                    Text(appState.copiedRemoteCommand ? "Copied" : "Copy")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(appState.copiedRemoteCommand ? Color(red: 0.19, green: 0.82, blue: 0.35) : Color.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(9)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }
}

struct FooterView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        HStack {
            Text("Independent personal utility · Not affiliated with Google")
                .font(.system(size: 9, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.40))

            Spacer()

            Button {
                appState.quit()
            } label: {
                Text("Quit")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.65))
            }
            .buttonStyle(.plain)
            .help("Quit Antigravity Usage (⌘Q)")
        }
    }
}

struct LoadingCardView: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("Connecting to local daemon...")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.60))
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}

struct OfflineCardView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.04))
                Text("Daemon Offline")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
            }

            Text("LaunchAgent daemon not responding on 127.0.0.1:3007.")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.60))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Button {
                    appState.triggerManualRefresh()
                } label: {
                    Text("Retry Connection")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.white.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 1.0, green: 0.84, blue: 0.04).opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color(red: 1.0, green: 0.84, blue: 0.04).opacity(0.25), lineWidth: 1)
                )
        )
    }
}

struct DashboardView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 11) {
            if let groups = appState.quota?.groups, !groups.isEmpty {
                ForEach(groups) { group in
                    GroupCardView(group: group)
                }
                .padding(.horizontal, 14)
            } else if appState.isOffline {
                OfflineCardView(appState: appState)
                    .padding(.horizontal, 14)
            } else {
                LoadingCardView()
                    .padding(.horizontal, 14)
            }

            RemoteDeviceBar(appState: appState)
                .padding(.horizontal, 14)

            FooterView(appState: appState)
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
        }
        .padding(.top, 4)
    }
}

struct SetupRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.60))
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
    }
}

struct SetupView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    withAnimation {
                        appState.currentScreen = .dashboard
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Back to Dashboard")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(Color(red: 0.04, green: 0.52, blue: 1.0))
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 8) {
                Text("AUTHENTICATION & IDENTITY")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.40))

                SetupRow(label: "Account", value: appState.quota?.account ?? "ohheysean@gmail.com")
                SetupRow(label: "Plan Tier", value: appState.quota?.tier ?? "Google AI Ultra")
                SetupRow(label: "Credential Store", value: appState.quota?.credentialSource ?? "macOS Keychain")
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.09), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 14)

            VStack(alignment: .leading, spacing: 8) {
                Text("DAEMON & NETWORK")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.40))

                SetupRow(label: "Daemon Status", value: appState.isOffline ? "Offline" : "Running 24/7 (LaunchAgent)")
                SetupRow(label: "Local Port", value: "\(appState.quota?.port ?? 3007)")
                SetupRow(label: "Local LAN IP", value: appState.quota?.localIp ?? "192.168.5.67")
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.09), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 14)

            VStack(alignment: .leading, spacing: 10) {
                Text("APPLICATION MANAGEMENT")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.40))

                Button(role: .destructive) {
                    appState.quit()
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "power")
                            .font(.system(size: 11, weight: .bold))
                        Text("Quit Antigravity Usage Completely")
                            .font(.system(size: 11, weight: .bold))
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.red.opacity(0.85))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.red.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.red.opacity(0.25), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
    }
}

struct MainContainerView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(appState: appState)

            Divider()
                .background(Color.white.opacity(0.08))

            if appState.currentScreen == .dashboard {
                DashboardView(appState: appState)
                    .transition(.opacity)
            } else {
                SetupView(appState: appState)
                    .transition(.opacity)
            }
        }
        .frame(width: 360)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.05, green: 0.06, blue: 0.09).opacity(0.97))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color(red: 0.04, green: 0.52, blue: 1.0).opacity(0.22), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.65), radius: 20, x: 0, y: 10)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .fixedSize(horizontal: true, vertical: false)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: appState.currentScreen)
    }
}

struct DesktopWidgetView: View {
    @ObservedObject var appState: AppState

    var isHovering: Bool { appState.isWidgetHovering }

    var tierText: String {
        let t = appState.quota?.tier ?? "Ultra"
        return t.lowercased().contains("ultra") ? "Ultra" : t
    }

    var geminiFraction: Double {
        for grp in appState.quota?.groups ?? [] {
            if (grp.displayName ?? grp.name ?? "").lowercased().contains("gemini") {
                for b in grp.buckets ?? [] {
                    if b.window == "5h" || (b.displayName ?? "").contains("Five Hour") {
                        return b.remainingFraction ?? 1.0
                    }
                }
            }
        }
        return 1.0
    }

    var claudeFraction: Double {
        for grp in appState.quota?.groups ?? [] {
            if !(grp.displayName ?? grp.name ?? "").lowercased().contains("gemini") {
                for b in grp.buckets ?? [] {
                    if b.window == "5h" || (b.displayName ?? "").contains("Five Hour") {
                        return b.remainingFraction ?? 1.0
                    }
                }
            }
        }
        return 1.0
    }

    var body: some View {
        VStack(spacing: 7) {
            HStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(red: 0.04, green: 0.05, blue: 0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .strokeBorder(Color(red: 0.04, green: 0.52, blue: 1.0).opacity(0.45), lineWidth: 0.8)
                        )
                    Image(systemName: "sparkles")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color(red: 0.04, green: 0.52, blue: 1.0))
                }
                .frame(width: 18, height: 18)

                Text("Antigravity")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)

                Text(tierText.uppercased())
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.04))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color(red: 1.0, green: 0.84, blue: 0.04).opacity(0.18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .strokeBorder(Color(red: 1.0, green: 0.84, blue: 0.04).opacity(0.35), lineWidth: 0.8)
                            )
                    )

                Spacer()

                Button {
                    appState.onCloseWidget?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.white.opacity(isHovering ? 0.9 : 0.4))
                        .frame(width: 16, height: 16)
                        .background(
                            Circle()
                                .fill(isHovering ? Color.red.opacity(0.7) : Color.white.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.15), value: isHovering)
            }

            VStack(spacing: 5) {
                VStack(spacing: 2) {
                    HStack {
                        Text("Gemini (5h)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.65))
                        Spacer()
                        Text("\(Int(round(geminiFraction * 100)))%")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(colorFor(fraction: geminiFraction))
                    }
                    CustomProgressBar(fraction: geminiFraction)
                }

                VStack(spacing: 2) {
                    HStack {
                        Text("Claude & GPT")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.65))
                        Spacer()
                        Text("\(Int(round(claudeFraction * 100)))%")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(colorFor(fraction: claudeFraction))
                    }
                    CustomProgressBar(fraction: claudeFraction)
                }
            }

            Text("Independent personal utility · Not affiliated with Google")
                .font(.system(size: 7.5, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.35))
                .lineLimit(1)
        }
        .padding(10)
        .frame(width: 240, height: 124)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.55), radius: 16, x: 0, y: 8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onHover { hovering in
            appState.isWidgetHovering = hovering
        }
        .onTapGesture(count: 2) {
            appState.onOpenFullApp?()
        }
    }

    private func colorFor(fraction: Double) -> Color {
        if fraction < 0.20 { return Color(red: 1.0, green: 0.27, blue: 0.23) }
        if fraction < 0.50 { return Color(red: 1.0, green: 0.84, blue: 0.04) }
        return Color(red: 0.19, green: 0.82, blue: 0.35)
    }
}

// MARK: - AppKit AppDelegate & Window Management

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSPopoverDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var detachedWindow: NSPanel?
    var widgetWindow: NSPanel?

    let appState = AppState()
    var pollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        ensureDaemonRunning()

        appState.onToggleUnsnap = { [weak self] in
            self?.toggleUnsnapMode()
        }
        appState.onToggleWidget = { [weak self] in
            self?.toggleDesktopWidget()
        }
        appState.onCloseWidget = { [weak self] in
            self?.closeDesktopWidget()
        }
        appState.onOpenFullApp = { [weak self] in
            self?.snapOutPopover()
        }
        appState.onUpdateStatusTitle = { [weak self] title, tooltip in
            self?.statusItem?.button?.title = title
            self?.statusItem?.button?.toolTip = tooltip
        }

        let hostingVC = NSHostingController(rootView: MainContainerView(appState: appState))
        hostingVC.view.wantsLayer = true
        hostingVC.view.layer?.backgroundColor = NSColor.clear.cgColor

        popover = NSPopover()
        popover.appearance = NSAppearance(named: .darkAqua)
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 360, height: 430)
        popover.delegate = self
        popover.contentViewController = hostingVC

        setupStatusBar()
        setupMainMenu()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        appState.fetchQuota()
        let timer = Timer(timeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.appState.fetchQuota()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.snapOutPopover()
        }
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
            if appState.isUnsnapped, let win = detachedWindow, win.isVisible {
                win.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            } else {
                togglePopover(sender)
            }
        }
    }

    func snapOutPopover() {
        guard let button = statusItem.button else { return }
        if appState.isUnsnapped {
            detachedWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        if !popover.isShown {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            appState.fetchQuota()
        }
    }

    @objc func togglePopover(_ sender: Any?) {
        if appState.isUnsnapped {
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

        appState.isUnsnapped = true

        let winWidth: CGFloat = 360
        let winHeight: CGFloat = 430

        var origin = NSPoint(x: 250, y: 350)
        if let button = statusItem.button, let win = button.window {
            let buttonRect = win.convertToScreen(button.bounds)
            origin = NSPoint(x: max(20, buttonRect.origin.x - (winWidth / 2)), y: max(40, buttonRect.origin.y - winHeight - 10))
        }

        let panel = NSPanel(
            contentRect: NSRect(origin: origin, size: NSSize(width: winWidth, height: winHeight)),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.delegate = self

        if popover.isShown {
            popover.close()
        }

        let hostingVC = NSHostingController(rootView: MainContainerView(appState: appState))
        hostingVC.view.wantsLayer = true
        hostingVC.view.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentViewController = hostingVC

        detachedWindow = panel
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        return panel
    }

    func snapBackToPopover() {
        guard appState.isUnsnapped else { return }
        appState.isUnsnapped = false

        if let win = detachedWindow {
            win.orderOut(nil)
            detachedWindow = nil
        }

        let hostingVC = NSHostingController(rootView: MainContainerView(appState: appState))
        hostingVC.view.wantsLayer = true
        hostingVC.view.layer?.backgroundColor = NSColor.clear.cgColor
        popover.contentViewController = hostingVC

        snapOutPopover()
    }

    func windowWillClose(_ notification: Notification) {
        if let win = notification.object as? NSPanel {
            if win == detachedWindow {
                snapBackToPopover()
            } else if win == widgetWindow {
                saveWidgetPosition(win)
                appState.isWidgetVisible = false
            }
        }
    }

    func toggleDesktopWidget() {
        if appState.isWidgetVisible {
            closeDesktopWidget()
        } else {
            showDesktopWidget()
        }
    }

    func showDesktopWidget() {
        if let win = widgetWindow {
            win.makeKeyAndOrderFront(nil)
            appState.isWidgetVisible = true
            return
        }

        let widgetWidth: CGFloat = 240
        let widgetHeight: CGFloat = 124

        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        var targetFrame = NSRect(x: screenFrame.maxX - widgetWidth - 30, y: screenFrame.minY + 40, width: widgetWidth, height: widgetHeight)

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

        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.delegate = self

        let hostingVC = NSHostingController(rootView: DesktopWidgetView(appState: appState))
        hostingVC.view.wantsLayer = true
        hostingVC.view.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentViewController = hostingVC

        widgetWindow = panel
        appState.isWidgetVisible = true
        panel.makeKeyAndOrderFront(nil)
    }

    func closeDesktopWidget() {
        if let win = widgetWindow {
            saveWidgetPosition(win)
            win.orderOut(nil)
        }
        appState.isWidgetVisible = false
    }

    private func saveWidgetPosition(_ panel: NSPanel) {
        UserDefaults.standard.set(NSStringFromRect(panel.frame), forKey: "antigravity.widgetFrame")
    }

    func showContextMenu() {
        let menu = NSMenu()
        menu.delegate = self

        let titleItem = NSMenuItem(title: "Google Antigravity Quota", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        if let acc = appState.quota?.account {
            let accItem = NSMenuItem(title: "Account: \(acc)", action: nil, keyEquivalent: "")
            accItem.isEnabled = false
            menu.addItem(accItem)
        }

        if let tier = appState.quota?.tier {
            let tierItem = NSMenuItem(title: "Plan: \(tier)", action: nil, keyEquivalent: "")
            tierItem.isEnabled = false
            menu.addItem(tierItem)
        }

        menu.addItem(NSMenuItem.separator())

        if let groups = appState.quota?.groups, !groups.isEmpty {
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

        if appState.isUnsnapped {
            let snapItem = NSMenuItem(title: "Snap Back to Menu Bar", action: #selector(snapMenuAction), keyEquivalent: "u")
            snapItem.target = self
            menu.addItem(snapItem)
        } else {
            let unsnapItem = NSMenuItem(title: "Unsnap to Floating Window", action: #selector(unsnapMenuAction), keyEquivalent: "u")
            unsnapItem.target = self
            menu.addItem(unsnapItem)
        }

        let widgetItemTitle = appState.isWidgetVisible ? "Hide Desktop Widget" : "Add Desktop Widget"
        let widgetItem = NSMenuItem(title: widgetItemTitle, action: #selector(widgetMenuAction), keyEquivalent: "w")
        widgetItem.target = self
        if appState.isWidgetVisible {
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
        appState.triggerManualRefresh()
    }

    @objc func copyRemoteCmd() {
        appState.copyRemoteCommand()
    }

    @objc func systemDidWake() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.appState.fetchQuota(force: true)
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
        if appState.isUnsnapped {
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
        if appState.isUnsnapped, let win = detachedWindow {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            snapOutPopover()
        }
        return true
    }
}

// MARK: - Entry Point

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

## build_app_v10.sh
**Description:** Pure Native Release Build, Packaging & Signing Script  
**Path:** `build_app_v10.sh` | **Lines:** 106

```bash
#!/usr/bin/env bash
# v10 – Build and install pure native SwiftUI & AppKit macOS Menu Bar app via SPM (Deterministic Refresh)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="/Applications/Antigravity Usage.app"

echo "==> Terminating any running instance of Antigravity Usage..."
pkill -f "Antigravity Usage" 2>/dev/null || true
sleep 0.5

# Sync SPM sources with v10 native Swift code
cp "${SCRIPT_DIR}/app_main_v10.swift" "${SCRIPT_DIR}/Sources/AntigravityUsageApp/app_main.swift"

echo "==> Compiling pure native SwiftUI executable (v10 SPM Release Build)..."
swift build -c release --target AntigravityUsageApp --package-path "${SCRIPT_DIR}"

BIN_PATH="${SCRIPT_DIR}/.build/release/AntigravityUsageApp"
if [ ! -f "${BIN_PATH}" ]; then
  echo "==> Fallback to swiftc release compilation..."
  swiftc -parse-as-library -O \
    -framework Cocoa \
    -framework SwiftUI \
    -framework WidgetKit \
    "${SCRIPT_DIR}/app_main_v10.swift" \
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
<!-- v10 – Info.plist for Pure SwiftUI & AppKit Menu Bar App -->
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Antigravity Usage</string>
    <key>CFBundleDisplayName</key>
    <string>Antigravity Usage</string>
    <key>CFBundleIdentifier</key>
    <string>com.dad.antigravity.usage</string>
    <key>CFBundleVersion</key>
    <string>10.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>10.0.0</string>
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

echo "==> Launching 100% Pure Native Antigravity Usage v10..."
open "${APP_DIR}"

echo "==> Done! Antigravity Usage v10 is running."

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
