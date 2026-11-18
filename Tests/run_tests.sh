#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

SDK_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk"
if [ ! -d "$SDK_PATH" ]; then
    SDK_PATH="$(xcrun --show-sdk-path)"
fi

TARGET="arm64-apple-macosx14.0"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

echo "=== YmacPlayer Test Suite ==="
echo "SDK:    $SDK_PATH"
echo "Target: $TARGET"
echo ""

# Collect App sources (excluding @main YmacPlayerApp.swift for test binary)
APP_ALL_SOURCES=(
    YmacPlayer/Models/*.swift
    YmacPlayer/System/*.swift
    YmacPlayer/Controllers/*.swift
    YmacPlayer/Views/*.swift
)

APP_TEST_SOURCES=()
for f in YmacPlayer/Models/*.swift YmacPlayer/System/*.swift YmacPlayer/Controllers/*.swift YmacPlayer/Views/*.swift; do
    if [[ "$f" != *"YmacPlayerApp.swift" ]]; then
        APP_TEST_SOURCES+=("$f")
    fi
done

WIDGET_ALL_SOURCES=(
    YmacPlayer/Models/*.swift
    YmacPlayer/Controllers/YmacIntents.swift
    YmacPlayerWidget/YmacPlayerWidget.swift
    YmacPlayerWidget/YmacPlayerWidgetBundle.swift
)

WIDGET_TEST_SOURCES=(
    YmacPlayer/Models/*.swift
    YmacPlayer/Controllers/YmacIntents.swift
    YmacPlayerWidget/YmacPlayerWidget.swift
)

echo "[1/4] Typechecking YmacPlayer App target..."
swiftc -typecheck \
    -sdk "$SDK_PATH" \
    -target "$TARGET" \
    -default-isolation MainActor \
    "${APP_ALL_SOURCES[@]}"

echo "[2/4] Typechecking YmacPlayer Widget target..."
swiftc -typecheck \
    -sdk "$SDK_PATH" \
    -target "$TARGET" \
    "${WIDGET_ALL_SOURCES[@]}"

echo "[3/4] Compiling and running YmacPlayer App tests..."
swiftc \
    -sdk "$SDK_PATH" \
    -target "$TARGET" \
    -default-isolation MainActor \
    -DTEST_APP \
    "${APP_TEST_SOURCES[@]}" \
    Tests/YmacPlayerTests.swift \
    -o "$BUILD_DIR/YmacPlayerAppTests"
"$BUILD_DIR/YmacPlayerAppTests"

echo ""
echo "[4/4] Compiling and running YmacPlayer Widget tests..."
swiftc \
    -sdk "$SDK_PATH" \
    -target "$TARGET" \
    -DTEST_WIDGET \
    "${WIDGET_TEST_SOURCES[@]}" \
    Tests/YmacPlayerTests.swift \
    -o "$BUILD_DIR/YmacPlayerWidgetTests"
"$BUILD_DIR/YmacPlayerWidgetTests"

echo ""
echo "=== All YmacPlayer tests passed ==="
