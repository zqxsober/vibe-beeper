#!/bin/bash
set -e

cd "$(dirname "$0")/.."

# Build the app first (skip the auto-install to /Applications — DMG builds
# should not stomp on the user's installed copy).
SKIP_INSTALL=1 ./build.sh

echo "Creating DMG with create-dmg..."

rm -f vibe-beeper.dmg

# Stage app in temp directory (create-dmg expects a source folder)
STAGING="/tmp/cc-beeper-dmg-staging"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R vibe-beeper.app "$STAGING/"

create-dmg \
    --volname "vibe-beeper" \
    --window-pos 200 120 \
    --window-size 660 400 \
    --icon-size 128 \
    --icon "vibe-beeper.app" 180 170 \
    --app-drop-link 480 170 \
    --hide-extension "vibe-beeper.app" \
    --no-internet-enable \
    vibe-beeper.dmg \
    "$STAGING"

rm -rf "$STAGING"

echo ""
echo "Created vibe-beeper.dmg"

# Notarize if profile provided
if [ -n "$NOTARY_PROFILE" ]; then
    echo ""
    echo "Submitting vibe-beeper.dmg for notarization (profile: $NOTARY_PROFILE)..."
    xcrun notarytool submit vibe-beeper.dmg \
        --keychain-profile "$NOTARY_PROFILE" \
        --wait
    xcrun stapler staple vibe-beeper.dmg
    xcrun stapler staple vibe-beeper.app
    echo "Notarization complete."
else
    echo ""
    echo "Skipped notarization (set NOTARY_PROFILE to enable)."
fi
