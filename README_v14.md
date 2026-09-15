# Google Antigravity Usage Monitor
<!-- v14 – Production Native Swift/SwiftUI/AppKit/WidgetKit Suite, Dual App Targets (Antigravity & Grok), ✨ Sparkle Branding, Zero WebKit -->

<div align="center">

```
  █████  ███    ██ ████████ ██  ██████  ██████   █████  ██    ██ ██ ████████ ██    ██ 
 ██   ██ ████   ██    ██    ██ ██       ██   ██ ██   ██ ██    ██ ██    ██     ██  ██  
 ███████ ██ ██  ██    ██    ██ ██   ███ ██████  ███████ ██    ██ ██    ██      ████   
 ██   ██ ██  ██ ██    ██    ██ ██    ██ ██   ██ ██   ██  ██  ██  ██    ██       ██    
 ██   ██ ██   ████    ██    ██  ██████  ██   ██ ██   ██   ████   ██    ██       ██    
                                                                                      
                ⚡ PURE NATIVE MACOS MENU BAR & DESKTOP HUD ⚡
```

[![Platform](https://img.shields.io/badge/Platform-macOS%2014.0%2B-black?style=for-the-badge&logo=apple&logoColor=white)](https://apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![UI](https://img.shields.io/badge/UI-Pure%20SwiftUI%20%26%20AppKit-007AFF?style=for-the-badge&logo=swift&logoColor=white)](https://developer.apple.com/swiftui/)
[![Architecture](https://img.shields.io/badge/Architecture-100%25%20Native%20(Zero%20WebKit)-00C853?style=for-the-badge)](https://github.com/seanbuilds/antigravity-usage-monitor)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

<p align="center">
  <b>A lightweight, zero-configuration native macOS Menu Bar utility, detachable floating HUD, and WidgetKit extension to monitor real-time AI model quotas, rolling rate limits, and live countdown timers.</b>
</p>

</div>

---

> [!IMPORTANT]
> **LEGAL DISCLAIMER**: This software is an independent, open-source personal developer utility. It is **not** affiliated with, endorsed by, or connected to **Google LLC** or **xAI** in any way. All product names, trademarks, logos, and brands are property of their respective owners. Provided "as-is" under the terms of the [MIT License](LICENSE).

---

## 📑 Table of Contents

- [Visual Showcase & Interfaces](#-visual-showcase--interfaces)
- [Architecture & Shared Swift Package](#-architecture--shared-swift-package)
- [Dual Presentation Modes (Snap / Unsnap HUD)](#-dual-presentation-modes-snap--unsnap-hud)
- [Dual Rate-Limit Architecture (4-Limit Matrix)](#-dual-rate-limit-architecture-4-limit-matrix)
- [Live Countdown Engine & ISO-8601 Delta Math](#-live-countdown-engine--iso-8601-delta-math)
- [Keyboard Shortcuts](#-keyboard-shortcuts)
- [Quick Start & Build Pipeline](#-quick-start--build-pipeline)
- [Security & Credential Management](#-security--credential-management)
- [Repository Structure](#-repository-structure)
- [License](#-license)

---

## 🖥 Visual Showcase & Interfaces

```text
  ┌────────────────────────────────────────────────────────────────────────┐
  │  macOS Menu Bar (Top Right Status Item)                                │
  │  ...  [Wi-Fi]  [Battery]  [✨ G: 63% (4h 12m) · C: 56% (3h 45m)]       │
  └───────────────────────────────────┬────────────────────────────────────┘
                                      │ (Left-Click or ⌘U)
                                      ▼
  ┌────────────────────────────────────────────────────────────────────────┐
  │  ✨ Antigravity  [ULTRA]                               [⊞] [⚙] [↗] [↻] │
  │  account@example.com                                                   │
  ├────────────────────────────────────────────────────────────────────────┤
  │  Gemini Models (Flash & Pro)                                           │
  │  • 5-Hour Rolling Limit:     [████████████░░░░░░░]  63%                │
  │    [resets in 4h 12m]                                                  │
  │  • Weekly Plan Quota:        [██████████████████░]  92%                │
  │    [Ready]                                                             │
  │                                                                        │
  │  Claude & GPT Models (Opus, Sonnet, GPT-OSS)                           │
  │  • 5-Hour Rolling Limit:     [██████████░░░░░░░░░]  56%                │
  │    [resets in 3h 45m]                                                  │
  │  • Weekly Plan Quota:        [█████████████████░░]  90%                │
  │    [Ready]                                                             │
  ├────────────────────────────────────────────────────────────────────────┤
  │  Shared App Group Persistence · group.com.dad.aiusage        [Quit]    │
  └────────────────────────────────────────────────────────────────────────┘
```

---

## 🏛 Architecture & Shared Swift Package

The repository is organized into a clean multi-target Swift Package (`SharedQuotaSuite`):

- **`SharedQuotaKit`**: Shared library containing domain models, persistence (`group.com.dad.aiusage`), keychain security helpers, native AppKit window management, and SwiftUI components (`DashboardView`, `HUDPanel`, `MenuBarManager`).
- **`AntigravityUsageApp`**: Production macOS menu bar executable for Antigravity quotas.
- **`GrokUsageApp`**: Production macOS menu bar executable for xAI Grok quotas.
- **`AntigravityWidget` & `GrokWidget`**: Native macOS WidgetKit extension targets reading shared App Group snapshots.

```
                    ┌──────────────────────────────┐
                    │    SharedQuotaKit (Core)     │
                    │  • Models & Delta Math       │
                    │  • AppKit Windowing/HUD      │
                    │  • App Group Persistence     │
                    │  • Obsidian SwiftUI Views    │
                    └──────────────┬───────────────┘
                                   │
         ┌─────────────────────────┼─────────────────────────┐
         ▼                         ▼                         ▼
┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐
│ Antigravity App  │      │     Grok App     │      │ WidgetKit Target │
│ (Menu Bar + HUD) │      │ (Menu Bar + HUD) │      │ (macOS Desktop)  │
└──────────────────┘      └──────────────────┘      └──────────────────┘
```

---

## 🪟 Dual Presentation Modes (Snap / Unsnap HUD)

1. **Snapped Mode (NSPopover)**:
   - Clicking the menu bar item presents a native Obsidian-styled popover positioned directly below the icon on the active monitor.
2. **Unsnapped HUD Mode (NSPanel)**:
   - Clicking the detach button or pressing `⌘U` transforms the dashboard into a borderless, floating desktop HUD (`level = .floating`, movable by background).
   - Coordinates are actively clamped within `screen.visibleFrame` across multi-monitor setups.
3. **Snap-Back**:
   - Closing or re-clicking the snap button restores the menu bar popover cleanly without state loss.

---

## 📊 Dual Rate-Limit Architecture (4-Limit Matrix)

Antigravity models enforce dual rolling windows for first-party (Gemini) and third-party models:

| Model Family | 5-Hour Rolling Limit | Weekly Plan Quota |
| :--- | :--- | :--- |
| **Gemini Models** (Flash, Pro) | Burst pacing & smoothing | Subscription weekly ceiling |
| **Claude & GPT Models** (Sonnet, Opus) | Third-party burst pacing | Partner model weekly allocation |

---

## ⏱ Live Countdown Engine & ISO-8601 Delta Math

- Internal APIs return ISO-8601 target reset timestamps.
- The client engine parses timestamps directly and computes $\Delta t = \text{targetDate} - \text{now}$ client-side every second.
- Updates status bar titles smoothly (`✨ G: 63% (4h 12m) · C: 56% (3h 45m)`) without repeated network calls.

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action | Scope |
| :--- | :--- | :--- |
| `⌘ U` | Snap / Unsnap floating HUD | Global when focused |
| `⌘ R` | Force Quota Refresh | Dashboard |
| `⌘ Q` | Quit Application | Global |

---

## 🚀 Quick Start & Build Pipeline

### Prerequisites
- macOS 14.0 (Sonoma) or newer
- Xcode 15+ or Command Line Tools (`swift --version` >= 5.9)

### Build & Run
```bash
# 1. Run automated test suite
swift run TestRunner

# 2. Build release binaries, codesign with entitlements, and install into /Applications/
./build.sh
```

Both `Antigravity Usage.app` and `Grok Usage.app` will be compiled and launched into the macOS menu bar with `LSUIElement = true` (zero Dock clutter).

---

## 🔐 Security & Credential Management

- **Local Keychain**: Queries system credentials using standard macOS Security APIs (`SecItemCopyMatching`).
- **No External Servers**: Direct communication with local IDE endpoints and authoritative APIs; zero telemetry or third-party tracking.
- **App Group Sandboxing**: Uses `group.com.dad.aiusage` for local on-device IPC between the main app and widgets.

---

## 📂 Repository Structure

| Path | Purpose |
| :--- | :--- |
| [`Package.swift`](Package.swift) | SPM Multi-Target Manifest |
| [`Sources/SharedQuotaKit/`](Sources/SharedQuotaKit/) | Core models, windowing, and UI framework |
| [`Sources/AntigravityUsageApp/`](Sources/AntigravityUsageApp/) | Antigravity menu bar application |
| [`Sources/GrokUsageApp/`](Sources/GrokUsageApp/) | Grok menu bar application |
| [`Sources/AntigravityWidget/`](Sources/AntigravityWidget/) | Antigravity WidgetKit extension |
| [`Sources/GrokWidget/`](Sources/GrokWidget/) | Grok WidgetKit extension |
| [`Tests/TestRunner/`](Tests/TestRunner/) | Native test suite |
| [`build.sh`](build.sh) | Production build and packaging script |
| [`package.sh`](package.sh) | Release archiver |
| [`archive/`](archive/) | Historical prototypes and reference implementations |

---

## 📄 License

Open-source software licensed under the **[MIT License](LICENSE)**.
