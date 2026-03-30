---
phase: 37-permission-spectrum
plan: 02
subsystem: UI / Permission Spectrum
tags: [swiftui, menubarextra, permission-preset, yolo, toast, rabbit]
dependency_graph:
  requires: [37-01]
  provides: [PERM-01, PERM-03, PERM-04, PERM-05, YOLO-02]
  affects: [Sources/App/CCBeeperApp.swift, Sources/App/MenuBarPopoverView.swift, Sources/Monitor/ClaudeMonitor.swift, Sources/Widget/ScreenContentView.swift, Sources/Widget/ScreenView.swift]
tech_stack:
  added: []
  patterns: [SwiftUI Picker(.inline), @Published didSet side-effect, ZStack overlay pattern]
key_files:
  created: []
  modified:
    - Sources/Monitor/ClaudeMonitor.swift
    - Sources/App/CCBeeperApp.swift
    - Sources/App/MenuBarPopoverView.swift
    - Sources/Widget/ScreenContentView.swift
    - Sources/Widget/ScreenView.swift
decisions:
  - "currentPreset (PermissionPreset) replaces autoAccept (Bool) as the source of truth for YOLO/permission mode"
  - "Preset toast (RESTART SESSION TO APPLY) fires from ClaudeMonitor.currentPreset.didSet, not from UI layer"
  - "PixelCharacterView checks isYolo before isGlitching — rabbit takes absolute priority over all other states"
metrics:
  duration: 4 minutes
  completed: 2026-03-30
  tasks_completed: 2
  tasks_total: 3
  files_modified: 5
---

# Phase 37 Plan 02: Permission Spectrum UI Summary

**One-liner:** Native MenuBarExtra preset picker (4 modes with em-dash descriptions), YOLO rabbit character, 5s toast on mode change — autoAccept fully replaced by currentPreset.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add currentPreset to ClaudeMonitor, replace autoAccept | a71b464 | Sources/Monitor/ClaudeMonitor.swift |
| 2 | MenuBarExtra preset picker, remove old YOLO controls, wire rabbit and toast | de84657 | Sources/App/CCBeeperApp.swift, Sources/App/MenuBarPopoverView.swift, Sources/Widget/ScreenContentView.swift, Sources/Widget/ScreenView.swift |

## Decisions Made

1. **currentPreset replaces autoAccept entirely** — `@Published var autoAccept: Bool` removed; `@Published var currentPreset: PermissionPreset = .cautious` is the new source of truth. Initialized from `PermissionPresetWriter.readCurrentPreset()` on launch.

2. **Toast fires from model layer (ClaudeMonitor), not UI** — The 5s "RESTART SESSION TO APPLY" timer lives in `currentPreset.didSet`. The UI simply observes `presetToastMessage`. This keeps the logic centralized and testable.

3. **Rabbit takes absolute priority in currentSprite** — The `isYolo` check comes before `isGlitching`. This means in YOLO mode, the rabbit always shows — even during error glitch animations. Per D-07: simple swap, no animation.

4. **Malformed settings.json disables the picker** — `isSettingsMalformed` is read at launch and drives `.disabled()` on the Picker plus an informational caption. No silent failure.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all data sources are wired. The permission preset picker reads from and writes to `~/.claude/settings.json` via `PermissionPresetWriter`. The toast, rabbit, and malformed state are all driven by live `@Published` properties.

## Checkpoint Task (Task 3)

Task 3 is a `checkpoint:human-verify` — pausing for human visual verification. The app has been built and copied to `/Applications/CC-Beeper.app`. See checkpoint message below for verification steps.

## Self-Check: PASSED

Files confirmed to exist:
- /Users/vcartier/Desktop/CC-Beeper/Sources/Monitor/ClaudeMonitor.swift — FOUND
- /Users/vcartier/Desktop/CC-Beeper/Sources/App/CCBeeperApp.swift — FOUND
- /Users/vcartier/Desktop/CC-Beeper/Sources/App/MenuBarPopoverView.swift — FOUND
- /Users/vcartier/Desktop/CC-Beeper/Sources/Widget/ScreenContentView.swift — FOUND
- /Users/vcartier/Desktop/CC-Beeper/Sources/Widget/ScreenView.swift — FOUND

Commits confirmed:
- a71b464: feat(37-02): add currentPreset to ClaudeMonitor, remove autoAccept — FOUND
- de84657: feat(37-02): wire permission preset picker in menu, remove YOLO controls, add toast and rabbit — FOUND

Build: `swift build` succeeded
Tests: 53 tests, 0 failures
