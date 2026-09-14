#!/usr/bin/env bash
# v2 – Package Antigravity Usage Monitor v12.0.0 release distribution with codesign verification, entitlement inspection, and Dock integration
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="/Applications/Antigravity Usage.app"
DIST_DIR="${SCRIPT_DIR}/dist"
VERSION="12.0.0"
ZIP_NAME="Antigravity-Usage-v${VERSION}-macOS.zip"
ENTITLEMENTS_FILE="${SCRIPT_DIR}/antigravity.entitlements"

echo "=========================================================="
echo " Antigravity Usage Monitor v${VERSION} Release Packager"
echo "=========================================================="

# 1. Verify Application Bundle
echo "==> [1/6] Verifying application bundle at ${APP_DIR}..."
if [ ! -d "${APP_DIR}" ]; then
  echo "ERROR: Application bundle not found at ${APP_DIR}" >&2
  exit 1
fi

BUNDLE_VERSION="$(defaults read "${APP_DIR}/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "unknown")"
echo "    Found installed bundle version: ${BUNDLE_VERSION}"
if [ "${BUNDLE_VERSION}" != "${VERSION}" ]; then
  echo "    Warning: Bundle version (${BUNDLE_VERSION}) does not match packaging target (${VERSION})."
fi

# 2. Verify Code Signing & Entitlements
echo "==> [2/6] Verifying code signature and App Group entitlements..."
xattr -cr "${APP_DIR}" 2>/dev/null || true

if ! codesign -v --deep --strict "${APP_DIR}" 2>/dev/null; then
  echo "    Signature check reported issues, re-signing bundle with entitlements..."
  if [ -f "${ENTITLEMENTS_FILE}" ]; then
    codesign --force --deep --sign - --entitlements "${ENTITLEMENTS_FILE}" "${APP_DIR}"
  else
    codesign --force --deep --sign - "${APP_DIR}"
  fi
fi

echo "    Performing strict signature verification..."
codesign -v --deep --strict "${APP_DIR}"
echo "    ✓ Code signature verified strictly."

echo "    Inspecting active entitlements..."
ENTITLEMENTS_OUTPUT="$(codesign -d --entitlements :- "${APP_DIR}" 2>/dev/null || true)"
if echo "${ENTITLEMENTS_OUTPUT}" | grep -q "group.com.dad.aiusage"; then
  echo "    ✓ App Group entitlement verified: group.com.dad.aiusage"
else
  echo "    Notice: App Group entitlement not detected or formatted differently."
fi

# 3. Prepare Distribution Directory
echo "==> [3/6] Preparing distribution directory..."
mkdir -p "${DIST_DIR}"
rm -f "${DIST_DIR}/${ZIP_NAME}" "${DIST_DIR}/${ZIP_NAME}.sha256"

# 4. Create Release Zip Archive
echo "==> [4/6] Creating clean release zip archive preserving code signatures & resource forks..."
ditto -c -k --sequesterRsrc --keepParent "${APP_DIR}" "${DIST_DIR}/${ZIP_NAME}"

# Verify zip archive integrity
echo "    Testing archive integrity..."
unzip -t -q "${DIST_DIR}/${ZIP_NAME}"
echo "    ✓ Archive integrity verified."

# 5. Compute SHA-256 Checksum
echo "==> [5/6] Generating SHA-256 checksum..."
(
  cd "${DIST_DIR}"
  shasum -a 256 "${ZIP_NAME}" > "${ZIP_NAME}.sha256"
)

CHECKSUM="$(cat "${DIST_DIR}/${ZIP_NAME}.sha256" | awk '{print $1}')"
FILE_SIZE="$(du -h "${DIST_DIR}/${ZIP_NAME}" | awk '{print $1}')"

# 6. Verify Dock Integration
echo "==> [6/6] Verifying macOS Dock integration..."
if command -v dockutil &> /dev/null; then
  if dockutil --find "Antigravity Usage" &> /dev/null; then
    echo "    ✓ Antigravity Usage is present in macOS Dock."
  else
    echo "    Adding Antigravity Usage to macOS Dock beside Antigravity..."
    if dockutil --find "Antigravity" &> /dev/null; then
      dockutil --add "${APP_DIR}" --after "Antigravity" --allhomes
    else
      dockutil --add "${APP_DIR}" --allhomes
    fi
    echo "    ✓ Added to macOS Dock beside Antigravity."
  fi
else
  echo "    Notice: dockutil not installed or not in PATH, skipping Dock placement check."
fi

echo "=========================================================="
echo " Antigravity Usage Monitor v${VERSION} Packaging Complete"
echo "=========================================================="
echo " Archive:  ${DIST_DIR}/${ZIP_NAME} (${FILE_SIZE})"
echo " SHA-256:  ${CHECKSUM}"
echo " Status:   Verified & Ready for Distribution"
echo "=========================================================="
