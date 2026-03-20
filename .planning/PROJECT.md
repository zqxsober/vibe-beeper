# Claumagotchi

## What This Is

A Tamagotchi-style macOS desktop companion for Claude Code. It monitors active sessions via file-based IPC, displays state as an animated pixel character, and handles permission requests — all from a floating widget and menu bar icon.

## Core Value

Users can see what Claude is doing and respond to permission requests without leaving their workflow.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

- Session monitoring via JSONL file watcher (thinking/finished/needsYou states)
- Permission request handling (allow/deny via UI buttons and YOLO auto-accept mode)
- Animated pixel character reflecting session state (thinking, working, alert, happy, YOLO)
- Menu bar extra with status, actions, theme picker
- 9 color themes with dark mode support
- Sound alerts (ping for permissions, pop for done)
- Single-instance enforcement via PID file
- Auto-launch on Claude Code session start
- Auto-update via LaunchAgent
- DMG distribution
- ✓ YOLO mode distinct purple icon in menu bar — Phase 1
- ✓ Stable window lookup via identifier (not title) — Phase 1
- ✓ Default-deny on malformed/missing permission response — Phase 1
- ✓ Event JSON schema validation before processing — Phase 1
- ✓ Response freshness check (rejects stale/pre-written responses) — Phase 1
- ✓ File watcher auto-recovers from events.jsonl deletion/rename — Phase 2
- ✓ Sprite animation pauses when window is hidden — Phase 2
- ✓ DispatchWorkItem idle timer (no manual Timer objects) — Phase 2
- ✓ Noise texture cached as static NSImage (renders once) — Phase 2
- ✓ Throttled sessions.json reads (every 30s, not per-event) — Phase 2
- ✓ Unified hex color parsing (single implementation) — Phase 2
- ✓ Session count badge on LCD screen — Phase 3
- ✓ Idle/sleeping animation after 60s inactivity — Phase 3
- ✓ Full file path in permission prompts (not just basename) — Phase 3
- ✓ Global hotkeys Option+A/D with accessibility gate — Phase 3

### Active

<!-- Current scope. Building toward these. -->
- [ ] macOS Notification Center integration (with enable/disable toggle)

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- Actionable notification buttons — app is always floating, buttons in notifications are redundant
- Tests — valuable but separate milestone to avoid scope bloat
- Swift Concurrency migration (async/await) — refactor milestone, not a polish pass
- iOS/iPad companion — macOS only

## Context

- Swift 5.10+ / macOS 14+ / SwiftUI + AppKit
- Zero external dependencies — all system frameworks
- Python hook script bridges Claude Code events to the app via JSONL IPC
- Codebase is small (~1200 LOC Swift, ~300 LOC Python) — changes are low-risk
- Codebase map available at `.planning/codebase/`

## Constraints

- **Platform**: macOS 14+ only — uses AppKit, SwiftUI, kqueue file watching
- **Dependencies**: No third-party frameworks — keep it self-contained
- **Distribution**: Must remain buildable via `make build` with just Xcode CLI tools
- **IPC protocol**: Hook ↔ app communication via `~/.claude/claumagotchi/` files — changes must be backward compatible

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| File-based IPC over XPC/sockets | Simpler, works cross-process, debuggable | ✓ Good |
| No external dependencies | Minimal attack surface, easy distribution | ✓ Good |
| Global hotkey Option+A/D for permissions | Fastest response path without mouse | ✓ Good |
| Notifications for visibility, not actions | App is always floating — action buttons redundant | — Pending |
| Default-deny on malformed response | Security: fail closed, not open | ✓ Good |

---
*Last updated: 2026-03-20 after Phase 3 completion*
