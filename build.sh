#!/usr/bin/env bash
# build.sh — Production build and installation for Antigravity Usage & Grok Usage
# Pure Native Swift/SwiftUI/AppKit/WidgetKit Suite
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANTIGRAVITY_APP="/Applications/Antigravity Usage.app"
GROK_APP="/Applications/Grok Usage.app"

echo "==> Terminating running instances..."
pkill -f "Antigravity Usage" 2>/dev/null || true
pkill -f "Grok Usage" 2>/dev/null || true
sleep 0.5

echo "==> Building Release binaries via Swift Package Manager..."
swift build -c release --package-path "${SCRIPT_DIR}"

BIN_DIR="${SCRIPT_DIR}/.build/release"

# ─────────────────────────────────────────────────────────────────────────────
# 1. Package Antigravity Usage.app
# ─────────────────────────────────────────────────────────────────────────────
echo "==> Packaging ${ANTIGRAVITY_APP}..."
rm -rf "${ANTIGRAVITY_APP}"
mkdir -p "${ANTIGRAVITY_APP}/Contents/MacOS"
mkdir -p "${ANTIGRAVITY_APP}/Contents/Resources"

cp "${BIN_DIR}/AntigravityUsageApp" "${ANTIGRAVITY_APP}/Contents/MacOS/Antigravity Usage"
chmod +x "${ANTIGRAVITY_APP}/Contents/MacOS/Antigravity Usage"

if [ -f "${SCRIPT_DIR}/AntigravityAppIcon.icns" ]; then
  cp "${SCRIPT_DIR}/AntigravityAppIcon.icns" "${ANTIGRAVITY_APP}/Contents/Resources/AppIcon.icns"
elif [ -f "${SCRIPT_DIR}/AppIcon.icns" ]; then
  cp "${SCRIPT_DIR}/AppIcon.icns" "${ANTIGRAVITY_APP}/Contents/Resources/AppIcon.icns"
elif [ -f "/Applications/Antigravity.app/Contents/Resources/icon.icns" ]; then
  cp "/Applications/Antigravity.app/Contents/Resources/icon.icns" "${ANTIGRAVITY_APP}/Contents/Resources/AppIcon.icns"
fi

cat << 'EOF' > "${ANTIGRAVITY_APP}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Antigravity Usage</string>
    <key>CFBundleDisplayName</key>
    <string>Antigravity Usage</string>
    <key>CFBundleIdentifier</key>
    <string>com.dad.antigravity.usage</string>
    <key>CFBundleVersion</key>
    <string>12.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>12.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>Antigravity Usage</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <true/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsLocalNetworking</key>
        <true/>
    </dict>
</dict>
</plist>
EOF

echo "APPL????" > "${ANTIGRAVITY_APP}/Contents/PkgInfo"

echo "==> Code-signing Antigravity Usage with entitlements..."
xattr -cr "${ANTIGRAVITY_APP}" 2>/dev/null || true
codesign --force --deep --sign - --entitlements "${SCRIPT_DIR}/antigravity.entitlements" "${ANTIGRAVITY_APP}"

# ─────────────────────────────────────────────────────────────────────────────
# 2. Package Grok Usage.app
# ─────────────────────────────────────────────────────────────────────────────
echo "==> Packaging ${GROK_APP}..."
rm -rf "${GROK_APP}"
mkdir -p "${GROK_APP}/Contents/MacOS"
mkdir -p "${GROK_APP}/Contents/Resources"

cp "${BIN_DIR}/GrokUsageApp" "${GROK_APP}/Contents/MacOS/Grok Usage"
chmod +x "${GROK_APP}/Contents/MacOS/Grok Usage"

if [ -f "${SCRIPT_DIR}/GrokAppIcon.icns" ]; then
  cp "${SCRIPT_DIR}/GrokAppIcon.icns" "${GROK_APP}/Contents/Resources/AppIcon.icns"
fi

cat << 'EOF' > "${GROK_APP}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Grok Usage</string>
    <key>CFBundleDisplayName</key>
    <string>Grok Usage</string>
    <key>CFBundleIdentifier</key>
    <string>com.dad.grok.usage</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>Grok Usage</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>com.dad.grok.usage.oauth</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>grokquota</string>
            </array>
        </dict>
    </array>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsLocalNetworking</key>
        <true/>
    </dict>
</dict>
</plist>
EOF

echo "APPL????" > "${GROK_APP}/Contents/PkgInfo"

echo "==> Code-signing Grok Usage with entitlements..."
xattr -cr "${GROK_APP}" 2>/dev/null || true
codesign --force --deep --sign - --entitlements "${SCRIPT_DIR}/grok.entitlements" "${GROK_APP}"

# ─────────────────────────────────────────────────────────────────────────────
# 3. Launch Both Applications
# ─────────────────────────────────────────────────────────────────────────────
echo "==> Launching Antigravity Usage..."
open "${ANTIGRAVITY_APP}"

echo "==> Launching Grok Usage..."
open "${GROK_APP}"

echo "==> Done! Both pure native apps are active in the macOS menu bar."
