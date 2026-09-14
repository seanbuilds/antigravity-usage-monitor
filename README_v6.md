# Google Antigravity Usage & Quota Monitor (Unsnap & Desktop Widget)
<!-- v6 – Added Unsnap floating window mode, macOS Desktop Widget mode, and hardened daemon v3 -->

A lightweight, zero-configuration utility, native macOS Menu Bar snap-out popover, detachable floating window, and cross-device network daemon to view real-time Google Antigravity (`agy`) model quotas, consumption percentages, and reset timers across all your devices.

---

## 🌟 Key Features

### 1. Menu Bar Snap-Out Popover
- **Menu Bar Status Item** (Top Right):
  - Displays live quota percentage (e.g. `✦ 84%`).
  - **Left-Click**: Instantly snaps out the clean 360px card directly below the menu bar icon.
  - **Click Anywhere Outside**: Automatically snaps closed.
  - **Right-Click**: Fast native context menu with model breakdowns and quick actions.
- **Dock Companion**:
  - Pinned right beside `Antigravity` in your Dock.
  - Clicking the Dock icon snaps out the popover right from the menu bar.

### 2. Unsnap to Floating Window (Detachable)
- **Drag to Detach**: Simply drag the popover away from the menu bar to unsnap it into an independent floating window!
- **Unsnap Button**: Click the pop-out icon (`↗`) in the top right header (or press `⌘U`).
- **Floating HUD**: Stays open and floats on top while you code in Antigravity or other full-screen apps.
- **Snap Back**: Click the dock icon (`↙`) in the header (or press `⌘U` or close the window) to cleanly snap it back into the menu bar.

### 3. macOS Desktop Widget Mode
- **Compact Glancable Widget**: 240×124px translucent frosted glass card designed for your desktop.
- **Toggle Anytime**:
  - Click the **Widget** button in the popover header.
  - Or right-click the menu bar icon and select **Add Desktop Widget** (`⌘W`).
- **Live Mini Meters**: Tracks Gemini (5h) and Claude/GPT quota windows with live percentage bars.
- **Interactive**: Drag it anywhere on your desktop; double-click the widget body to open the full dashboard.

---

## 💻 Terminal Commands

The CLI executable is symlinked to `~/.local/bin/antigravity-usage`.

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

From **any terminal on any device** (secondary laptop, Linux server, Raspberry Pi, iPhone via iSH, Android via Termux):
```bash
# Display the full colored terminal dashboard directly:
curl -s http://192.168.5.67:3007

# Or retrieve JSON for status bars or custom scripts:
curl -s http://192.168.5.67:3007/quota
```

---

## 🛠 Architecture & Source Files

All source code is maintained in your GitHub repository: **[github.com/seanbuilds/antigravity-usage-monitor](https://github.com/seanbuilds/antigravity-usage-monitor)**

* Native Swift runner (v5): [`app_main_v5.swift`](file:///Users/dad/git/antigravity-usage-monitor/app_main_v5.swift)
* Build & packaging script (v5): [`build_app_v5.sh`](file:///Users/dad/git/antigravity-usage-monitor/build_app_v5.sh)
* Popover user interface (v5): [`index_v5.html`](file:///Users/dad/git/antigravity-usage-monitor/index_v5.html)
* Desktop Widget UI (v5): [`widget_v5.html`](file:///Users/dad/git/antigravity-usage-monitor/widget_v5.html)
* Standalone Python script (v3): [`antigravity_usage_v3.py`](file:///Users/dad/git/antigravity-usage-monitor/antigravity_usage_v3.py)
* Terminal alias: [`antigravity-usage`](file:///Users/dad/.local/bin/antigravity-usage)
* Installed Application: [`/Applications/Antigravity Usage.app`](file:///Applications/Antigravity%20Usage.app)
* LaunchAgent configuration: [`com.antigravity.usage_v3.plist`](file:///Users/dad/Library/LaunchAgents/com.antigravity.usage_v3.plist)
