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

# 1. Detect Xcode Developer Directory (with CommandLineTools swiftc fallback)
USE_XCODE=0
if command -v xcodebuild &>/dev/null && xcodebuild -version &>/dev/null; then
    USE_XCODE=1
else
    for candidate in \
        "/Volumes/FastBoy/Applications/Xcode.app/Contents/Developer" \
        "/Applications/Xcode.app/Contents/Developer"; do
        if [ -d "$candidate" ] && DEVELOPER_DIR="$candidate" xcodebuild -version &>/dev/null; then
            export DEVELOPER_DIR="$candidate"
            USE_XCODE=1
            break
        fi
    done
fi

# 2. Configurable Variables
SCHEME="YmacPlayer"
PROJECT="YmacPlayer.xcodeproj"
CONFIGURATION="${CONFIGURATION:-Release}"
OUTPUT_DIR="${OUTPUT_DIR:-dist}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/tmp/YmacPlayer-DerivedData}"
VERSION="${VERSION:-1.1.0}"
DEFAULT_CLT_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk"
TARGET_ARCH="${TARGET_ARCH:-$(uname -m)}"
TARGET_TRIPLE="${TARGET_ARCH}-apple-macosx14.0"

if [ "$USE_XCODE" -eq 1 ]; then
    XCODE_INFO=$(xcodebuild -version 2>/dev/null || true)
    XCODE_VERSION=$(echo "$XCODE_INFO" | grep "Xcode" || echo "Xcode")
    echo -e "Using: ${GREEN}${XCODE_VERSION}${NC} (${DEVELOPER_DIR:-$(xcode-select -p)})"
else
    if ! command -v swiftc &>/dev/null; then
        echo -e "${RED}Error: Neither xcodebuild nor swiftc was found.${NC}"
        exit 1
    fi
    if [ -n "${SDK_PATH:-}" ]; then
        :
    elif [ -d "$DEFAULT_CLT_SDK" ]; then
        SDK_PATH="$DEFAULT_CLT_SDK"
    else
        SDK_PATH="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
    fi
    if [ -z "${SDK_PATH:-}" ] || [ ! -d "$SDK_PATH" ]; then
        echo -e "${RED}Error: macOS SDK not found (checked ${DEFAULT_CLT_SDK}).${NC}"
        exit 1
    fi
    SWIFT_VERSION_STR="$(swiftc --version 2>/dev/null | head -n 1)"
    echo -e "${YELLOW}Notice: Full Xcode (xcodebuild) unavailable; using CommandLineTools (swiftc) fallback.${NC}"
    echo -e "Using: ${GREEN}${SWIFT_VERSION_STR}${NC}"
    echo -e "SDK:   ${GREEN}${SDK_PATH}${NC}"
fi

echo -e "Scheme:        ${BOLD}${SCHEME}${NC}"
echo -e "Configuration: ${BOLD}${CONFIGURATION}${NC}"
echo -e "Version:       ${BOLD}${VERSION}${NC}"
echo -e "Output:        ${BOLD}${OUTPUT_DIR}/${NC}\n"

# 3. Clean and prepare directories
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
mkdir -p "build"

resolve_sign_identity() {
    if [ "${SIGN_ADHOC:-0}" = "1" ]; then
        echo "-"
        return
    fi
    if [ -n "${CODE_SIGN_IDENTITY:-}" ]; then
        echo "$CODE_SIGN_IDENTITY"
        return
    fi
    local dev_identity
    dev_identity=$(security find-identity -v -p codesigning 2>/dev/null | sed -n 's/.*"\(Apple Development:[^"]*\)".*/\1/p' | head -n 1 || true)
    if [ -n "$dev_identity" ]; then
        echo "$dev_identity"
    else
        echo "-"
    fi
}

sign_bundle() {
    local app_path="$1"
    local identity="${2:--}"
    local widget_path="${app_path}/Contents/PlugIns/YmacPlayerWidgetExtension.appex"
    rm -f "${app_path}/Contents/embedded.provisionprofile"
    rm -f "${widget_path}/Contents/embedded.provisionprofile"
    if [ -d "$widget_path" ]; then
        codesign --force --sign "$identity" --entitlements "YmacPlayerWidgetExtension.entitlements" "$widget_path"
    fi
    codesign --force --sign "$identity" --entitlements "YmacPlayer/YmacPlayer.entitlements" "$app_path"
}

