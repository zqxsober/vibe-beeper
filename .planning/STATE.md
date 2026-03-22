---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: Voice Loop
status: in-progress
stopped_at: "Completed 10-01-PLAN.md — Phase 10 done, Phase 11 pending"
last_updated: "2026-03-22T15:00:00.000Z"
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 5
  completed_plans: 5
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-21)

**Core value:** Users can see what Claude is doing, respond to it, and give it instructions — without leaving their current workflow
**Current focus:** Phase 10 — voice-input-injection

## Current Position

Phase: 11 (auto-speak-summary-hook) — NEXT
Plan: Phase 10 complete (1/1 plans done)

## Accumulated Context

### Decisions

- v1.1 complete: All 4 phases shipped (hardening, reliability, UX, notifications)
- v2.0 previously attempted (phases 5-8) and reverted — voice/settings/summary unreliable
- VoiceLoop prototype validates: voice input, auto-speak, hook-based summary, CGEvent injection
- Lessons: use regular window (not NSPanel), nil audio format, Apple Dev signing, nil CGEvent source
- Extracted types to separate files following SwiftUI Pro one-type-per-file rule
- isActive initialized in init body after setupFileWatcher so didSet only fires on external mutation
- Hotkey guard pendingPermission moved into A/D cases only — S and G work without pending permission
- thinkingStartTime only resets when transitioning INTO thinking (session state was not .thinking)
- [Phase 09-ui-controls]: 4 buttons always visible in fixed layout — YOLO mode only affects screen text, not button visibility
- [Phase 09-ui-controls]: ScreenContentView drives state-specific status text; ScreenView is a thin passthrough wrapper
- [Phase 09-ui-controls]: Show/Hide Widget and Power Off are independent controls — Show/Hide preserves isActive, Power Off sets it false
- [Phase 09-ui-controls]: Menu bar icon greyed only when powered off (EggIconState.hidden) — not when widget is merely hidden
- [Phase 10-voice-input-injection]: VoiceService uses format:nil in installTap, nil CGEvent source, keyboardSetUnicodeString on keyDown+keyUp, /usr/bin/open -a for terminal focus — exact VoiceLoop prototype patterns
- [Phase 10-voice-input-injection]: isRecording on ClaudeMonitor is private(set), driven exclusively by Combine from VoiceService; previousAppPID captured before startRecording for correct refocus target

### Pending Todos

None yet.

### Blockers/Concerns

- Audio engine corruption from rapid start/stop — mitigated by recreating AVAudioEngine each session
- Accessibility permission requires Apple Development signing to persist across rebuilds
- Apple Intelligence availability varies — need graceful fallback when unavailable

## Session Continuity

Last session: 2026-03-22T15:00:00.000Z
Stopped at: Completed 10-01-PLAN.md — Phase 10 complete, Phase 11 pending
Resume file: None
