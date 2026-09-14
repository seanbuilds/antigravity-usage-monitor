# Google Antigravity Usage Monitor
<!-- v11 – Comprehensive Native Architecture, Dual Quota Indicator (✦ G: 63% · C: 56%), 4-Rate-Limit Matrix, Development Log & MIT License -->

> **LEGAL DISCLAIMER**  
> This software is an independent personal project. It is **not** affiliated with, endorsed by,
> or connected to **Google LLC** in any way. All product names, logos, and brands are property of their respective owners.
> Provided "as-is" under the terms of the [MIT License](LICENSE). For personal monitoring only.

[![Platform](https://img.shields.io/badge/Platform-macOS%2014.0%2B-blue.svg)](https://apple.com)
[![Language](https://img.shields.io/badge/Language-Swift%205.9%20%7C%20Python%203-orange.svg)](https://swift.org)
[![Framework](https://img.shields.io/badge/UI-Pure%20SwiftUI%20%26%20AppKit-indigo.svg)](https://developer.apple.com/swiftui/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A high-performance, zero-configuration macOS Menu Bar utility, detachable floating HUD window, desktop ambient widget, terminal CLI, and cross-device local network daemon to monitor real-time Google Antigravity (`agy`) model consumption, rolling rate limits, tier capacities, and reset countdowns across all your devices.

---

## 🌟 Native Architecture Highlights

Built using **100% pure native Swift, SwiftUI, AppKit, and WidgetKit** with zero WebKit, HTML, or JavaScript dependencies:

### 1. Dual Status Indicator (Option A)
* **Simultaneous Tracking**: Displays both active 5-hour rolling capacity limits in the macOS menu bar at a glance:
  $$\mathbf{✦\ G:\ 63\%\ \cdot\ C:\ 56\%}$$
* **Gemini Models (`G`)**: Live 5-hour rolling smoothing limit.
* **Claude & GPT Models (`C`)**: Live 5-hour rolling smoothing limit for third-party models.
* **Instant Transparency**: Eliminates single-number ambiguity where a collapsed percentage masked independent model limits.

### 2. Complete 4-Rate-Limit Matrix
Exposes the four underlying rate-limiting buckets returned by Google's `retrieveUserQuotaSummary` endpoint:
1. **Gemini 5-Hour Rolling Limit** (`gemini-5h`): Short-term smoothing capacity.
2. **Gemini Weekly Tier Limit** (`gemini-weekly`): Overall weekly capacity tier.
3. **Claude/GPT 5-Hour Rolling Limit** (`3p-5h`): Third-party model smoothing capacity.
4. **Claude/GPT Weekly Tier Limit** (`3p-weekly`): Overall weekly third-party capacity tier.

### 3. Native Hover Tooltip & Right-Click Context Menu
* **Hover Tooltip**: Hovering over the menu bar status item provides an immediate overview of all 4 limits with remaining percentages and countdown timers:
  ```text
  Antigravity Quotas (Google AI Ultra):
  • Gemini 5-Hour: 63% (Ready)
  • Gemini Weekly: 92% (Ready)
  • Claude/GPT 5-Hour: 56% (Ready)
  • Claude/GPT Weekly: 90% (Ready)
  (Click to open dashboard)
  ```
* **Context Menu**: Right-clicking the menu bar icon reveals a full macOS context menu detailing all 4 limits alongside direct actions (`Refresh Now`, `Add Desktop Widget`, `Unsnap to Window`, `Copy curl Command`, `Quit`).

### 4. Obsidian Design System (Sibling Parity with Grok)
* **Visual Parity**: Crafted to match the exact aesthetic language of the Grok Usage Monitor.
* **Obsidian Palette**: Deep charcoal container (`rgba(13, 16, 23, 0.97)`), continuous 14pt corner curvature, and subtle electric blue outline (`#3B82F6` at $0.22$ opacity).
* **Deterministic 360° Refresh Animation**: Manual refresh (`⌘R`) performs a single, fluid 360-degree ease-in-out rotation (`withAnimation(.easeInOut(duration: 0.6))`). Background 30-second polling updates silently without spinning the icon.
* **Ultra-Low Memory Footprint**: Idles at ~89 MB RAM (a 70% reduction compared to WebKit hybrid architectures).

### 5. Detachable Floating HUD Window
* **Unsnap to Window**: Tear off the popover into an independent floating HUD window (`⌘U` or the `↗` button in the toolbar).
* **Multi-Space Support**: Remains visible across macOS Spaces while interacting with code and terminal windows.
* **Snap Back**: Snap cleanly back into the menu bar at any time (`⌘U` or the `↙` button).

### 6. Ambient Desktop Widget
* **Glanceable Glass Card**: A compact 240×124pt translucent card that hovers directly above the desktop wallpaper (`desktopIconWindow + 1`).
* **4-Bar Progress Matrix**: Displays individual mini progress bars for Gemini 5h, Gemini Weekly, Claude 5h, and Claude Weekly.
* **Position Persistence**: Remembers its exact desktop coordinates across restarts.
* **Interactive Control**: Draggable, hover close button (`×`), and double-clickable to open the full popover.

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action | Scope |
| :--- | :--- | :--- |
| **`⌘R`** | Trigger immediate bypass-cache quota refresh | Popover & Floating Window |
| **`⌘U`** | Toggle between Menu Bar Popover and Floating HUD | Global / Application |
| **`⌘,`** | Toggle Setup & Diagnostics view | Popover & Floating Window |
| **`⌘W`** | Close Popover or Floating HUD | Active Window |
| **`⌘Q`** | Terminate Antigravity Usage completely | Global / Application |

---

## 💻 Terminal CLI & Cross-Device Usage

### Terminal Command
```bash
# View formatted color terminal quota dashboard:
antigravity-usage

# Live auto-refreshing watch mode (updates every 30 seconds):
antigravity-usage --watch 30

# Machine-readable JSON output:
antigravity-usage --json
```

### Cross-Device LAN Inspection
The background daemon runs 24/7 on port `3007` via macOS LaunchAgent (`com.antigravity.usage_v4.plist`).  
From any device on your local network or VPN:
```bash
# Color ANSI dashboard:
curl -s http://192.168.5.67:3007

# Machine-readable JSON:
curl -s http://192.168.5.67:3007/quota

# Health check:
curl -s http://192.168.5.67:3007/health
```

---

## 🛠 Build & Installation

### Prerequisites
* macOS 14.0 (Sonoma) or newer
* Xcode Command Line Tools (`xcode-select --install`)
* Python 3.9+ (bundled with macOS)

### Build & Package via Swift Package Manager
```bash
# Clone the repository:
git clone https://github.com/seanbuilds/antigravity-usage-monitor.git
cd antigravity-usage-monitor

# Compile, sign with entitlements, and install into /Applications:
./build_app_v11.sh
```

---

## 📖 Comprehensive Documentation & Engineering History

* **Step-by-Step Engineering Log**: Consult [`DEVELOPMENT_NOTES_v1.md`](DEVELOPMENT_NOTES_v1.md) for detailed records covering reverse engineering, keychain extraction, ground truth verification, double-blur artifact fixes, and rate limit investigations.
* **Unified Single-File Codebase**: View [`CODEBASE_ALL_v6.md`](CODEBASE_ALL_v6.md) for a single consolidated markdown dump of all current active source code.

---

## 📂 Active Repository Files

* **Swift Package Manifest**: [`Package.swift`](Package.swift)
* **App Group Entitlements**: [`antigravity.entitlements`](antigravity.entitlements)
* **Pure Native Swift Application (v11)**: [`app_main_v11.swift`](app_main_v11.swift)
* **Build & Packaging Script (v11)**: [`build_app_v11.sh`](build_app_v11.sh)
* **Shared Data Models**: [`SharedModels/SharedQuota.swift`](SharedModels/SharedQuota.swift)
* **WidgetKit Extension**: [`AntigravityWidget/AntigravityWidget.swift`](AntigravityWidget/AntigravityWidget.swift)
* **Hardened Python Daemon (v4)**: [`antigravity_usage_v4.py`](antigravity_usage_v4.py)
* **LaunchAgent Configuration (v4)**: [`/Users/dad/Library/LaunchAgents/com.antigravity.usage_v4.plist`](file:///Users/dad/Library/LaunchAgents/com.antigravity.usage_v4.plist)
* **Step-by-Step Development Notes (v1)**: [`DEVELOPMENT_NOTES_v1.md`](DEVELOPMENT_NOTES_v1.md)
* **MIT License**: [`LICENSE_v1`](LICENSE_v1) (symlinked to [`LICENSE`](LICENSE))

---

## 📄 License

This project is open-source software licensed under the **[MIT License](LICENSE)**.
See the [`LICENSE_v1`](LICENSE_v1) file for complete details.
