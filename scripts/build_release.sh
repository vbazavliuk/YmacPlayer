#!/usr/bin/env bash
# ==============================================================================
# Ymac Player - Release Packaging Script
# 
# Builds the Release configuration of YmacPlayer and packages it into:
#   1. YmacPlayer-<version>.zip (direct archive)
#   2. YmacPlayer-<version>.dmg (drag-and-drop installer)
#   3. SHA256SUMS.txt (cryptographic checksums)
# ==============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo -e "${BLUE}${BOLD}=== Ymac Player Release Packaging ===${NC}\n"

# 1. Detect Xcode Developer Directory
if ! command -v xcodebuild &>/dev/null || xcode-select -p 2>&1 | grep -q "CommandLineTools"; then
    if [ -d "/Volumes/FastBoy/Applications/Xcode.app/Contents/Developer" ]; then
        export DEVELOPER_DIR="/Volumes/FastBoy/Applications/Xcode.app/Contents/Developer"
    elif [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
        export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
    fi
fi

if ! command -v xcodebuild &>/dev/null; then
    echo -e "${RED}Error: xcodebuild not found. Please install Xcode or set DEVELOPER_DIR.${NC}"
    exit 1
fi
XCODE_INFO=$(xcodebuild -version 2>/dev/null || true)
XCODE_VERSION=$(echo "$XCODE_INFO" | grep "Xcode" || echo "Xcode")
echo -e "Using: ${GREEN}${XCODE_VERSION}${NC} (${DEVELOPER_DIR:-$(xcode-select -p)})"

# 2. Configurable Variables
SCHEME="YmacPlayer"
PROJECT="YmacPlayer.xcodeproj"
CONFIGURATION="${CONFIGURATION:-Release}"
OUTPUT_DIR="${OUTPUT_DIR:-dist}"
DERIVED_DATA_PATH="/tmp/YmacPlayer-DerivedData"
VERSION="${VERSION:-1.0.0}"

echo -e "Scheme:        ${BOLD}${SCHEME}${NC}"
echo -e "Configuration: ${BOLD}${CONFIGURATION}${NC}"
echo -e "Version:       ${BOLD}${VERSION}${NC}"
echo -e "Output:        ${BOLD}${OUTPUT_DIR}/${NC}\n"

# 3. Clean and prepare directories
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
mkdir -p "build"

# 4. Build Release
echo -e "${BLUE}🔨 Building ${SCHEME} (${CONFIGURATION})...${NC}"

BUILD_SIGNING_FLAGS=()
if [ "${SIGN_ADHOC:-0}" = "1" ]; then
    echo -e "${YELLOW}Notice: Building with ad-hoc signature for CI/distribution without developer certs.${NC}"
    BUILD_SIGNING_FLAGS=(
        "CODE_SIGN_IDENTITY=-"
        "CODE_SIGN_STYLE=Manual"
    )
elif [ -n "${DEVELOPMENT_TEAM:-}" ]; then
    echo -e "Using Development Team: ${GREEN}${DEVELOPMENT_TEAM}${NC}"
    BUILD_SIGNING_FLAGS=(
        "DEVELOPMENT_TEAM=${DEVELOPMENT_TEAM}"
    )
fi

if command -v xcbeautify &>/dev/null; then
    xcodebuild \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        ${BUILD_SIGNING_FLAGS[@]+"${BUILD_SIGNING_FLAGS[@]}"} \
        clean build | xcbeautify
else
    xcodebuild \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        ${BUILD_SIGNING_FLAGS[@]+"${BUILD_SIGNING_FLAGS[@]}"} \
        clean build -quiet
fi

# Check if build succeeded
APP_PATH="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}/YmacPlayer.app"
if [ ! -d "$APP_PATH" ]; then
    # Fallback search if path varies
    FOUND_APP=$(find "${DERIVED_DATA_PATH}/Build/Products" -name "YmacPlayer.app" -type d 2>/dev/null | head -n 1 || true)
    if [ -n "$FOUND_APP" ] && [ -d "$FOUND_APP" ]; then
        APP_PATH="$FOUND_APP"
    else
        echo -e "${RED}❌ Build failed: YmacPlayer.app not found in ${DERIVED_DATA_PATH}.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Build succeeded:${NC} ${APP_PATH}"

# Remove any extended attributes (iCloud/FinderInfo) that trigger Gatekeeper rejection
xattr -rc "$APP_PATH" 2>/dev/null || true

# If built with ad-hoc signing, ensure entitlements are applied properly
if [ "${SIGN_ADHOC:-0}" = "1" ]; then
    echo -e "${BLUE}🔏 Applying clean ad-hoc signature with entitlements...${NC}"
    WIDGET_PATH="$APP_PATH/Contents/PlugIns/YmacPlayerWidgetExtension.appex"
    if [ -d "$WIDGET_PATH" ]; then
        codesign --force --sign - --entitlements YmacPlayerWidgetExtension.entitlements "$WIDGET_PATH"
    fi
    codesign --force --sign - --entitlements YmacPlayer/YmacPlayer.entitlements "$APP_PATH"
fi

# 5. Create ZIP Archive
ZIP_NAME="YmacPlayer-${VERSION}.zip"
ZIP_PATH="${OUTPUT_DIR}/${ZIP_NAME}"
echo -e "\n${BLUE}📦 Creating ZIP archive: ${ZIP_NAME}...${NC}"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
echo -e "${GREEN}✓ Created:${NC} ${ZIP_PATH} ($(du -sh "$ZIP_PATH" | cut -f1))"

# 6. Create DMG Image
DMG_NAME="YmacPlayer-${VERSION}.dmg"
DMG_PATH="${OUTPUT_DIR}/${DMG_NAME}"
DMG_STAGING="build/dmg_staging"

echo -e "\n${BLUE}💿 Creating DMG disk image: ${DMG_NAME}...${NC}"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"

# Copy App to staging
cp -R "$APP_PATH" "$DMG_STAGING/"

# Add Applications symlink
ln -s /Applications "$DMG_STAGING/Applications"

# Build DMG using hdiutil
hdiutil create \
    -volname "Ymac Player" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDZO \
    "$DMG_PATH" > /dev/null

rm -rf "$DMG_STAGING"
echo -e "${GREEN}✓ Created:${NC} ${DMG_PATH} ($(du -sh "$DMG_PATH" | cut -f1))"

# 7. Generate Checksums
echo -e "\n${BLUE}🔐 Generating SHA-256 checksums...${NC}"
cd "$OUTPUT_DIR"
shasum -a 256 "$ZIP_NAME" "$DMG_NAME" > "SHA256SUMS.txt"
cd "$PROJECT_DIR"
echo -e "${GREEN}✓ Checksums written to:${NC} ${OUTPUT_DIR}/SHA256SUMS.txt\n"

cat "${OUTPUT_DIR}/SHA256SUMS.txt"

echo -e "\n${GREEN}${BOLD}🎉 Release packaging complete! Artifacts are ready in ${OUTPUT_DIR}/${NC}"
