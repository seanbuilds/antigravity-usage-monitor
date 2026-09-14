#!/usr/bin/env bash
# v1 – Package Antigravity Usage Monitor for GitHub Release Distribution
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="/Applications/Antigravity Usage.app"
DIST_DIR="${SCRIPT_DIR}/dist"
VERSION="11.0.0"
ZIP_NAME="Antigravity-Usage-v${VERSION}-macOS.zip"

echo "==> Ensuring fresh release build of Antigravity Usage v${VERSION}..."
"${SCRIPT_DIR}/build_app_v11.sh"

echo "==> Preparing distribution directory..."
mkdir -p "${DIST_DIR}"
rm -f "${DIST_DIR}/${ZIP_NAME}" "${DIST_DIR}/${ZIP_NAME}.sha256"

echo "==> Creating clean zip archive preserving code signatures & resource forks..."
ditto -c -k --sequesterRsrc --keepParent "${APP_DIR}" "${DIST_DIR}/${ZIP_NAME}"

echo "==> Generating SHA256 checksum..."
cd "${DIST_DIR}"
shasum -a 256 "${ZIP_NAME}" > "${ZIP_NAME}.sha256"
cd "${SCRIPT_DIR}"

CHECKSUM="$(cat "${DIST_DIR}/${ZIP_NAME}.sha256" | awk '{print $1}')"
FILE_SIZE="$(du -h "${DIST_DIR}/${ZIP_NAME}" | awk '{print $1}')"

echo "=========================================================="
echo " Antigravity Usage Monitor v${VERSION} Package Complete"
echo "=========================================================="
echo " Release Asset:  ${DIST_DIR}/${ZIP_NAME} (${FILE_SIZE})"
echo " SHA-256:        ${CHECKSUM}"
echo " Ready to upload to GitHub Releases or share."
echo "=========================================================="
