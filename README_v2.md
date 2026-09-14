# Google Antigravity Usage & Quota Monitor (Native macOS App & Cross-Device CLI)
<!-- v2 – Added native macOS Dock Application and one-click desktop UI -->

A lightweight utility, native macOS desktop application, and cross-device network daemon to view real-time Google Antigravity (`agy`) model quotas, consumption percentages, and reset timers across all your devices.

---

## 🌟 Quick Start: macOS Dock App ("Click and Tada")

An ad-hoc signed, native Cocoa/WebKit macOS desktop application has been built and pinned directly to your **Dock**:

- **Location**: `/Applications/Antigravity Usage.app`
- **In your Dock**: Located right beside `Antigravity`.
- **Action**: Just click the icon in your Dock! It instantly displays:
  - Real-time remaining quota percentages for **Gemini** (Flash, Pro) and **Claude & GPT** (Opus, Sonnet, GPT-OSS).
  - Live ticking countdown clocks showing exactly when your 5-hour rolling limit and weekly subscription caps refresh.
  - User account pill & active plan status.
  - Cross-device `curl` command box with a 1-click **Copy** button.
  - Instant manual refresh button + background auto-refresh every 30 seconds.

To rebuild or re-pin the application at any time:
```bash
./build_app_v1.sh
```

---

## 1. Top Recommended GitHub Repositories

If you are looking for community open-source repositories designed specifically for this purpose:

1. **[`abruption/agy-cli-usage`](https://github.com/abruption/agy-cli-usage)** (Primary Recommendation for CLI users)
   - **Target**: Built specifically for terminal users of the Antigravity CLI (`agy`).
   - **How it works**: Direct headless querying of Cloud Code internal quota endpoints via OS Keyring (`security` on macOS, Secret Service on Linux, Credential Manager on Windows) with an automated pseudo-terminal (PTY) fallback.
   - **Features**: ANSI color progress bars, 5-hour rolling limit and weekly limit countdowns, `--json` machine-readable output, `--watch` auto-refresh mode, and a built-in HTTP server daemon (`PORT=3007 agy-cli-usage serve`).
   - **Quick Run**: `npx -y agy-cli-usage` or `npm install -g agy-cli-usage`.

2. **[`skainguyen1412/antigravity-usage`](https://github.com/skainguyen1412/antigravity-usage)**
   - **Target**: Antigravity IDE and multi-account cloud tracking.
   - **Features**: Dual-fetch architecture (local Language Server priority + Google Cloud Code fallback), multi-account side-by-side comparison (`--all`), headless manual authentication (`login --manual`), and automated wakeup cron jobs.
   - **Quick Run**: `npm install -g antigravity-usage`.

3. **[`FeikoWielsma/dms-antigravity-cli`](https://github.com/FeikoWielsma/dms-antigravity-cli)**
   - **Target**: Linux / Wayland desktop users running Dank Material Shell (DMS) wishing to dock quota indicators directly into their taskbar.

---

## 2. Included Standalone Tool (`antigravity_usage_v1.py`)

This repository provides a self-contained, standalone Python 3 script with **zero external dependencies** that works out-of-the-box on your machine and across your network.

### Features
- **Local Credential Extraction**: Automatically extracts and refreshes Google OAuth tokens directly from macOS Keychain (`gemini:antigravity`), Linux Secret Service, Windows Credential Manager, or fallback token files.
- **Cross-Device HTTP Server Mode**: Run on your main machine or server. Any secondary laptop, Linux server, Raspberry Pi, or phone (Termux/iSH) on your network or Tailscale mesh can check your quota with a single `curl` command.
- **Terminal Visuals**: Renders color-coded progress bars, remaining percentages, and countdown clocks for both 5-hour rolling limits and weekly caps.
- **Watch Mode**: Real-time refreshing dashboard with countdown timers.
- **JSON Mode**: Clean machine-readable JSON for tmux status bars, Starship prompt modules, or shell scripts.

---

## 3. Terminal Commands

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

#### Method A: Query the Background Server Daemon
The background daemon runs 24/7 via macOS LaunchAgent on port 3007.

From **any terminal on any device** (other laptops, iPad/iPhone with iSH/Termius, Android with Termux, home server, Raspberry Pi):
```bash
# Display the full colored terminal dashboard directly:
curl -s http://192.168.4.98:3007

# Or retrieve JSON for status bars or scripts:
curl -s http://192.168.4.98:3007/quota
```

#### Method B: Remote CLI Client Mode
If Python is installed on your secondary device:
```bash
python3 antigravity_usage_v1.py --remote http://192.168.4.98:3007
```
