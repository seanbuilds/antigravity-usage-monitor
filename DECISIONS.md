# Architectural Decisions (DECISIONS.md)

## ADR-001: Unified Native Swift Architecture
- **Context**: Prior iterations utilized Python daemons, WKWebView, HTML/CSS assets, and shell scripts.
- **Decision**: All production code is implemented strictly in pure Swift, SwiftUI, AppKit, and WidgetKit via a single root Swift Package Manager layout (`SharedQuotaSuite`). Zero external runtime daemons or web wrappers.
- **Consequence**: Ultra-low memory/CPU usage, instantaneous responsiveness, and native macOS windowing capabilities.

## ADR-002: Dual Presentation (NSPopover + HUDPanel)
- **Context**: Users need quick glanceability from the menu bar as well as persistent floating desktop widgets while deep in focus mode.
- **Decision**: The menu bar status item presents a transient `NSPopover` by default. A dedicated detach button transitions the view seamlessly into a borderless floating `NSPanel` (`level = .floating`, movable by background, bounds-clamped to `screen.visibleFrame`). Re-clicking or closing snaps back to popover mode.

## ADR-003: App Group Snapshot Persistence for WidgetKit
- **Context**: Standalone macOS WidgetKit extensions run out-of-process and cannot query interactive Keychain prompts or local state directly.
- **Decision**: Main application targets (`AntigravityUsageApp`, `GrokUsageApp`) periodically write unified JSON snapshots to App Group suite `group.com.dad.aiusage`. Widgets read from this cache to ensure instant, zero-latency widget timeline rendering.

## ADR-004: Client-Side Delta Timers for Dynamic Menu Bar Titles
- **Context**: Server APIs return ISO-8601 target timestamps that can drift if not refreshed continuously.
- **Decision**: Countdown math computes $\Delta t = \text{targetDate} - \text{now}$ client-side every second, updating status titles (e.g. `✦ G: 51% (4m) · C: 57% (15m)`) smoothly without spamming backend network requests.

## ADR-005: Independent Trademark-Safe Visual Identity
- **Context**: Public distribution via Mac App Store, Homebrew, or GitHub requires strict adherence to trademark guidelines and Apple Review Guideline 4.1 (avoiding intellectual property infringement or false brand affiliation).
- **Decision**: Reject proprietary logos. Adopt safe, minimalist geometric glyphs:
  - **Grok**: Slashed circle motif (`⊘`) in monochrome titanium/obsidian palette (`#E5E5E7`).
  - **Antigravity**: Celestial orbit sparkle (`✦`) in electric blue palette (`#3B82F6`).
- **Consequence**: Full compliance with App Store review guidelines and trademark protections while preserving high-contrast, Apple-grade aesthetics.