build_with_xcode() {
    local build_signing_flags=()
    if [ "${SIGN_ADHOC:-0}" = "1" ]; then
        echo -e "${YELLOW}Notice: Building with ad-hoc signature for CI/distribution without developer certs.${NC}"
        build_signing_flags=(
            "CODE_SIGN_IDENTITY=-"
            "CODE_SIGN_STYLE=Manual"
        )
    elif [ -n "${DEVELOPMENT_TEAM:-}" ]; then
        echo -e "Using Development Team: ${GREEN}${DEVELOPMENT_TEAM}${NC}"
        build_signing_flags=(
            "DEVELOPMENT_TEAM=${DEVELOPMENT_TEAM}"
        )
    fi

    if command -v xcbeautify &>/dev/null; then
        xcodebuild \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -configuration "$CONFIGURATION" \
            -derivedDataPath "$DERIVED_DATA_PATH" \
            ${build_signing_flags[@]+"${build_signing_flags[@]}"} \
            clean build | xcbeautify
    else
        xcodebuild \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -configuration "$CONFIGURATION" \
            -derivedDataPath "$DERIVED_DATA_PATH" \
            ${build_signing_flags[@]+"${build_signing_flags[@]}"} \
            clean build -quiet
    fi

    APP_PATH="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}/YmacPlayer.app"
    if [ ! -d "$APP_PATH" ]; then
        local found_app
        found_app=$(find "${DERIVED_DATA_PATH}/Build/Products" -name "YmacPlayer.app" -type d 2>/dev/null | head -n 1 || true)
        if [ -n "$found_app" ] && [ -d "$found_app" ]; then
            APP_PATH="$found_app"
        else
            echo -e "${RED}❌ Build failed: YmacPlayer.app not found in ${DERIVED_DATA_PATH}.${NC}"
            exit 1
        fi
    fi

    xattr -rc "$APP_PATH" 2>/dev/null || true

    local sign_identity
    sign_identity="$(resolve_sign_identity)"
    echo -e "${BLUE}🔏 Applying non-expiring signature (${sign_identity}) with entitlements...${NC}"
    sign_bundle "$APP_PATH" "$sign_identity"
}

