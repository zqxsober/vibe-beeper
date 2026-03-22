---
phase: 10-voice-input-injection
plan: 01
subsystem: ui
tags: [swift, swiftui, speech, avfoundation, cgevent, voice, accessibility]

# Dependency graph
requires: []
provides:
  - VoiceService: SFSpeechRecognizer on-device transcription + CGEvent HID injection + terminal focus/refocus
  - ClaudeMonitor.voiceService: owned VoiceService instance with Combine-mirrored isRecording
  - ContentView Speak button: wired to voiceService.toggle()
affects: [phase-11-auto-speak]

# Tech tracking
tech-stack:
  added: [SFSpeechRecognizer, AVAudioEngine, CGEvent, ApplicationServices]
  patterns:
    - "Recreate AVAudioEngine each session to prevent audio corruption across headphone changes"
    - "CGEvent nil source + .cghidEventTap for system-level keyboard injection"
    - "Clipboard paste fallback for text >200 UTF-16 characters"
    - "Capture frontmost app PID before focusing terminal; restore after injection"
    - "Combine assign(to:) to mirror VoiceService.isRecording into ClaudeMonitor without manual toggle"

key-files:
  created:
    - Sources/VoiceService.swift
  modified:
    - Sources/ClaudeMonitor.swift
    - Sources/ContentView.swift

key-decisions:
  - "format: nil in installTap — required for headphone compatibility (not a specific format)"
  - "AVAudioEngine recreated each session — prevents corruption on rapid start/stop"
  - "CGEvent(keyboardEventSource: nil, ...) — nil source required for correct HID injection"
  - "keyboardSetUnicodeString called on BOTH keyDown AND keyUp events"
  - "focusTerminal uses /usr/bin/open -a (Process), not NSRunningApplication.activate"
  - "previousAppPID captured BEFORE recording starts (while Claumagotchi is frontmost or user's app is frontmost)"
  - "isRecording on ClaudeMonitor is private(set), driven exclusively by Combine from VoiceService"

patterns-established:
  - "VoiceService is the single source of truth for recording state — ClaudeMonitor mirrors it"
  - "Power-off (isActive = false) calls stopIfRecording() before teardown"

requirements-completed: [VOICE-01, VOICE-02, INFRA-04]

# Metrics
duration: 8min
completed: 2026-03-22
---

# Phase 10 Plan 01: Voice Input Pipeline Summary

**On-device voice recording via SFSpeechRecognizer with CGEvent HID injection into terminal and automatic app refocus — user speaks from any app, text lands in Claude Code without touching the terminal**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-22T14:13:16Z
- **Completed:** 2026-03-22T14:21:17Z
- **Tasks:** 2 of 3 complete (Task 3 = human verification checkpoint)
- **Files modified:** 3

## Accomplishments

- Created VoiceService.swift: full recording, transcription, injection, and refocus pipeline adapted from VoiceLoop prototype
- Wired VoiceService into ClaudeMonitor (ownership, Combine binding, power-off cleanup) and ContentView (Speak button)
- Project builds cleanly (xcodebuild BUILD SUCCEEDED)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create VoiceService with recording, transcription, and injection** - `18add60` (feat)
2. **Task 2: Wire VoiceService into ClaudeMonitor and ContentView** - `08b52de` (feat)
3. **Task 3: Verify voice input end-to-end** - awaiting human verification

## Files Created/Modified

- `Sources/VoiceService.swift` - Voice recording, transcription, CGEvent injection, terminal focus, app refocus
- `Sources/ClaudeMonitor.swift` - Added voiceService property, Combine binding, stopIfRecording on power-off, hotkey wired
- `Sources/ContentView.swift` - Speak button now calls monitor.voiceService.toggle()

## Decisions Made

- Copied recording and injection logic directly from VoiceLoop prototype (proven working) rather than reinventing
- format: nil in installTap (headphone compatibility) — critical known requirement
- Nil CGEvent source + .cghidEventTap for HID injection — critical known requirement
- keyboardSetUnicodeString on both keyDown and keyUp — required for correct character injection
- focusTerminal via /usr/bin/open -a Process (not NSRunningApplication.activate) — works more reliably across terminal apps
- previousAppPID captured before startRecording so refocus targets the app the user was in when they pressed Speak

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Voice pipeline (recording + injection + refocus) is complete and compiled
- Human verification required (Task 3 checkpoint): grant mic + speech permissions, test end-to-end flow in Xcode
- After verification: Phase 11 (auto-speak) can wire into voiceService.isRecording to avoid interrupting recording

---
*Phase: 10-voice-input-injection*
*Completed: 2026-03-22*
