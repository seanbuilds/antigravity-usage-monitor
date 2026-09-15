#!/usr/bin/env bash
# package_dmg.sh — Build standalone DMG installers and Homebrew Casks
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

DIST_DIR="${SCRIPT_DIR}/dist"
mkdir -p "${DIST_DIR}"

# 1. Compile and package both applications
echo "==> Running production build..."
./build.sh

# 2. Function to create a clean DMG
create_app_dmg() {
    local APP_NAME="$1"
    local DMG_NAME="$2"
    local DMG_PATH="${DIST_DIR}/${DMG_NAME}.dmg"
    local VOL_NAME="$1 Installer"
    local STAGING_DIR="${DIST_DIR}/staging_${DMG_NAME}"

    echo "==> Packaging ${APP_NAME} into ${DMG_NAME}.dmg..."
    rm -rf "${STAGING_DIR}" "${DMG_PATH}"
    mkdir -p "${STAGING_DIR}"

    # Copy application bundle and Applications symlink
    cp -R "/Applications/${APP_NAME}.app" "${STAGING_DIR}/"
    ln -s /Applications "${STAGING_DIR}/Applications"

    # Create compressed disk image
    hdiutil create -volname "${VOL_NAME}" \
                   -srcfolder "${STAGING_DIR}" \
                   -ov \
                   -format UDZO \
                   "${DMG_PATH}"

    rm -rf "${STAGING_DIR}"

    # Calculate SHA-256
    local SHA256=$(shasum -a 256 "${DMG_PATH}" | awk '{print $1}')
    echo "${SHA256}  ${DMG_NAME}.dmg" > "${DIST_DIR}/${DMG_NAME}.dmg.sha256"
    echo "    ✓ Built ${DMG_PATH} (SHA256: ${SHA256})"
}

# 3. Create DMGs for both Antigravity Usage and Grok Usage
create_app_dmg "Antigravity Usage" "Antigravity-Usage-macOS"
create_app_dmg "Grok Usage" "Grok-Usage-macOS"

# 4. Generate Homebrew Cask Formula for Grok Usage
GROK_SHA=$(cat "${DIST_DIR}/Grok-Usage-macOS.dmg.sha256" | awk '{print $1}')
cat << EOF > "${DIST_DIR}/grok-usage.rb"
cask "grok-usage" do
  version "1.0.0"
  sha256 "${GROK_SHA}"

  url "https://github.com/seanbuilds/antigravity-usage-monitor/releases/download/v#{version}/Grok-Usage-macOS.dmg"
  name "Grok Usage"
  desc "Native macOS Menu Bar Quota & Rate Limit Tracker for Grok / xAI"
  homepage "https://github.com/seanbuilds/antigravity-usage-monitor"

  app "Grok Usage.app"

  zap trash: [
    "~/Library/Preferences/com.dad.grok.usage.plist",
    "~/Library/Group Containers/group.com.dad.aiusage",
  ]
end
EOF

echo "==> Done! Production distribution artifacts generated in ${DIST_DIR}."
ls -lh "${DIST_DIR}"
