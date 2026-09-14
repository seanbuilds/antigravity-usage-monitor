#!/usr/bin/env bash
# v10 – Build and install pure native SwiftUI & AppKit macOS Menu Bar app via SPM (Deterministic Refresh)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="/Applications/Antigravity Usage.app"

echo "==> Terminating any running instance of Antigravity Usage..."
pkill -f "Antigravity Usage" 2>/dev/null || true
sleep 0.5

# Sync SPM sources with v10 native Swift code
cp "${SCRIPT_DIR}/app_main_v10.swift" "${SCRIPT_DIR}/Sources/AntigravityUsageApp/app_main.swift"

echo "==> Compiling pure native SwiftUI executable (v10 SPM Release Build)..."
swift build -c release --target AntigravityUsageApp --package-path "${SCRIPT_DIR}"

BIN_PATH="${SCRIPT_DIR}/.build/release/AntigravityUsageApp"
if [ ! -f "${BIN_PATH}" ]; then
  echo "==> Fallback to swiftc release compilation..."
  swiftc -parse-as-library -O \
    -framework Cocoa \
    -framework SwiftUI \
    -framework WidgetKit \
    "${SCRIPT_DIR}/app_main_v10.swift" \
    -o "${SCRIPT_DIR}/Antigravity Usage"
  BIN_PATH="${SCRIPT_DIR}/Antigravity Usage"
fi

echo "==> Creating macOS App bundle structure at ${APP_DIR}..."
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

# Move compiled binary
cp "${BIN_PATH}" "${APP_DIR}/Contents/MacOS/Antigravity Usage"
chmod +x "${APP_DIR}/Contents/MacOS/Antigravity Usage"

# Copy Icon
if [ -f "/Applications/Antigravity.app/Contents/Resources/icon.icns" ]; then
  cp "/Applications/Antigravity.app/Contents/Resources/icon.icns" "${APP_DIR}/Contents/Resources/AppIcon.icns"
elif [ -f "${HOME}/Applications/Antigravity.app/Contents/Resources/icon.icns" ]; then
  cp "${HOME}/Applications/Antigravity.app/Contents/Resources/icon.icns" "${APP_DIR}/Contents/Resources/AppIcon.icns"
fi

# Write Info.plist
cat << 'EOF' > "${APP_DIR}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!-- v10 – Info.plist for Pure SwiftUI & AppKit Menu Bar App -->
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Antigravity Usage</string>
    <key>CFBundleDisplayName</key>
    <string>Antigravity Usage</string>
    <key>CFBundleIdentifier</key>
    <string>com.dad.antigravity.usage</string>
    <key>CFBundleVersion</key>
    <string>10.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>10.0.0</string>
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

echo "APPL????" > "${APP_DIR}/Contents/PkgInfo"

# Clear quarantine and sign with App Group entitlements
echo "==> Code-signing bundle with entitlements..."
xattr -cr "${APP_DIR}" 2>/dev/null || true
if [ -f "${SCRIPT_DIR}/antigravity.entitlements" ]; then
  codesign --force --deep --sign - --entitlements "${SCRIPT_DIR}/antigravity.entitlements" "${APP_DIR}"
else
  codesign --force --deep --sign - "${APP_DIR}"
fi

echo "==> Updating macOS Dock entry..."
if command -v dockutil &> /dev/null; then
  dockutil --remove "Antigravity Usage" --no-restart 2>/dev/null || true
  if dockutil --find "Antigravity" &> /dev/null; then
    dockutil --add "${APP_DIR}" --after "Antigravity" --allhomes
  else
    dockutil --add "${APP_DIR}" --allhomes
  fi
fi

echo "==> Launching 100% Pure Native Antigravity Usage v10..."
open "${APP_DIR}"

echo "==> Done! Antigravity Usage v10 is running."
