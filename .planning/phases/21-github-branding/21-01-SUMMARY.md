---
phase: 21-github-branding
plan: "01"
subsystem: menu-bar-icon
tags: [icon, beeper, branding, appkit, nsbezierpath]
dependency_graph:
  requires: []
  provides: [BeeperIcon, BeeperIconState]
  affects: [Sources/CCBeeperApp.swift, Sources/ClaudeMonitor.swift]
tech_stack:
  added: []
  patterns: [NSBezierPath programmatic icon, isTemplate for dark/light adaptation]
key_files:
  created:
    - Sources/BeeperIcon.swift
  modified:
    - Sources/CCBeeperApp.swift
    - Sources/ClaudeMonitor.swift
  deleted:
    - Sources/EggIcon.swift
decisions:
  - "Punched screen and buttons via NSGraphicsContext .copy + NSColor.clear rather than subtracting paths — matches existing EggIcon technique"
  - "Three button dots placed vertically on right side of body for legibility at 18x18"
  - "Antenna nub added top-right as small rounded rect to give pager silhouette distinctiveness"
metrics:
  duration: "5 minutes"
  completed: "2026-03-26"
  tasks: 2
  files_changed: 4
---

# Phase 21 Plan 01: Beeper Menu Bar Icon Summary

## One-liner

Replaced egg-shaped EggIcon with a programmatic pager/beeper silhouette (BeeperIcon) drawn via NSBezierPath — horizontal body, screen cutout, antenna nub, button dots — with isTemplate adaptation for light/dark menu bars.

## What Was Built

Created `Sources/BeeperIcon.swift` defining `enum BeeperIconState` (4 cases) and `enum BeeperIcon` with a static `image(state:) -> NSImage` factory. The icon draws a horizontal pager silhouette at 18x18:

- Rounded rect body (wider than tall)
- Screen cutout punched with NSColor.clear via .copy compositing
- Three button dots on the right side of the body (punched out)
- Small antenna nub on top-right corner

Color mapping is identical to EggIcon: normal=black (isTemplate), attention=systemOrange, yolo=systemPurple, hidden=gray.

Deleted `Sources/EggIcon.swift` and updated all two call sites:
- `CCBeeperApp.swift`: `EggIcon.image(state:)` → `BeeperIcon.image(state:)`
- `ClaudeMonitor.swift`: return type `EggIconState` → `BeeperIconState`

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Create BeeperIcon.swift with pager silhouette | 7443315 | Sources/BeeperIcon.swift (+), Sources/EggIcon.swift (deleted) |
| 2 | Update call sites to use BeeperIcon | b609a73 | Sources/CCBeeperApp.swift, Sources/ClaudeMonitor.swift |

## Verification

- `swift build` completes with zero errors
- `grep -ri "EggIcon" Sources/` returns no matches
- `grep -c "BeeperIcon" Sources/BeeperIcon.swift Sources/CCBeeperApp.swift Sources/ClaudeMonitor.swift` shows 3, 1, 1

## Deviations from Plan

None — plan executed exactly as written.

The only pragmatic adjustment was that Task 1's `swift build` verification was deferred until after Task 2's call site updates, since deleting EggIcon.swift without updating call sites produces a compile error. Both tasks were completed before the first build run. This is not a deviation from the intent — the plan implicitly requires both changes before the build can succeed.

## Known Stubs

None. The icon is fully wired and all 4 states are functional.

## Self-Check: PASSED

- [x] Sources/BeeperIcon.swift exists
- [x] Sources/EggIcon.swift deleted
- [x] Commit 7443315 exists
- [x] Commit b609a73 exists
- [x] `swift build` passes with zero errors
- [x] Zero EggIcon references in Sources/
