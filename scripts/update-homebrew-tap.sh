#!/bin/bash
# update-homebrew-tap.sh — Update the Homebrew tap formula after a new vibe-beeper release.
#
# Usage: ./scripts/update-homebrew-tap.sh [version]
#
# If version is omitted, the latest GitHub release tag is used.
# Requires: gh CLI (authenticated), curl, shasum

set -euo pipefail

REPO="zqxsober/vibe-beeper"
TAP_REPO="vecartier/homebrew-tap"
CASK_PATH="Casks/cc-beeper.rb"

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    VERSION=$(gh release view --repo "$REPO" --json tagName -q '.tagName' | sed 's/^v//')
    echo "Latest release: v$VERSION"
fi

DMG_URL="https://github.com/$REPO/releases/download/v${VERSION}/vibe-beeper.dmg"
echo "Downloading vibe-beeper.dmg for v$VERSION..."

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

curl -fsSL "$DMG_URL" -o "$TMPDIR/vibe-beeper.dmg"
SHA=$(shasum -a 256 "$TMPDIR/vibe-beeper.dmg" | awk '{print $1}')
echo "SHA256: $SHA"

echo "Updating Homebrew tap..."
gh repo clone "$TAP_REPO" "$TMPDIR/tap" -- -q
cd "$TMPDIR/tap"

sed -i '' "s/version \".*\"/version \"$VERSION\"/" "$CASK_PATH"
sed -i '' "s/sha256 \".*\"/sha256 \"$SHA\"/" "$CASK_PATH"

git add "$CASK_PATH"
git commit -m "Update vibe-beeper to v$VERSION"
git push origin main

echo "Done. Homebrew tap updated to v$VERSION."
