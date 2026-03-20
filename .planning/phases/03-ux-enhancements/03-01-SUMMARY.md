---
phase: 03-ux-enhancements
plan: 01
subsystem: monitor-state, screen-view, hook
tags: [ux, session-count, idle-state, sprites, permissions]
dependency_graph:
  requires: []
  provides: [sessionCount, ClaudeState.idle, sleep-sprites, full-path-display]
  affects: [Sources/ClaudeMonitor.swift, Sources/ScreenView.swift, hooks/claumagotchi-hook.py]
tech_stack:
  added: []
  patterns: [published-derived-state, exhaustive-enum-switch, left-truncated-path]
key_files:
  created: []
  modified:
    - Sources/ClaudeMonitor.swift
    - Sources/ScreenView.swift
    - hooks/claumagotchi-hook.py
decisions:
  - sessionCount updated at all 4 mutation sites (updateAggregateState, two permission branches, rehydrateSessions)
  - Idle timer transitions to .idle not .finished — distinct sleeping state from done state
  - Full path left-truncated at 40 chars preserving meaningful filename end
  - Checkmark LCD icon lights for both .finished and .idle — both mean session complete
metrics:
  duration: "~3 min"
  completed: "2026-03-20"
  tasks_completed: 2
  files_modified: 3
---

# Phase 03 Plan 01: Session Count, Idle State, Full-Path Permissions Summary

**One-liner:** Session count badge in LCD row, sleeping sprites after 60s idle via new ClaudeState.idle, and full path display replacing basename in permission prompts.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add session count display and full-path permission info | 1dd6a0a | ClaudeMonitor.swift, ScreenView.swift, claumagotchi-hook.py |
| 2 | Add idle/sleeping animation state | 163eb0e | ClaudeMonitor.swift, ScreenView.swift |

## What Was Built

### Session Count Badge (UX-01)
- `@Published var sessionCount: Int = 0` added to `ClaudeMonitor`
- Updated at all 4 mutation sites: `updateAggregateState()` end, both permission branches in `processEvent()`, and `rehydrateSessions()`
- LCD icon row now renders a session count text badge between the alert and bolt icons when `sessionCount > 0`

### Idle/Sleeping State (UX-02)
- `ClaudeState.idle` case added with label "ZZZ...", `needsAttention=false`, `canGoToConvo=false`
- `startIdleTimer` now sets state to `.idle` instead of `.finished` after 60 seconds
- `spritesForState(.idle)` returns `[Sprites.sleep1, Sprites.sleep2]` for breathing animation
- Two new sleeping sprites added — closed eyes (blank eye rows), flat mouth, feet-shift animation
- Checkmark LCD icon lights for both `.finished` and `.idle`
- All switch statements over `ClaudeState` remain exhaustive (compiler verified)

### Full-Path Permission Display (UX-03)
- `summarize_input()` for Write/Read/Edit/Glob tools now returns full path
- Truncated from left with "..." prefix if path exceeds 40 characters, preserving filename end
- Replaces `os.path.basename()` which only showed filename without context

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

1. `swift build` passes — all ClaudeState switch statements exhaustive with new .idle case
2. `grep -c "sessionCount" Sources/ClaudeMonitor.swift` = 5 (declaration + 4 update sites)
3. `grep 'path[-37:]' hooks/claumagotchi-hook.py` confirms full-path logic
4. `grep "sleep1" Sources/ScreenView.swift` confirms sleeping sprites
5. `grep "case idle" Sources/ClaudeMonitor.swift` confirms new state

## Self-Check: PASSED

- ClaudeMonitor.swift: FOUND
- ScreenView.swift: FOUND
- claumagotchi-hook.py: FOUND
- commit 1dd6a0a: FOUND
- commit 163eb0e: FOUND
