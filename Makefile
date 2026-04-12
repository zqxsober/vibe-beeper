.PHONY: build install uninstall clean dmg release update autoupdate no-autoupdate

build:
	@./build.sh

install: build
	@echo ""
	@echo "Setting up Claude Code hooks..."
	@python3 scripts/setup.py
	@echo "Launching CC-Beeper..."
	@open /Applications/CC-Beeper.app

uninstall: no-autoupdate
	@echo "Uninstalling CC-Beeper..."
	@python3 scripts/uninstall.py

clean:
	@rm -rf .build CC-Beeper.app CC-Beeper.dmg
	@echo "Cleaned build artifacts"

dmg:
	@./scripts/create-dmg.sh

release:
	@VERSION=$$(grep 'CFBundleShortVersionString' build.sh -A1 | grep '<string>' | sed 's/.*<string>//;s/<.*//' ) && \
	echo "==> Building + notarizing v$$VERSION..." && \
	SIGNING_IDENTITY='Developer ID Application: VICTOR EMMANUEL CARTIER (BMT85YWFD9)' \
	NOTARY_PROFILE='CC-Beeper' ./scripts/create-dmg.sh && \
	echo "==> Tagging v$$VERSION..." && \
	git tag -f "v$$VERSION" HEAD && \
	git push origin main && \
	git push origin "v$$VERSION" --force && \
	echo "==> Waiting for CI..." && \
	sleep 5 && \
	gh run watch $$(gh run list --repo vecartier/cc-beeper --limit 1 --json databaseId --jq '.[0].databaseId') --repo vecartier/cc-beeper --exit-status && \
	echo "==> Uploading notarized DMG..." && \
	gh release upload "v$$VERSION" CC-Beeper.dmg --repo vecartier/cc-beeper --clobber && \
	echo "==> Updating Homebrew tap..." && \
	./scripts/update-homebrew-tap.sh "$$VERSION" && \
	echo "==> Done. v$$VERSION released."

update:
	@./scripts/update.sh

autoupdate:
	# NOTE: plist file retains legacy name com.cc-beeper.autoupdate.plist — rename not required for functionality
	@REPO="$$(cd "$(CURDIR)" && pwd)" && \
	sed "s|__REPO_PATH__|$$REPO|g" scripts/com.cc-beeper.autoupdate.plist \
		> ~/Library/LaunchAgents/com.cc-beeper.autoupdate.plist && \
	launchctl bootout gui/$$(id -u) ~/Library/LaunchAgents/com.cc-beeper.autoupdate.plist 2>/dev/null || true && \
	launchctl bootstrap gui/$$(id -u) ~/Library/LaunchAgents/com.cc-beeper.autoupdate.plist && \
	echo "Auto-update enabled — checks every 6 hours."

no-autoupdate:
	@launchctl bootout gui/$$(id -u) ~/Library/LaunchAgents/com.cc-beeper.autoupdate.plist 2>/dev/null || true
	@rm -f ~/Library/LaunchAgents/com.cc-beeper.autoupdate.plist
	@echo "Auto-update disabled."
