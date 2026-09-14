# Google Antigravity Usage Monitor (SPM, WidgetKit & App Group Sync)
<!-- v7 – Added Swift Package Manager architecture, WidgetKit extension, and code review fixes -->

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

### 2. Menu Bar Snap-Out Popover
- **Menu Bar Status Item** (Top Right):
  - Displays primary model capacity (e.g. `✦ 82%`).
  - **Left-Click**: Instantly snaps out the clean 360px card directly below the menu bar icon.
  - **Click Anywhere Outside**: Automatically snaps closed.
  - **Right-Click**: Fast native context menu with model breakdowns and quick actions.
  - **Error Awareness**: Displays `✦ err` or `✦ offline` with explanatory tooltips on network or decode failures.
- **Dock Companion**:
  - Pinned beside `Antigravity` in your Dock.
  - Clicking the Dock icon snaps out the popover right from the menu bar.

### 3. Unsnap to Floating Window (Detachable HUD)
- **Drag to Detach**: Drag the popover card away from the menu bar to tear it off into an independent floating window.
- **Unsnap Button**: Click the pop-out icon (`↗`) in the top right header (or press `⌘U`).
- **Floating HUD**: Operates at `.floating` level with a subtle translucent dark Aqua card, remaining visible while interacting with code.
- **Snap Back**: Click the dock icon (`↙`) in the header (or press `⌘U` or close the window) to cleanly snap it back into the menu bar.

### 4. macOS Desktop Widget Mode
- **Compact Desktop Widget**: An Apple-grade 240×124px translucent frosted glass card (`backdrop-filter: blur(28px)`) that sits directly above desktop wallpaper (`desktopIconWindow + 1`) and below normal application windows.
- **Position Persistence**: Automatically remembers and restores the exact position where you last placed it on the desktop.
- **One-Click Activation**: Click the **Widget** button in the popover header or right-click the menu bar icon and select **Add Desktop Widget** (`⌘W`).
- **Live Mini Gauges**: Glanceable mini capacity bars for **Gemini Models** (5h window) and **Claude & GPT Models** (5h window).
- **Interactive Control**: Draggable across the desktop, equipped with a subtle hover close button (`×`), and double-clickable to open the full popover.

---

## 💻 Terminal Commands & Build Scripts

### Build via Swift Package Manager
```bash
# Compile and install application bundle with App Group entitlements:
./build_app_v6.sh
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
* Native Swift runner (v6): [`app_main_v6.swift`](file:///Users/dad/git/antigravity-usage-monitor/app_main_v6.swift)
* Build & packaging script (v6): [`build_app_v6.sh`](file:///Users/dad/git/antigravity-usage-monitor/build_app_v6.sh)
* Popover user interface (v6): [`index_v6.html`](file:///Users/dad/git/antigravity-usage-monitor/index_v6.html)
* Desktop Widget UI (v6): [`widget_v6.html`](file:///Users/dad/git/antigravity-usage-monitor/widget_v6.html)
* Shared Data Models: [`SharedModels/SharedQuota.swift`](file:///Users/dad/git/antigravity-usage-monitor/SharedModels/SharedQuota.swift)
* WidgetKit Extension: [`AntigravityWidget/AntigravityWidget.swift`](file:///Users/dad/git/antigravity-usage-monitor/AntigravityWidget/AntigravityWidget.swift)
* Standalone Python script (v3): [`antigravity_usage_v3.py`](file:///Users/dad/git/antigravity-usage-monitor/antigravity_usage_v3.py)
* Terminal alias: [`antigravity-usage`](file:///Users/dad/.local/bin/antigravity-usage)
* Installed Application: [`/Applications/Antigravity Usage.app`](file:///Applications/Antigravity%20Usage.app)
* LaunchAgent configuration: [`com.antigravity.usage_v3.plist`](file:///Users/dad/Library/LaunchAgents/com.antigravity.usage_v3.plist)
