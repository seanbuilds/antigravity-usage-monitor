# Google Antigravity Usage Monitor (Pure SwiftUI & AppKit Architecture)
<!-- v8 – 100% Pure Native SwiftUI & AppKit Architecture (Zero WebKit/HTML Wrappers), Dynamic Sizing, Instant Quit & Sibling Parity -->

> **LEGAL DISCLAIMER**
> This software is an independent personal project. It is **not** affiliated with, endorsed by,
> or connected to **Google LLC** in any way. All trademarks belong to their respective owners.
> Provided "as-is" with **no warranty**. For personal use only.

A lightweight, zero-configuration utility, 100% pure native macOS Menu Bar snap-out popover, detachable floating HUD window, desktop widget, and cross-device network daemon to view real-time Google Antigravity (`agy`) model quotas, consumption percentages, and reset timers across all your devices.

---

## 🌟 100% Pure Native macOS Architecture (v8)

The application has been completely rebuilt using **pure native Swift, SwiftUI, AppKit, and WidgetKit** — entirely replacing all WebKit, HTML, CSS, and JavaScript wrappers:

### 1. Pure SwiftUI & AppKit Foundations
- **Zero WebKit Wrappers**: Native Apple Cocoa controls, native frosted glass materials (`.popover` visual effect blending), and native SF Symbols.
- **Ultra-Low Resource Footprint**: Runs at just ~89 MB RAM with zero auxiliary WebKit helper processes.
- **Instant Response & Animations**: Native SwiftUI `Capsule` gauges with fluid spring animations (`.spring(response: 0.35, dampingFraction: 0.85)`).
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
  - `↻ Refresh`: Instant cache-bypassing live quota reload (`⌘R`) with rotating animation.
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
- **Compact Desktop Widget**: An Apple-grade 240×124px translucent frosted glass card (`NSVisualEffectView`) that sits directly above desktop wallpaper (`desktopIconWindow + 1`) and below normal application windows.
- **Position Persistence**: Automatically remembers and restores the exact position where you last placed it on the desktop.
- **Live Mini Gauges**: Glanceable mini capacity bars for **Gemini Models** (5h window) and **Claude & GPT Models** (5h window).
- **Interactive Control**: Draggable across the desktop, equipped with a subtle hover close button (`×`), double-clickable to open the full popover, and equipped with a discrete legal disclaimer.

---

## 💻 Terminal Commands & Build Scripts

### Build via Swift Package Manager
```bash
# Compile and install application bundle with App Group entitlements:
./build_app_v8.sh
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
* Native Swift App (v8): [`app_main_v8.swift`](file:///Users/dad/git/antigravity-usage-monitor/app_main_v8.swift)
* Build & packaging script (v8): [`build_app_v8.sh`](file:///Users/dad/git/antigravity-usage-monitor/build_app_v8.sh)
* Shared Data Models: [`SharedModels/SharedQuota.swift`](file:///Users/dad/git/antigravity-usage-monitor/SharedModels/SharedQuota.swift)
* WidgetKit Extension: [`AntigravityWidget/AntigravityWidget.swift`](file:///Users/dad/git/antigravity-usage-monitor/AntigravityWidget/AntigravityWidget.swift)
* Standalone Python daemon (v4): [`antigravity_usage_v4.py`](file:///Users/dad/git/antigravity-usage-monitor/antigravity_usage_v4.py)
* Terminal alias: [`antigravity-usage`](file:///Users/dad/.local/bin/antigravity-usage)
* Installed Application: [`/Applications/Antigravity Usage.app`](file:///Applications/Antigravity%20Usage.app)
* LaunchAgent configuration: [`com.antigravity.usage_v4.plist`](file:///Users/dad/Library/LaunchAgents/com.antigravity.usage_v4.plist)
