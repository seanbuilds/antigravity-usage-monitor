# Google Antigravity Usage & Quota Monitor (Menu Bar Snap-Out Popover)
<!-- v4 – Added Menu Bar Snap-Out Popover architecture with auto-dismiss -->

A lightweight, zero-configuration utility, native macOS Menu Bar popover application, and cross-device network daemon to view real-time Google Antigravity (`agy`) model quotas, consumption percentages, and reset timers across all your devices.

---

## 🌟 Menu Bar Snap-Out Popover ("Click & It Snaps Out")

The application now primarily acts as a **native macOS Menu Bar Popover**:

- **Menu Bar Status Item** (Top Right):
  - Displays a live indicator (e.g. `✦ 89%`) with verified Google AI Ultra quota.
  - **Left-Click**: Snaps out a dark-mode dashboard directly anchored to your menu bar icon with a native macOS arrow.
  - **Click Anywhere Outside**: Automatically snaps closed (transient popover behavior).
  - **Right-Click**: Opens a quick context menu with per-model quota numbers, manual refresh, and a 1-click option to copy the remote `curl` command.
- **Dock Companion**:
  - Pinned directly next to `Antigravity` in your Dock.
  - Clicking the Dock icon snaps out the popover right from the menu bar.
- **Auto-Updating**:
  - Live auto-refresh every 30 seconds.
  - Live countdown timers ticking down to your 5-hour rolling limit and weekly cap resets.

To rebuild or re-pin the application at any time:
```bash
./build_app_v3.sh
```

---

## 1. Ground Truth & Accurate Tier Detection

Unlike generic community tools that blindly fall back to `currentTier.id: "free-tier"`, this tool inspects the root `paidTier` object returned by Google's Cloud Code API (`v1internal:loadCodeAssist`):

* **Tier**: `✦ Google AI Ultra` (`g1-ultra-tier` / $200 plan)
* **Status**: *"You are subscribed to the best Google AI plan."*
* **Models**: Full access to Gemini Models (Flash, Pro) and Third-Party Models (Claude Opus, Claude Sonnet, GPT-OSS).
* **Identity**: Cryptographically extracted from the signed Google OIDC `id_token` in your macOS Keychain.

---

## 2. Terminal Commands

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
curl -s http://192.168.4.98:3007

# Or retrieve JSON for status bars or scripts:
curl -s http://192.168.4.98:3007/quota
```

---

## 3. Architecture & Source Files

All source code is maintained in your GitHub repository: **[github.com/seanbuilds/antigravity-usage-monitor](https://github.com/seanbuilds/antigravity-usage-monitor)**

* Native Swift popover runner (v3): [`app_main_v3.swift`](file:///Users/dad/git/antigravity-usage-monitor/app_main_v3.swift)
* Build script: [`build_app_v3.sh`](file:///Users/dad/git/antigravity-usage-monitor/build_app_v3.sh)
* Popover user interface: [`index_v3.html`](file:///Users/dad/git/antigravity-usage-monitor/index_v3.html)
* Standalone Python script (v2): [`antigravity_usage_v2.py`](file:///Users/dad/git/antigravity-usage-monitor/antigravity_usage_v2.py)
* Terminal alias: [`antigravity-usage`](file:///Users/dad/.local/bin/antigravity-usage)
* Installed Application: [`/Applications/Antigravity Usage.app`](file:///Applications/Antigravity%20Usage.app)
* LaunchAgent configuration: [`com.antigravity.usage_v2.plist`](file:///Users/dad/Library/LaunchAgents/com.antigravity.usage_v2.plist)
