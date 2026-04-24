#!/bin/bash
set -e

cd "$(dirname "$0")/.."

# Fetch latest from remote
git fetch origin main --quiet

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" = "$REMOTE" ]; then
    echo "vibe-beeper is up to date."
    exit 0
fi

echo "Update available — pulling and rebuilding..."
git pull --quiet origin main

./build.sh

# Stop running instance if any
pkill -x vibe-beeper 2>/dev/null || true
sleep 0.5

# Install to /Applications
rm -rf /Applications/vibe-beeper.app
rm -rf /Applications/CC-Beeper.app
cp -R vibe-beeper.app /Applications/

# Relaunch
open /Applications/vibe-beeper.app

echo "vibe-beeper updated and relaunched."
