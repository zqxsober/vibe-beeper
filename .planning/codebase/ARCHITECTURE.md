# Architecture

## Overview
Claumagotchi is a macOS menu bar + floating window companion for Claude Code. It monitors Claude sessions via file-based IPC, displays state as an animated Tamagotchi character, and handles permission requests.

## Architectural Pattern
**Observer / Event-Driven** — a Python hook writes events to a JSONL file, and the Swift app watches that file for changes using GCD file system events.

## Layers

### 1. Hook Layer (Python)
- `hooks/claumagotchi-hook.py` — Claude Code hook script
- Receives Claude Code lifecycle events via stdin JSON
- Writes events to `~/.claude/claumagotchi/events.jsonl`
- Handles permission requests: writes pending, polls for response, returns decision to Claude Code
- Manages session tracking in `sessions.json`
- Auto-launches the app on `SessionStart` if not running

### 2. IPC Layer (File System)
- Directory: `~/.claude/claumagotchi/` (0700 permissions)
- `events.jsonl` — append-only event stream (truncated at 50KB)
- `pending.json` — current permission request details
- `response.json` — user's allow/deny decision
- `sessions.json` — active session tracking with timestamps
- `claumagotchi.pid` — single-instance enforcement
- All writes use symlink-safe atomic operations (`safe_write`, `safe_append`)

### 3. Monitor Layer (Swift)
- `Sources/ClaudeMonitor.swift` — `ObservableObject` that owns all state
- Watches `events.jsonl` via `DispatchSource.makeFileSystemObjectSource` (kqueue)
- Maintains per-session state map (`sessionStates: [String: ClaudeState]`)
- Derives aggregate state: `needsYou > thinking > finished`
- Handles permission responses by writing `response.json`
- Rehydrates sessions from `sessions.json` on launch

### 4. UI Layer (SwiftUI)
- `Sources/ClaumagotchiApp.swift` — App entry point with `Window` + `MenuBarExtra`
- `Sources/ContentView.swift` — Tamagotchi shell (egg shape, buttons, noise texture)
- `Sources/ScreenView.swift` — LCD screen with pixel character, status icons, labels
- `Sources/ThemeManager.swift` — 9 color themes with dark mode support

## Data Flow

```
Claude Code session
  → hook receives event via stdin
  → hook appends to events.jsonl (or writes pending.json for permissions)
  → Swift app detects file change via kqueue
  → ClaudeMonitor.processEvent() updates state
  → SwiftUI reacts to @Published properties
  → User sees character animation change / permission prompt
  → User taps Allow/Deny → response.json written
  → Hook reads response, returns decision to Claude Code
```

## Key Abstractions

| Abstraction | Type | Purpose |
|---|---|---|
| `ClaudeState` | enum | Three states: thinking, finished, needsYou |
| `PendingPermission` | struct | Permission request metadata (id, tool, summary) |
| `ClaudeMonitor` | class | Central state machine + file watcher |
| `ThemeManager` | class | Color theme system with dark mode |
| `ShellTheme` | struct | Theme definition (shell gradients, accents, title colors) |

## Entry Points
- **App launch**: `ClaumagotchiApp` (@main) → creates `Window` + `MenuBarExtra`
- **Hook invocation**: `claumagotchi-hook.py` main() — called by Claude Code for each event
- **Setup**: `setup.py` — installs hook into `~/.claude/settings.json`
- **Build**: `build.sh` via `Makefile` — compiles Swift Package to `.app` bundle

## Single Instance
- `AppDelegate` writes PID to `~/.claude/claumagotchi/claumagotchi.pid` on launch
- Checks for existing PID on launch; quits silently if another instance is alive
- Hook also checks PID file before attempting to launch app

## Window Behavior
- Floating window (`.floating` level), always on top
- No title bar, transparent background, movable by background
- Joins all Spaces (`.canJoinAllSpaces`)
- Constrained to screen bounds on move
- `.accessory` activation policy (no dock icon)
