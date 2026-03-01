#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Pomodoro"
BUILD_DIR="$SCRIPT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_DIR="$BUILD_DIR/dmg"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"

# Step 1: Build the app
echo "🍅 Building $APP_NAME..."
"$SCRIPT_DIR/build.sh"

# Step 2: Prepare DMG staging folder
echo "📦 Packaging DMG..."
rm -rf "$DMG_DIR" "$DMG_PATH"
mkdir -p "$DMG_DIR"

# Copy app bundle into staging
cp -R "$APP_BUNDLE" "$DMG_DIR/"

# Create Applications symlink for drag-and-drop install
ln -s /Applications "$DMG_DIR/Applications"

# Step 3: Create the DMG
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

# Clean up staging
rm -rf "$DMG_DIR"

echo ""
echo "✅ DMG created: $DMG_PATH"
echo "   Double-click to open, then drag Pomodoro to Applications."
