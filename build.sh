#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$PROJECT_DIR/ManusIsland"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/Manus Island.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "🏝️  Building Manus Island v8..."
echo ""

# Clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Source files
SOURCES=(
    "$SRC_DIR/main.swift"
    "$SRC_DIR/ManusAPIClient.swift"
    "$SRC_DIR/TaskStore.swift"
    "$SRC_DIR/IslandView.swift"
    "$SRC_DIR/IslandWindowController.swift"
    "$SRC_DIR/SettingsView.swift"
    "$SRC_DIR/AppDelegate.swift"
    "$SRC_DIR/ScreenTimeTracker.swift"
    "$SRC_DIR/VoiceInputManager.swift"
)

echo "📦 Compiling Swift sources..."
swiftc \
    -o "$MACOS_DIR/ManusIsland" \
    -target arm64-apple-macosx14.0 \
    -sdk "$(xcrun --sdk macosx --show-sdk-path)" \
    -framework AppKit \
    -framework SwiftUI \
    -framework Combine \
    -framework Carbon \
    -framework UserNotifications \
    -framework AVFoundation \
    -framework Speech \
    -framework CoreSpotlight \
    -framework UniformTypeIdentifiers \
    -swift-version 5 \
    -O \
    "${SOURCES[@]}"

echo "📋 Copying resources..."
cp "$SRC_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

# Completion sound removed — uses system notification sounds only

# Copy app icon if it exists
if [ -f "$SRC_DIR/Resources/AppIcon.icns" ]; then
    cp "$SRC_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
    echo "🎨 App icon copied"
fi

# Copy menu bar icon if it exists
if [ -f "$SRC_DIR/Resources/menubar_icon.png" ]; then
    cp "$SRC_DIR/Resources/menubar_icon.png" "$RESOURCES_DIR/menubar_icon.png"
    cp "$SRC_DIR/Resources/menubar_icon@2x.png" "$RESOURCES_DIR/menubar_icon@2x.png" 2>/dev/null || true
    echo "🖼️  Menu bar icon copied"
fi

# Copy Manus logo assets
for logo_file in "$SRC_DIR/Resources/manus_logo_"*.png; do
    if [ -f "$logo_file" ]; then
        cp "$logo_file" "$RESOURCES_DIR/"
    fi
done
echo "🫰 Manus logo assets copied"

# Create PkgInfo
echo -n "APPL????" > "$CONTENTS_DIR/PkgInfo"

echo ""
echo "✅ Build successful!"
echo "📍 App location: $APP_BUNDLE"
echo ""
echo "To run: open \"$APP_BUNDLE\""
echo ""
