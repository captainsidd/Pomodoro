#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Pomodoro"
BUILD_DIR="$SCRIPT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "🍅 Building Pomodoro..."

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS" "$RESOURCES"

# Compile Swift source
swiftc \
    "$SCRIPT_DIR/Sources/main.swift" \
    -o "$MACOS/$APP_NAME" \
    -framework Cocoa \
    -framework SwiftUI \
    -framework UserNotifications \
    -framework AVFoundation \
    -target arm64-apple-macos13 \
    -O

# Copy Info.plist and icon
cp "$SCRIPT_DIR/Info.plist" "$CONTENTS/Info.plist"
cp "$SCRIPT_DIR/Resources/AppIcon.icns" "$RESOURCES/AppIcon.icns"

echo "✅ Built successfully: $APP_BUNDLE"
echo ""
echo "To run:  open $APP_BUNDLE"
echo "To install: cp -R $APP_BUNDLE /Applications/"
