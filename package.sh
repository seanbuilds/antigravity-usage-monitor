#!/usr/bin/env bash
# package.sh — Create signed release zip bundles with SHA-256 checksums
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

DIST_DIR="${SCRIPT_DIR}/dist"
mkdir -p "${DIST_DIR}"

# Build latest release binaries and apps
./build.sh

echo "==> Creating release zip archives..."

# Antigravity Usage
cd /Applications
zip -qry "${DIST_DIR}/Antigravity-Usage-macOS.zip" "Antigravity Usage.app"
cd "${DIST_DIR}"
shasum -a 256 "Antigravity-Usage-macOS.zip" > "Antigravity-Usage-macOS.zip.sha256"

# Grok Usage
cd /Applications
zip -qry "${DIST_DIR}/Grok-Usage-macOS.zip" "Grok Usage.app"
cd "${DIST_DIR}"
shasum -a 256 "Grok-Usage-macOS.zip" > "Grok-Usage-macOS.zip.sha256"

echo "==> Release Packages Created:"
ls -lh "${DIST_DIR}"
cat "${DIST_DIR}"/*.sha256
