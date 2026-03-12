.PHONY: build install uninstall clean dmg update autoupdate no-autoupdate

build:
	@./build.sh

install: build
	@echo ""
	@echo "Setting up Claude Code hooks..."
	@python3 setup.py
	@echo ""
	@echo "Launching Claumagotchi..."
	@open Claumagotchi.app

uninstall: no-autoupdate
	@echo "Uninstalling Claumagotchi..."
	@python3 uninstall.py

clean:
	@rm -rf .build Claumagotchi.app Claumagotchi.dmg
	@echo "Cleaned build artifacts"

dmg: build
	@./create-dmg.sh

update:
	@./update.sh

autoupdate:
	@REPO="$$(cd "$(CURDIR)" && pwd)" && \
	sed "s|__REPO_PATH__|$$REPO|g" com.claumagotchi.autoupdate.plist \
		> ~/Library/LaunchAgents/com.claumagotchi.autoupdate.plist && \
	launchctl bootout gui/$$(id -u) ~/Library/LaunchAgents/com.claumagotchi.autoupdate.plist 2>/dev/null || true && \
	launchctl bootstrap gui/$$(id -u) ~/Library/LaunchAgents/com.claumagotchi.autoupdate.plist && \
	echo "Auto-update enabled — checks every 6 hours."

no-autoupdate:
	@launchctl bootout gui/$$(id -u) ~/Library/LaunchAgents/com.claumagotchi.autoupdate.plist 2>/dev/null || true
	@rm -f ~/Library/LaunchAgents/com.claumagotchi.autoupdate.plist
	@echo "Auto-update disabled."
