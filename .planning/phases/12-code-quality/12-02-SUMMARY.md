---
phase: 12-code-quality
plan: 02
subsystem: ui
tags: [swift, swiftui, macos, architecture, refactoring, single-responsibility]

# Dependency graph
requires:
  - 12-01
provides:
  - BuzzService class owning all vibration/buzz logic
  - EggIcon and EggIconState extracted into dedicated file
  - WindowConfigurator extracted into dedicated file
  - Single-responsibility file structure across Sources/
affects: [13-voice-input, 14-distribution]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "BuzzService delegates vibration — ContentView passes vibrationEnabled/soundEnabled as params"
    - "One primary type per file — file name matches type name"
    - "@MainActor final class for service objects with timer state"

key-files:
  created:
    - Sources/BuzzService.swift
    - Sources/EggIcon.swift
    - Sources/WindowConfigurator.swift
  modified:
    - Sources/ContentView.swift
    - Sources/ClaumagotchiApp.swift

key-decisions:
  - "BuzzService takes vibrationEnabled/soundEnabled as parameters — no direct ClaudeMonitor reference, keeps dependency one-directional"
  - "Leave ScreenView, ScreenContentView, NoiseView as-is — their helper types are private/tightly coupled and have no independent consumers"
  - "AppDelegate colocated with @main ClaumagotchiApp — acceptable exception to one-type-per-file rule (app lifecycle coupling)"

# Metrics
duration: 3min
completed: 2026-03-24
---

# Phase 12 Plan 02: Code Quality Summary

**Vibration logic extracted into BuzzService, EggIcon and WindowConfigurator split into dedicated files — each Swift file now has exactly one primary type**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-24T10:16:09Z
- **Completed:** 2026-03-24T10:18:38Z
- **Tasks:** 2
- **Files modified:** 2 (+ 3 created)

## Accomplishments

- Created `Sources/BuzzService.swift` — dedicated `@MainActor final class BuzzService` with all vibration logic (handleStateChange, vibrate, playBeeps, reminderTimer)
- `ContentView` delegates to `buzzService.handleStateChange(newState, vibrationEnabled:, soundEnabled:)` — single call, no inline buzz logic
- Removed from ContentView: `lastVibrateState`, `reminderTimer`, `vibrate()`, `playBeeps()` — 69 lines removed from the view
- Created `Sources/EggIcon.swift` with `EggIconState` enum and `EggIcon` enum extracted from ClaumagotchiApp.swift
- Created `Sources/WindowConfigurator.swift` with `WindowConfigurator` struct and `constrainToScreen` function extracted from ClaumagotchiApp.swift
- `ClaumagotchiApp.swift` reduced from 277 to 179 lines — now contains only `ClaumagotchiApp` App struct and `AppDelegate` class
- `swift build -c release` and `bash build.sh` both pass with zero warnings or errors

## Task Commits

Each task was committed atomically:

1. **Task 1: Extract BuzzService from ContentView** - `eb63c12` (feat)
2. **Task 2: Split multi-type files into one-type-per-file** - `57ce01f` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `Sources/BuzzService.swift` — Created: BuzzService class with all vibration/buzz logic
- `Sources/EggIcon.swift` — Created: EggIconState + EggIcon enums
- `Sources/WindowConfigurator.swift` — Created: WindowConfigurator struct + constrainToScreen func
- `Sources/ContentView.swift` — Removed buzz state/logic, added buzzService property + delegation call
- `Sources/ClaumagotchiApp.swift` — Removed EggIconState, EggIcon, WindowConfigurator, constrainToScreen

## Decisions Made

- BuzzService takes `vibrationEnabled` and `soundEnabled` as parameters rather than holding a `ClaudeMonitor` reference — keeps the dependency one-directional (ContentView owns the monitor reference)
- `ScreenView.swift`, `ScreenContentView.swift`, `NoiseView.swift` left as-is — helper types (LCDIcon, PixelCharacterView, Sprites, MarqueeText, SeededRNG) are tightly coupled private helpers with no independent consumers
- `AppDelegate` remains colocated with `@main ClaumagotchiApp` — app lifecycle coupling makes this an acceptable exception to the one-type-per-file rule

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None — all extractions applied cleanly, build completed with zero warnings on first attempt.

## User Setup Required

None.

## Next Phase Readiness

- Clean single-responsibility file structure ready for Phase 13 voice input work
- BuzzService is independently testable — dependency injection via parameters, no global state
- File structure matches Swift naming conventions throughout

---
*Phase: 12-code-quality*
*Completed: 2026-03-24*

## Self-Check: PASSED

- Sources/BuzzService.swift: FOUND
- Sources/EggIcon.swift: FOUND
- Sources/WindowConfigurator.swift: FOUND
- Sources/ContentView.swift: FOUND
- Sources/ClaumagotchiApp.swift: FOUND
- .planning/phases/12-code-quality/12-02-SUMMARY.md: FOUND
- Commit eb63c12: FOUND
- Commit 57ce01f: FOUND
