---
phase: 38-visibility-spectrum
plan: 01
subsystem: ui
tags: [swift, swiftui, macos, tts, http, permissions, assets]

# Dependency graph
requires:
  - phase: 37-permission-spectrum
    provides: PermissionPreset enum, HTTP permission flow, ClaudeMonitor state machine
provides:
  - 10 beeper-small-{color}.png assets in Sources/shells/ for compact mode
  - ThemeManager.smallShellImageName computed property
  - TTS interrupt when PreToolUse event arrives during speech
  - PermissionRequest HTTP connection stored for deferred accept/deny response
affects:
  - 38-visibility-spectrum plan 02 (compact mode widget uses smallShellImageName and small shell assets)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "smallShellImageName mirrors shellImageName pattern with -small infix"
    - "TTS stopSpeaking called after session state set but before updateAggregateState"
    - "isPermissionPrompt uses || to match both Notification/permission_prompt and PermissionRequest"

key-files:
  created:
    - Sources/shells/beeper-small-black.png
    - Sources/shells/beeper-small-blue.png
    - Sources/shells/beeper-small-green.png
    - Sources/shells/beeper-small-mint.png
    - Sources/shells/beeper-small-orange.png
    - Sources/shells/beeper-small-pink.png
    - Sources/shells/beeper-small-purple.png
    - Sources/shells/beeper-small-red.png
    - Sources/shells/beeper-small-white.png
    - Sources/shells/beeper-small-yellow.png
  modified:
    - Sources/Theme/ThemeManager.swift
    - Sources/Monitor/ClaudeMonitor.swift
    - Sources/Monitor/HTTPHookServer.swift

key-decisions:
  - "smallShellImageName uses currentThemeId directly — all 10 color IDs match exactly between large and small shell sets"
  - "TTS stopSpeaking fires after sessionStates[sid] = .working so Combine sink resolves state correctly before TTS stops"
  - "isPermissionPrompt matches eventName == PermissionRequest to fix connection storage for PermissionRequest hook events"

patterns-established:
  - "Small shell assets follow beeper-small-{color}.png naming; large shells follow beeper-{color}.png"

requirements-completed: [D-04, D-05, TTS-FIX, PERM-BUG]

# Metrics
duration: 4min
completed: 2026-03-31
---

# Phase 38 Plan 01: Visibility Spectrum Foundation Summary

**10 small shell PNG assets added, ThemeManager.smallShellImageName wired, TTS interrupt on PreToolUse fixed, and PermissionRequest HTTP connection storage bug fixed**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-03-31T07:33:32Z
- **Completed:** 2026-03-31T07:37:54Z
- **Tasks:** 2
- **Files modified:** 13

## Accomplishments
- All 10 small shell PNGs copied from source (`/Users/vcartier/Desktop/Small shells/`) to `Sources/shells/` with correct naming convention
- `ThemeManager.smallShellImageName` computed property returns `beeper-small-{currentThemeId}.png` mirroring the existing `shellImageName` pattern
- TTS now stops immediately when a PreToolUse/PostToolUse event arrives while Claude is speaking the previous response recap
- `PermissionRequest` hook events now have their NWConnection stored in `permissionConnection`, enabling accept/deny buttons to send responses back to Claude Code

## Task Commits

Each task was committed atomically:

1. **Task 1: Copy small shell assets and add ThemeManager small shell support** - `8d54748` (feat)
2. **Task 2: Fix TTS interrupt on PreToolUse and HTTP permission connection for PermissionRequest** - `37f1ff5` (fix)

**Plan metadata:** pending (docs commit)

## Files Created/Modified
- `Sources/shells/beeper-small-{black,blue,green,mint,orange,pink,purple,red,white,yellow}.png` - Small shell PNG assets for compact mode widget (10 files created)
- `Sources/Theme/ThemeManager.swift` - Added `smallShellImageName` computed property
- `Sources/Monitor/ClaudeMonitor.swift` - TTS stop on pre_tool/post_tool events (after session state set, before aggregate update)
- `Sources/Monitor/HTTPHookServer.swift` - `isPermissionPrompt` now also matches `PermissionRequest` event name

## Decisions Made
- `smallShellImageName` uses `currentThemeId` directly since all 10 color IDs match between large and small shell sets — no mapping needed
- TTS `stopSpeaking()` is called after `sessionStates[sid] = .working` per RESEARCH.md Pitfall 4 so Combine sink resolves state correctly
- `isPermissionPrompt` uses `||` operator to add `PermissionRequest` alongside existing Notification/permission_prompt check — minimal change, no refactor

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All assets and code foundations ready for Plan 02 (compact mode widget)
- `smallShellImageName` provides the lookup Plan 02 needs to render the correct shell image at small size
- Both bug fixes (TTS-FIX, PERM-BUG) are live — daily use improves immediately

---
*Phase: 38-visibility-spectrum*
*Completed: 2026-03-31*

## Self-Check: PASSED

- All 10 beeper-small-*.png files exist in Sources/shells/
- ThemeManager.smallShellImageName property confirmed
- ClaudeMonitor.swift stopSpeaking call confirmed in pre_tool branch
- HTTPHookServer.swift PermissionRequest connection fix confirmed
- SUMMARY.md exists
- Commits 8d54748 and 37f1ff5 verified in git log