build_with_clt() {
    local clt_build_dir="${CLT_BUILD_DIR:-/tmp/YmacPlayer-swiftc-${CONFIGURATION}}"
    rm -rf "$clt_build_dir"

    APP_PATH="${clt_build_dir}/YmacPlayer.app"
    local app_contents="${APP_PATH}/Contents"
    local app_macos="${app_contents}/MacOS"
    local app_resources="${app_contents}/Resources"
    local widget_path="${app_contents}/PlugIns/YmacPlayerWidgetExtension.appex"
    local widget_contents="${widget_path}/Contents"
    local widget_macos="${widget_contents}/MacOS"
    local widget_resources="${widget_contents}/Resources"

    mkdir -p "$app_macos" "$app_resources" "$widget_macos" "$widget_resources"

    local swift_opt_flags=("-O" "-whole-module-optimization")
    if [ "$CONFIGURATION" = "Debug" ]; then
        swift_opt_flags=("-Onone" "-g")
    fi

    echo -e "${BLUE}  • Compiling YmacPlayer (${TARGET_TRIPLE})...${NC}"
    swiftc \
        -module-name YmacPlayer \
        -parse-as-library \
        "${swift_opt_flags[@]}" \
        -sdk "$SDK_PATH" \
        -target "$TARGET_TRIPLE" \
        -default-isolation MainActor \
        -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
        YmacPlayer/Models/*.swift \
        YmacPlayer/System/*.swift \
        YmacPlayer/Controllers/*.swift \
        YmacPlayer/Views/*.swift \
        -o "${app_macos}/YmacPlayer"

    echo -e "${BLUE}  • Compiling YmacPlayerWidgetExtension (${TARGET_TRIPLE})...${NC}"
    swiftc \
        -module-name YmacPlayerWidgetExtension \
        -parse-as-library \
        -application-extension \
        "${swift_opt_flags[@]}" \
        -sdk "$SDK_PATH" \
        -target "$TARGET_TRIPLE" \
        -Xlinker -e -Xlinker _NSExtensionMain \
        -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
        -Xlinker -rpath -Xlinker @executable_path/../../../../Frameworks \
        YmacPlayer/Models/*.swift \
        YmacPlayer/Controllers/YmacIntents.swift \
        YmacPlayerWidget/YmacPlayerWidget.swift \
        YmacPlayerWidget/YmacPlayerWidgetBundle.swift \
        -o "${widget_macos}/YmacPlayerWidgetExtension"

    echo -e "${BLUE}  • Assembling app bundle & resources...${NC}"
    local iconset_dir="${clt_build_dir}/AppIcon.iconset"
    if command -v iconutil &>/dev/null && ls YmacPlayer/Assets.xcassets/AppIcon.appiconset/icon_*.png &>/dev/null; then
        mkdir -p "$iconset_dir"
        cp -X YmacPlayer/Assets.xcassets/AppIcon.appiconset/icon_*.png "$iconset_dir/"
        iconutil -c icns "$iconset_dir" -o "${app_resources}/AppIcon.icns"
        rm -rf "$iconset_dir"
    fi

    if [ -f "scripts/prebuilt_resources/app/Assets.car" ]; then
        cp -X "scripts/prebuilt_resources/app/Assets.car" "${app_resources}/Assets.car"
    fi
    if [ -d "scripts/prebuilt_resources/app/Metadata.appintents" ]; then
        cp -RX "scripts/prebuilt_resources/app/Metadata.appintents" "${app_resources}/Metadata.appintents"
    fi
    if [ -d "scripts/prebuilt_resources/widget/Metadata.appintents" ]; then
        cp -RX "scripts/prebuilt_resources/widget/Metadata.appintents" "${widget_resources}/Metadata.appintents"
    fi

    if [ -f "README.md" ]; then
        cp -X "README.md" "${app_resources}/README.md"
        cp -X "README.md" "${widget_resources}/README.md"
    fi

    printf 'APPL????' > "${app_contents}/PkgInfo"

    cat > "${app_contents}/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleDisplayName</key>
	<string>Ymac</string>
	<key>CFBundleExecutable</key>
	<string>YmacPlayer</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIconName</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>com.valentin.YmacPlayer</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>YmacPlayer</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.1.0</string>
	<key>CFBundleSupportedPlatforms</key>
	<array>
		<string>MacOSX</string>
	</array>
	<key>CFBundleVersion</key>
	<string>2</string>
	<key>DTPlatformName</key>
	<string>macosx</string>
	<key>DTPlatformVersion</key>
	<string>26.5</string>
	<key>DTSDKName</key>
	<string>macosx26.5</string>
	<key>DTXcode</key>
	<string>2600</string>
	<key>LSApplicationCategoryType</key>
	<string>public.app-category.music</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
EOF
    plutil -replace CFBundleShortVersionString -string "$VERSION" "${app_contents}/Info.plist"
    plutil -lint "${app_contents}/Info.plist" >/dev/null

    cat > "${widget_contents}/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleDisplayName</key>
	<string>YmacPlayerWidget</string>
	<key>CFBundleExecutable</key>
	<string>YmacPlayerWidgetExtension</string>
	<key>CFBundleIdentifier</key>
	<string>com.valentin.YmacPlayer.YmacPlayerWidget</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>YmacPlayerWidgetExtension</string>
	<key>CFBundlePackageType</key>
	<string>XPC!</string>
	<key>CFBundleShortVersionString</key>
	<string>1.1.0</string>
	<key>CFBundleSupportedPlatforms</key>
	<array>
		<string>MacOSX</string>
	</array>
	<key>CFBundleVersion</key>
	<string>2</string>
	<key>DTPlatformName</key>
	<string>macosx</string>
	<key>DTPlatformVersion</key>
	<string>26.5</string>
	<key>DTSDKName</key>
	<string>macosx26.5</string>
	<key>DTXcode</key>
	<string>2600</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>NSExtension</key>
	<dict>
		<key>NSExtensionPointIdentifier</key>
		<string>com.apple.widgetkit-extension</string>
	</dict>
</dict>
</plist>
EOF
    plutil -replace CFBundleShortVersionString -string "$VERSION" "${widget_contents}/Info.plist"
    plutil -lint "${widget_contents}/Info.plist" >/dev/null

    find "$APP_PATH" -exec xattr -d com.apple.FinderInfo {} + 2>/dev/null || true
    find "$APP_PATH" -exec xattr -d com.apple.ResourceFork {} + 2>/dev/null || true
    xattr -rc "$APP_PATH" 2>/dev/null || true

    local sign_identity
    sign_identity="$(resolve_sign_identity)"
    echo -e "${BLUE}🔏 Signing bundle (${sign_identity}) with entitlements...${NC}"
    sign_bundle "$APP_PATH" "$sign_identity"
}

# 4. Build Release
echo -e "${BLUE}🔨 Building ${SCHEME} (${CONFIGURATION})...${NC}"

if [ "$USE_XCODE" -eq 1 ]; then
    build_with_xcode
else
    build_with_clt
fi

echo -e "${GREEN}✓ Build succeeded:${NC} ${APP_PATH}"

# 5. Create ZIP Archive
ZIP_NAME="YmacPlayer-${VERSION}.zip"
ZIP_PATH="${OUTPUT_DIR}/${ZIP_NAME}"
echo -e "\n${BLUE}📦 Creating ZIP archive: ${ZIP_NAME}...${NC}"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
echo -e "${GREEN}✓ Created:${NC} ${ZIP_PATH} ($(du -sh "$ZIP_PATH" | cut -f1))"

# 6. Create DMG Image
DMG_NAME="YmacPlayer-${VERSION}.dmg"
DMG_PATH="${OUTPUT_DIR}/${DMG_NAME}"
DMG_STAGING="/tmp/YmacPlayer-dmg-staging"

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
