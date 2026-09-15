# Architecture Inventory

## KEEP (Conforms to native architecture)
- `Package.swift`: Root SPM package configuration (multi-target layout)
- `antigravity.entitlements`, `grok.entitlements`: App Group and Keychain access entitlements
- `Sources/SharedQuotaKit/`: Shared native Swift framework (Domain models, SwiftUI views, HUD panel, MenuBar manager, Keychain, and App Group persistence)
- `Sources/AntigravityUsageApp/`: Native Antigravity menu bar application target
- `Sources/GrokUsageApp/`: Native Grok menu bar application target
- `Sources/AntigravityWidget/`: Native WidgetKit timeline provider and view
- `Sources/GrokWidget/`: Native Grok WidgetKit timeline provider and view
- `Tests/TestRunner/`: Native validation test suite
- `build.sh`: Unified production build and packaging script

## ARCHIVED (Moved to `./archive/`)
- Prototype Swift files: `app_main_v11.swift`, `app_main_v12.swift` (and earlier versions `v1`-`v10`)
- Prototype build scripts: `build_app_v11.sh`, `build_app_v12.sh` (and earlier versions `v1`-`v10`)
- Prototype HTML/CSS assets: `index_v6.html`, `index_v7.html`, `widget_v6.html`, `widget_v7.html`
- Python daemon reference scripts: `antigravity_usage_v4.py`, `antigravity_usage_v5.py`

## REFERENCE ONLY (Historical reference for behaviors & API payloads; do not extend)
- Files preserved in `./archive/`: Prior Python scripts, HTML prototypes, and build scripts.
- `DEVELOPMENT_NOTES_v1.md`, `README_v12.md`, `README_v13.md`.
