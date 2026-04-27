#!/bin/bash
set -e

# Code signing identity.
# Default is ad-hoc (-) for local development.
# Set SIGNING_IDENTITY='Developer ID Application: Name (TEAMID)' for distribution builds.
# Example: SIGNING_IDENTITY='Developer ID Application: Jane Smith (ABCDE12345)' make dmg
SIGNING_IDENTITY="${SIGNING_IDENTITY:--}"

cd "$(dirname "$0")"

APP_NAME="vibe-beeper"
OLD_APP_NAME="CC-Beeper"
APP_BUNDLE="${APP_NAME}.app"
OLD_APP_BUNDLE="${OLD_APP_NAME}.app"
BINARY=".build/release/${APP_NAME}"
APP_DIR="${APP_BUNDLE}/Contents/MacOS"
RESOURCES_DIR="${APP_BUNDLE}/Contents/Resources"

echo "Building ${APP_NAME}..."
swift build -c release 2>&1

echo "Creating app bundle..."
# Remove the legacy local bundle too so rename builds do not leave a stale app.
rm -rf "$APP_BUNDLE" "$OLD_APP_BUNDLE"
mkdir -p "$APP_DIR" "$RESOURCES_DIR"
cp "$BINARY" "$APP_DIR/"

# Copy shell image assets
cp Sources/shells/vibe-beeper-*.png "$RESOURCES_DIR/" 2>/dev/null

# Copy button image assets
cp Sources/buttons/*.png "$RESOURCES_DIR/" 2>/dev/null

# Copy font assets
cp Sources/fonts/*.ttf "$RESOURCES_DIR/" 2>/dev/null

# Copy cover image for onboarding
cp docs/cover.png "$RESOURCES_DIR/cover.png" 2>/dev/null

# Copy maintenance scripts used from Settings.
cp scripts/uninstall.py "$RESOURCES_DIR/uninstall.py"

# Generate app icon from icon.png (transparent, no background)
if [ -f "icon.png" ] && command -v iconutil &>/dev/null; then
    ICONSET="/tmp/cc-beeper-iconset.iconset"
    rm -rf "$ICONSET"
    mkdir -p "$ICONSET"
    for s in 16 32 64 128 256 512 1024; do
        sips -z $s $s icon.png --out "$ICONSET/tmp_${s}.png" &>/dev/null
    done
    cp "$ICONSET/tmp_16.png"   "$ICONSET/icon_16x16.png"
    cp "$ICONSET/tmp_32.png"   "$ICONSET/icon_16x16@2x.png"
    cp "$ICONSET/tmp_32.png"   "$ICONSET/icon_32x32.png"
    cp "$ICONSET/tmp_64.png"   "$ICONSET/icon_32x32@2x.png"
    cp "$ICONSET/tmp_128.png"  "$ICONSET/icon_128x128.png"
    cp "$ICONSET/tmp_256.png"  "$ICONSET/icon_128x128@2x.png"
    cp "$ICONSET/tmp_256.png"  "$ICONSET/icon_256x256.png"
    cp "$ICONSET/tmp_512.png"  "$ICONSET/icon_256x256@2x.png"
    cp "$ICONSET/tmp_512.png"  "$ICONSET/icon_512x512.png"
    cp "$ICONSET/tmp_1024.png" "$ICONSET/icon_512x512@2x.png"
    rm -f "$ICONSET"/tmp_*.png
    iconutil -c icns "$ICONSET" -o "$RESOURCES_DIR/AppIcon.icns"
    rm -rf "$ICONSET"
fi

cat > "${APP_BUNDLE}/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.zqxsober.vibe-beeper</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.4</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>ATSApplicationFontsPath</key>
    <string>.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>vibe-beeper needs microphone access to record your voice for transcription.</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>vibe-beeper uses on-device speech recognition to transcribe your voice.</string>
</dict>
</plist>
PLIST

echo "Built ${APP_BUNDLE}"

# Strip extended attributes (quarantine, etc.) from the bundle.
# Apple's notary service silently hangs on bundles containing com.apple.quarantine xattrs.
xattr -cr "$APP_BUNDLE"

# Hardened runtime + secure timestamp are required for notarization.
# Enable them only for Developer ID signing (not for ad-hoc "-" local builds).
if [ "$SIGNING_IDENTITY" = "-" ]; then
    codesign --force --deep --sign "$SIGNING_IDENTITY" --entitlements vibe-beeper.entitlements "$APP_BUNDLE"
else
    codesign --force --deep --sign "$SIGNING_IDENTITY" \
        --entitlements vibe-beeper.entitlements \
        --options runtime \
        --timestamp \
        "$APP_BUNDLE"
fi
echo "Signed ${APP_BUNDLE} (identity: $SIGNING_IDENTITY)"

# Install the fresh build into /Applications so the running copy never drifts
# from the source tree. Skip with SKIP_INSTALL=1 for CI / DMG builds.
if [ "${SKIP_INSTALL:-0}" != "1" ]; then
    echo "Installing to /Applications..."
    osascript -e "tell application \"${APP_NAME}\" to quit" >/dev/null 2>&1 || true
    pkill -f "/Applications/${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" >/dev/null 2>&1 || true
    rm -rf "/Applications/${APP_BUNDLE}"
    rm -rf "/Applications/${OLD_APP_BUNDLE}"
    cp -R "$APP_BUNDLE" /Applications/
    echo "Installed /Applications/${APP_BUNDLE}"
fi
