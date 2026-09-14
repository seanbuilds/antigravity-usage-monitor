# Implementation Plan: Pure Native Shared Swift Architecture

## Step 1: Shared Swift Package & Core Domain Models
- Define `SharedQuotaKit` in `Sources/SharedQuotaKit`:
  - `QuotaModels.swift`: Universal quota snapshots, rate limits, tier badges, countdown timers, brand configurations (`BrandTheme`, `AppBrand`).
  - `DataProviderProtocol.swift`: `QuotaDataProvider` protocol returning typed snapshot and breakdown.
  - `KeychainHelper.swift`: Safe extraction of credentials from macOS Keychain (`SecItemCopyMatching`).
  - `AppGroupPersistence.swift`: Read/write snapshot cache using `UserDefaults(suiteName: "group.com.dad.aiusage")`.

## Step 2: Shared UI & Window Management Vertical Slice
- In `Sources/SharedQuotaKit/UI`:
  - `DashboardView.swift`: Obsidian styled UI, live countdown badges, dual rate-limit cards, progress bars, refresh trigger, unsnap/snap toggle.
  - `HUDPanel.swift`: Borderless floating `NSPanel` (`level = .floating`, movable by background, clamped to active `screen.visibleFrame`).
  - `MenuBarManager.swift`: Native `NSStatusItem`, dynamic status title with timers, `NSPopover` management, and seamless snap/unsnap transition.

## Step 3: Branded App Targets
- `Sources/AntigravityUsageApp/main.swift`:
  - Antigravity brand theme (Electric Blue / Gold Ultra pill, ✦ icon).
  - Antigravity data provider: Reads Cloud Code quota via local loopback / Keychain OAuth tokens.
- `Sources/GrokUsageApp/main.swift`:
  - Grok brand theme (Crimson/Monochrome Obsidian, SuperGrok pill, 𝕏/Grok mark).
  - Grok data provider: Reads Grok rate limits via local debug-log or xAI Keychain token.

## Step 4: Native WidgetKit Extension Targets
- In `Sources/AntigravityWidget` and `Sources/GrokWidget`:
  - Timeline providers reading `group.com.dad.aiusage` cache.
  - Small and medium widget views displaying live remaining quotas and refresh status.

## Step 5: Root Package.swift & Build System
- Update `Package.swift` to expose `SharedQuotaKit`, `AntigravityUsageApp`, `GrokUsageApp`, `AntigravityWidget`, `GrokWidget`.
- Create clean `build.sh` script to build, codesign with entitlements, and install into `/Applications/`.

## Step 6: Build, Test, Verification & Cleanup
- Compile all targets with `swift build -c release`.
- Run validation checks and verify live menu bar and popover flows.
- Organize legacy files into reference status.
