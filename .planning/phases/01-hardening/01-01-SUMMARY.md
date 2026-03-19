---
phase: 01-hardening
plan: 01
subsystem: ui
tags: [swiftui, appkit, menu-bar, icon, security, event-validation]

# Dependency graph
requires: []
provides:
  - EggIconState enum with .normal/.attention/.yolo cases
  - Three-state menu bar icon (black/orange/purple)
  - Identifier-based window lookup via window.identifier?.rawValue == "main"
  - processEvent guard validating sid (String) and ts (Int) fields
affects: [02-reliability, 03-ux, 04-notifications]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "EggIconState enum drives menu bar icon rendering — add new states here"
    - "Window lookup via identifier?.rawValue == \"main\" not window.title"
    - "processEvent guard validates required fields before processing"

key-files:
  created: []
  modified:
    - Sources/ClaumagotchiApp.swift
    - Sources/ClaudeMonitor.swift

key-decisions:
  - "EggIcon.image() takes EggIconState not Bool — extensible for future states"
  - "isTemplate = true only for .normal so orange/purple show color in menu bar"
  - "yoloIconState computed property lives in ClaudeMonitor, not in the view layer"
  - "Schema validation uses 'is String' / 'is Int' type checks inside the existing guard"

patterns-established:
  - "Icon state derived from monitor properties via computed property, not passed as raw Bool"
  - "Window lookup stable via SwiftUI Window(id:) identifier, not mutable title string"

requirements-completed: [BUG-01, BUG-02, SEC-02]

# Metrics
duration: 6min
completed: 2026-03-19
---

# Phase 01 Plan 01: BUG-01/BUG-02/SEC-02 Hardening Summary

**Three-state menu bar icon (normal/orange/purple) with stable identifier-based window lookup and processEvent schema validation rejecting malformed events**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-19T14:44:09Z
- **Completed:** 2026-03-19T14:49:51Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments
- Added EggIconState enum (.normal, .attention, .yolo) and refactored EggIcon to show purple for YOLO mode, orange for needsYou, and black template for normal
- Replaced fragile window title string lookup with stable identifier-based lookup (window.identifier?.rawValue == "main") in both toggleMainWindow() and showMainWindow()
- Added guard checks for event["sid"] is String and event["ts"] is Int in processEvent, silently rejecting malformed events before any state processing

## Task Commits

Each task was committed atomically:

1. **Task 1: Add EggIconState enum and refactor EggIcon for three-state menu bar icon** - `bd8d77e` (feat)
2. **Task 2: Replace window title lookup with identifier-based lookup** - `000a22f` (fix)
3. **Task 3: Add event schema validation guards in processEvent** - `ba4d026` (fix)

## Files Created/Modified
- `Sources/ClaumagotchiApp.swift` - Added EggIconState enum, refactored EggIcon.image(state:), updated MenuBarExtra label and both window lookup functions
- `Sources/ClaudeMonitor.swift` - Added yoloIconState computed property, added sid/ts guards in processEvent

## Decisions Made
- EggIcon.image() signature changed to accept EggIconState instead of Bool — more extensible and explicit
- isTemplate is set only for .normal state so color variants (orange, purple) render correctly in the menu bar
- yoloIconState computed property placed in ClaudeMonitor (not the view) so it can be tested independently
- Schema validation added to existing guard rather than a separate guard block — minimal diff, consistent error path

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- BUG-01, BUG-02, SEC-02 resolved — menu bar icon, window management, and event validation all hardened
- Phase 01-02 (REL-01, SEC-01, BUG-03) can proceed

## Self-Check: PASSED

All files present and all commits verified on disk.

---
*Phase: 01-hardening*
*Completed: 2026-03-19*
