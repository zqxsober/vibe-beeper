---
phase: 31-kokoro-multilingual
plan: 02
subsystem: ui
tags: [swiftui, kokoro, tts, multilingual, settings, voice-picker]

# Dependency graph
requires:
  - phase: 31-kokoro-multilingual-01
    provides: KokoroVoiceCatalog, KokoroDepsInstaller, TTSService.setKokoroLangCode, ClaudeMonitor.kokoroLangCode
provides:
  - Language picker in Settings (9 languages, English US first)
  - Voice picker filtered by selected language using KokoroVoiceCatalog
  - Dep install prompt for Japanese (~500 MB) and Chinese (~45 MB)
  - Preview button speaks sample in selected voice
affects: [32-onboarding-voice, settings-ui]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Language-aware voice picker: KokoroVoiceCatalog.voicesByLang[monitor.kokoroLangCode] for filtered list"
    - "Dep check on language change: KokoroDepsInstaller.areDepsInstalled checked via onChange"

key-files:
  created: []
  modified:
    - Sources/Settings/SettingsVoiceSection.swift

key-decisions:
  - "Auto-voice-select on language change delegated to ClaudeMonitor.kokoroLangCode.didSet (no UI logic needed)"
  - "depsReady @State defaults to true to avoid flicker on app launch; checkDeps() called on language change"

patterns-established:
  - "Language/voice separation: language picker above voice picker, voice list derived from catalog"

requirements-completed: [TTS-02]

# Metrics
duration: 1min
completed: 2026-03-29
---

# Phase 31 Plan 02: Multilingual Settings Voice Picker Summary

**Language picker + filtered voice list in Settings, wiring KokoroVoiceCatalog into SettingsVoiceSection with dep install UI for Japanese/Chinese**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-29T11:02:11Z
- **Completed:** 2026-03-29T11:03:09Z
- **Tasks:** 1 of 2 (Task 2 is human-verify checkpoint)
- **Files modified:** 1

## Accomplishments
- Rewrote SettingsVoiceSection to remove 19-voice hardcoded array
- Added language picker showing all 9 languages, English US sorted first
- Voice picker now filters to `KokoroVoiceCatalog.voicesByLang[kokoroLangCode]` — correct voices per language
- Japanese/Chinese show dep install prompt with size warning and progress indicator
- Build succeeds with zero errors

## Task Commits

1. **Task 1: Rewrite SettingsVoiceSection with language picker and filtered voice list** - `14ec6ac` (feat)
2. **Task 2: Verify multilingual TTS works end-to-end** - CHECKPOINT (human-verify)

## Files Created/Modified
- `Sources/Settings/SettingsVoiceSection.swift` - Rewrote with language picker, filtered voice list, dep install UI

## Decisions Made
- Auto-voice-select on language change delegated entirely to `ClaudeMonitor.kokoroLangCode.didSet` — no duplicate UI logic
- `depsReady` @State defaults to `true` to prevent dep install prompt flashing on app startup

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Task 1 complete and committed. Awaiting human verification at checkpoint (Task 2).
- After approval: Phase 31 complete. Phase 32 (onboarding voice selection) can begin.

---
*Phase: 31-kokoro-multilingual*
*Completed: 2026-03-29 (partial — awaiting Task 2 human verify)*
