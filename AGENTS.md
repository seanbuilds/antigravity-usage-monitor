# AGENTS.md — Authoritative Architecture & Requirements

## 1. System Vision & Purpose
A high-performance, pure native macOS menu bar application suite for tracking AI quotas, rate limits, and reset countdowns in real-time. The suite powers both:
1. **Antigravity Quota Tracker**: Google Cloud Code & Antigravity quotas (Gemini Flash/Pro, Claude/GPT-OSS).
2. **Grok Quota Tracker**: xAI Grok quotas (fast tier, thinking tier, image tier).

Both apps share identical architecture, user ergonomics, window management, and widget integration via a unified Swift Package.

## 2. Mandatory Architectural Invariants
1. **100% Pure Native macOS**:
   - Written exclusively in Swift, SwiftUI, AppKit, and WidgetKit.
   - Zero Python, zero HTML, zero WebKit, zero WebView, zero Electron/Tauri dependencies.
   - Zero external runtime daemons required for standard operation.
2. **Headless / Menu Bar Operation**:
   - `LSUIElement = YES` (app operates as an accessory in the macOS menu bar; no persistent Dock icon).
   - High-contrast, dynamic menu bar title with live countdown timers: `✦ G: XX% (Xm) · C: YY% (Ym)`.
3. **Dual Presentation Modes (Snap / Unsnap)**:
   - **Snapped Mode**: Native `NSStatusItem` hosting an `NSPopover` (`.transient`) positioned directly below the status item on any connected display.
   - **Unsnapped HUD Mode**: Native borderless floating `NSPanel` (`level = .floating`, movable by background) positioned accurately within `screen.visibleFrame`.
   - **Seamless Snap-Back**: Closing or clicking the snap button restores popover mode without state loss.
4. **Data Acquisition & Security**:
   - **Antigravity**: Extracts OAuth / session credentials from macOS Keychain (service: `gemini`, account: `antigravity`) or local IDE endpoint; queries Cloud Code `retrieveUserQuotaSummary`.
   - **Grok**: Reads local CLI debug-logs or Keychain credentials (`xai` / `grok`); queries usage endpoint.
   - Never expose API keys or credentials in source, logs, or chat output.
5. **App Group Persistence & WidgetKit**:
   - Shared App Group suite (`group.com.dad.aiusage`) synchronizes snapshots between the main app and `WidgetKit` extension.
   - Native `WidgetKit` extension provides `.systemSmall` and `.systemMedium` widgets with periodic timeline refreshes.
6. **Project Structure & Clean Production Layout**:
   - Swift Package Manager (`Package.swift`) only. No CocoaPods.
   - Shared library target `SharedQuotaKit` (common UI, models, protocols, AppKit windowing, HUD, Widget views).
   - Executable target `AntigravityUsageApp`.
   - Executable target `GrokUsageApp`.
   - Widget targets `AntigravityWidget` and `GrokWidget`.
   - Stable production filenames without parallel `_vN` prototype branches in production sources.
7. **API Delta Computation & Timestamp Invariants**:
   - When consuming internal, loopback, or third-party APIs returning reset, expiration, or deadline timestamps (ISO-8601), NEVER assume integer duration or delta fields (`resetsInSeconds`, `expires_in`) exist unless verified in the schema.
   - Always parse the ISO-8601 timestamp directly and compute $\Delta t = \text{targetDate} - \text{now}$ client-side to ensure resilient live countdowns.
8. **Multi-Monitor Window Anchoring Invariants**:
   - When positioning `NSPopover` or borderless floating `NSPanel` from an `NSStatusItem`, always obtain the active screen via `statusItem.button?.window?.screen ?? NSScreen.main`.
   - Always clamp the window rect within `screen.visibleFrame` to prevent off-screen placement when secondary displays use offset or negative coordinate spaces.
