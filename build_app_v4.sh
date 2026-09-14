#!/usr/bin/env bash
# v4 – Build and install ultra-clean native macOS Menu Bar Popover application
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="/Applications/Antigravity Usage.app"

echo "==> Terminating any running instance of Antigravity Usage..."
pkill -f "Antigravity Usage" 2>/dev/null || true

echo "==> Compiling native Swift executable (v4 Ultra-Clean Popover)..."
swiftc -O \
  -framework Cocoa \
  -framework WebKit \
  "${SCRIPT_DIR}/app_main_v4.swift" \
  -o "${SCRIPT_DIR}/Antigravity Usage"

echo "==> Creating macOS App bundle structure at ${APP_DIR}..."
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

# Move compiled binary
mv "${SCRIPT_DIR}/Antigravity Usage" "${APP_DIR}/Contents/MacOS/Antigravity Usage"
chmod +x "${APP_DIR}/Contents/MacOS/Antigravity Usage"

# Copy HTML UI (v4 ultra-clean layout)
cp "${SCRIPT_DIR}/index_v4.html" "${APP_DIR}/Contents/Resources/index.html"

# Copy Icon
if [ -f "/Applications/Antigravity.app/Contents/Resources/icon.icns" ]; then
  cp "/Applications/Antigravity.app/Contents/Resources/icon.icns" "${APP_DIR}/Contents/Resources/AppIcon.icns"
fi

# Write Info.plist
cat << 'EOF' > "${APP_DIR}/Contents/Info.plist"
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
    <string>4.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>4.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>Antigravity Usage</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsLocalNetworking</key>
        <true/>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
</dict>
</plist>
EOF

echo "APPL????" > "${APP_DIR}/Contents/PkgInfo"

# Code sign ad-hoc
echo "==> Ad-hoc signing bundle..."
codesign --force --deep --sign - "${APP_DIR}"

echo "==> Updating macOS Dock entry..."
if command -v dockutil &> /dev/null; then
  dockutil --remove "Antigravity Usage" --no-restart 2>/dev/null || true
  if dockutil --find "Antigravity" &> /dev/null; then
    dockutil --add "${APP_DIR}" --after "Antigravity" --allhomes
  else
    dockutil --add "${APP_DIR}" --allhomes
  fi
fi

echo "==> Launching updated Antigravity Usage (v4 Clean Popover)..."
open "${APP_DIR}"

echo "==> Done! Antigravity Usage now has a clean, refined Apple-native popover."
