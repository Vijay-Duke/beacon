#!/bin/bash
set -e

APP_NAME="Beacon"
APP_DIR="$HOME/Applications/$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"

echo "Building release..."
swift build -c release

echo "Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS"
mkdir -p "$CONTENTS/Resources"

cp .build/release/Beacon "$MACOS/$APP_NAME"
cp Sources/Beacon/Resources/AppIcon.icns "$CONTENTS/Resources/AppIcon.icns"

cat > "$CONTENTS/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Beacon</string>
    <key>CFBundleIdentifier</key>
    <string>com.beacon.app</string>
    <key>CFBundleName</key>
    <string>Beacon</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo ""
echo "Installed to: $APP_DIR"
echo "Open it with: open \"$APP_DIR\""
echo ""
echo "To launch at login: System Settings > General > Login Items > add Beacon"
