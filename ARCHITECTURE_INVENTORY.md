# Architecture Inventory

## KEEP (Conforms to native architecture)
- `Package.swift`: Root SPM package configuration (updated to multi-target layout)
- `antigravity.entitlements`: App Group and Keychain access entitlements
- `SharedModels/SharedQuota.swift`: Core data model for cross-process snapshot sharing
- `AntigravityWidget/AntigravityWidget.swift`: Native WidgetKit timeline provider and view
- `AntigravityWidget/AntigravityWidgetBundle.swift`: Widget bundle entrypoint

## MIGRATE (Reusable logic/assets to convert into shared Swift package)
- `Sources/AntigravityUsageApp/app_main.swift`: Extract common SwiftUI components (Obsidian header, rate limit cards, progress bars, window snap/unsnap HUD controller, menu bar status manager) into `SharedQuotaKit`.
- `build_app_v12.sh` / `build_app_v11.sh`: Standardize into clean production build script `build.sh` building both Antigravity and Grok apps.
- `package_release_v2.sh`: Standardize into `package.sh` creating signed production app bundles.

## REFERENCE ONLY (Historical reference for behaviors & API payloads; do not extend)
- `antigravity_usage_v1.py` through `antigravity_usage_v5.py`: Python daemon reference for Keychain extraction & API endpoints
- `app_main_v1.swift` through `app_main_v12.swift`: Prototype iterations preserved in root/archive
- `index_v1.html` through `index_v7.html`: HTML/CSS visual design reference
- `widget_v1.html` through `widget_v7.html`: Widget layout design reference
- `DEVELOPMENT_NOTES_v1.md`, `DEVELOPMENT_NOTES_v2.md`: Engineering decision logs

## DELETE CANDIDATE (Redundant temporary artifacts; do not delete without approval)
- Root prototype Swift files: `app_main_v10.swift`, `app_main_v11.swift`, `app_main_v12.swift` (superseded by Sources/)
- Root build scripts: `build_app_v10.sh`, `build_app_v11.sh`, `build_app_v12.sh` (superseded by `build.sh`)
- Old web assets in `Sources/AntigravityUsageApp/Resources/index.html` and `widget.html` (pure native UI eliminates WebKit)
- Empty logs: `daemon.log`, `daemon_error.log`
