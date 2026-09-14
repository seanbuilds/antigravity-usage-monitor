# Google Antigravity Usage & Quota Monitor (Ultra-Clean macOS Popover)
<!-- v5 – Ultra-clean Apple-native design with compact popover and no visual noise -->

A lightweight, zero-configuration utility, native macOS Menu Bar snap-out popover, and cross-device network daemon to view real-time Google Antigravity (`agy`) model quotas, consumption percentages, and reset timers across all your devices.

---

## 🌟 Ultra-Clean Menu Bar Snap-Out Popover

Designed with Apple-grade SF Pro typography, dark frosted glassmorphism, and zero visual clutter:

- **Menu Bar Status Item** (Top Right):
  - Displays a clean indicator (e.g. `✦ 89%`).
  - **Left-Click**: Instantly snaps out the clean 360px card directly below the icon.
  - **Click Anywhere Outside**: Automatically snaps closed.
  - **Right-Click**: Fast native context menu with model breakdowns and quick actions.
- **Dock Companion**:
  - Pinned right beside `Antigravity` in your Dock.
  - Clicking it snaps out the popover right from the menu bar.
- **Visual Design**:
  - **No Clutter**: Removed bulky banners, giant monospace terminal blocks, and redundant text.
  - **Clean Hierarchy**:
    - Header with app title, subtle `Ultra` badge, verified email, and minimal refresh icon.
    - Two clean cards: **Gemini Models** (Flash · Pro) and **Claude & GPT Models** (Opus · Sonnet · GPT-OSS).
    - Refined 5px rounded meter bars with color status (`green` $\ge$ 50%, `yellow` 20-50%, `red` < 20%).
    - Live countdown clocks (`4d 1h left`, `3h 53m left`).
    - Compact footer with a discreet **Copy Remote curl** pill button.
  - **Zero Scrollbars**: Content fits within a 360 x 415 px viewport.

To rebuild or re-pin at any time:
```bash
./build_app_v4.sh
```

---

## 1. Ground Truth & Accurate Tier Detection

Directly verified against Google Cloud Code's backend API (`loadCodeAssist`):

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

* Native Swift popover runner (v4): [`app_main_v4.swift`](file:///Users/dad/git/antigravity-usage-monitor/app_main_v4.swift)
* Build script: [`build_app_v4.sh`](file:///Users/dad/git/antigravity-usage-monitor/build_app_v4.sh)
* Popover user interface: [`index_v4.html`](file:///Users/dad/git/antigravity-usage-monitor/index_v4.html)
* Standalone Python script (v2): [`antigravity_usage_v2.py`](file:///Users/dad/git/antigravity-usage-monitor/antigravity_usage_v2.py)
* Terminal alias: [`antigravity-usage`](file:///Users/dad/.local/bin/antigravity-usage)
* Installed Application: [`/Applications/Antigravity Usage.app`](file:///Applications/Antigravity%20Usage.app)
* LaunchAgent configuration: [`com.antigravity.usage_v2.plist`](file:///Users/dad/Library/LaunchAgents/com.antigravity.usage_v2.plist)
