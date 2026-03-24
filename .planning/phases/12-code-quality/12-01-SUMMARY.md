---
phase: 12-code-quality
plan: 01
subsystem: ui
tags: [swift, swiftui, macos, bundle, warnings, sendable]

# Dependency graph
requires: []
provides:
  - Bundle.main.resourcePath-only image loading (no hardcoded developer paths)
  - Package.swift excludes shells/, buttons/, shell.svg from SPM target
  - Zero-warning release build
  - Dead shell-*.png assets removed from Sources/shells/
affects: [13-voice-input, 14-distribution, 15-keychain]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Image loading via Bundle.main.resourcePath only — no fallback to source directory"
    - "Package.swift exclude list for non-Swift asset directories"
    - "Sendable closure safety via [weak self] + Task @MainActor pattern"

key-files:
  created: []
  modified:
    - Sources/ContentView.swift
    - Sources/ActionButton.swift
    - Package.swift
    - build.sh

key-decisions:
  - "Delete legacy shell-*.png files (9 files) — only beeper-*.png shells are active"
  - "Use [weak monitor] + Task @MainActor to resolve Sendable Timer closure warning"
  - "Package.swift exclude: shells/, buttons/, shell.svg to suppress 36 unhandled files warning"

patterns-established:
  - "Always use Bundle.main.resourcePath for runtime asset loading — never source directory paths"

requirements-completed: [CODE-01, CODE-02, CODE-03]

# Metrics
duration: 10min
completed: 2026-03-24
---

# Phase 12 Plan 01: Code Quality Summary

**Hardcoded developer paths removed, 9 dead shell assets deleted, and zero-warning release build achieved via Sendable-safe Timer closures and Package.swift exclusions**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-03-24T10:03:00Z
- **Completed:** 2026-03-24T10:13:55Z
- **Tasks:** 2
- **Files modified:** 4 (+ 9 deleted)

## Accomplishments
- Removed all `/Users/vcartier` fallback paths from `loadShellImage` and `loadButtonImage` — app now loads images from `Bundle.main.resourcePath` only, making it portable to any Mac
- Deleted 9 legacy `shell-*.png` files from `Sources/shells/` (only `beeper-*.png` active shells remain)
- Removed dead `shell-*.png` copy lines from `build.sh` (kept `beeper-*.png` line)
- Fixed Sendable warning: Timer closure now uses `[weak monitor]` + `Task { @MainActor in }` pattern
- Added `exclude:` list to `Package.swift` for `shells/`, `buttons/`, `shell.svg` — eliminates "36 unhandled files" build warning
- Build output: `Build complete!` with zero warnings

## Task Commits

Each task was committed atomically:

1. **Task 1: Remove hardcoded paths and delete dead assets** - `70ae890` (fix)
2. **Task 2: Fix compiler warnings and Package.swift resource handling** - `138cb51` (fix)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `Sources/ContentView.swift` - Removed hardcoded fallback path from `loadShellImage`; fixed Sendable Timer closure
- `Sources/ActionButton.swift` - Removed hardcoded fallback path from `loadButtonImage`
- `Package.swift` - Added `exclude: ["shells", "buttons", "shell.svg"]` to executable target
- `build.sh` - Removed `shell-*.png` copy lines; kept `beeper-*.png` only
- `Sources/shells/shell-{black,blue,green,mint,orange,pink,purple,white,yellow}.png` - Deleted (9 files)

## Decisions Made
- Delete legacy shell-*.png rather than keep as dead files — they were replaced by beeper-*.png in the v3 redesign
- Use `[weak monitor] + Task @MainActor` for Timer closure — correct Swift 6 Sendable pattern without changing the timer semantics
- Package.swift exclude list rather than `.process()` resources — assets are copied manually by build.sh, not embedded via SPM

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None — both fixes applied cleanly, build completed with zero warnings on first attempt.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Codebase is now portable to any Mac developer — no hardcoded paths
- Zero warnings provides a clean baseline for Phase 13 voice input work
- Dead assets cleaned up, reducing source tree noise

---
*Phase: 12-code-quality*
*Completed: 2026-03-24*

## Self-Check: PASSED

- ContentView.swift: FOUND
- ActionButton.swift: FOUND
- Package.swift: FOUND
- SUMMARY.md: FOUND
- Commit 70ae890: FOUND
- Commit 138cb51: FOUND
