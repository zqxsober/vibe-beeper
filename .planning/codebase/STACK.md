# Technology Stack

**Analysis Date:** 2026-03-19

## Languages

**Primary:**
- Swift 5.10+ - Entire application codebase
- Python 3 - Hook system and setup scripts

**Secondary:**
- Shell (Bash) - Build and installation automation

## Runtime

**Environment:**
- macOS 14+ (Sonoma and later)
- Apple Silicon (arm64) and Intel (x86_64) support

**Package Manager:**
- Swift Package Manager (SPM)
- Python 3 (system or user-installed)

## Frameworks

**Core:**
- SwiftUI - Entire UI (window, menu bar, views, animations)
- AppKit - Window configuration, process management, workspace integration
- Foundation - File I/O, JSON parsing, process management, notifications

**System Integration:**
- Dispatch (`DispatchSource`) - File system monitoring for events.jsonl
- Darwin/POSIX - Kill signals for process checking, fcntl for file locking

**Build/Dev:**
- Swift compiler (included with Xcode CLI Tools)
- Custom shell scripts for app bundling and DMG creation

## Key Dependencies

**Critical:**
- **No external dependencies** - Claumagotchi uses only Swift stdlib and system frameworks
- All JSON parsing uses Foundation's JSONSerialization
- All file I/O uses FileManager and Foundation
- All UI rendering uses SwiftUI primitives (no third-party UI libraries)

**System Requirements:**
- Xcode Command Line Tools (for swift compiler)
- iconutil (macOS native, for icon conversion)
- sips (macOS native, for image resizing)

## Configuration

**Environment:**
- App stores user preferences in `UserDefaults` (macOS standard)
- IPC communication via JSON files in `~/.claude/claumagotchi/`
- Hook configuration stored in `~/.claude/settings.json` (Claude Code settings)

**Build:**
- `Package.swift` - Defines executable target, platform (macOS 14+), Swift version
- `build.sh` - Compiles with `swift build -c release`, bundles as `.app`
- `create-dmg.sh` - Packages built app into distributable DMG

**Installation:**
- `setup.py` - Registers hook with Claude Code, creates IPC directory
- `uninstall.py` - Removes hooks and cleans up temp files
- `Makefile` - Convenience targets for build/install/uninstall/dmg

## Platform Requirements

**Development:**
- macOS 14+
- Swift 5.10+ (Xcode or Command Line Tools)
- Python 3 (for setup.py and hooks)
- Bash (for build scripts)

**Production:**
- macOS 14+
- Claude Code CLI installed
- App runs as menu bar accessory (LSUIElement = true)
- Can run on startup via LaunchAgent integration

## App Delivery

**Bundle:**
- Executable: `Claumagotchi.app/Contents/MacOS/Claumagotchi`
- Icon: `Claumagotchi.app/Contents/Resources/AppIcon.icns` (generated from icon.png)
- Metadata: `Claumagotchi.app/Contents/Info.plist` (generated during build)
- Bundle ID: `com.claumagotchi.app`

**Distribution:**
- DMG image created via create-dmg.sh
- Auto-update mechanism via LaunchAgent (com.claumagotchi.autoupdate.plist)
- GitHub Releases distribution

---

*Stack analysis: 2026-03-19*
