---
phase: 15-voice-fixes
plan: 02
subsystem: ui
tags: [swift, swiftui, groq, openai, keychain, tts, speech-recognition, onboarding]

# Dependency graph
requires:
  - phase: 15-voice-fixes-01
    provides: KeychainService, GroqTranscriptionService, SettingsVoiceSection with API key fields
provides:
  - Conditional Groq Whisper transcription path in VoiceService (activates when Groq key set)
  - Conditional OpenAI TTS path in TTSService (activates when OpenAI key set)
  - Optional API Keys onboarding step between Voices and Done
  - Mint and Pink shell themes (10 total themes)
  - Fixed Settings window frame (460x520) with .formStyle(.grouped)
affects: [future-phases, onboarding, voice, settings]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Conditional API path: check KeychainService.load at call time, branch to API or on-device path"
    - "AVAudioFile tap-recording for Groq WAV upload (native format, no conversion)"
    - "AVAudioPlayer with strong-reference delegate for OpenAI MP3 playback"
    - "Onboarding CaseIterable enum: inserting step auto-updates totalSteps/progress"

key-files:
  created:
    - Sources/OnboardingAPIKeysStep.swift
    - Sources/shells/beeper-mint.png
    - Sources/shells/beeper-pink.png
  modified:
    - Sources/VoiceService.swift
    - Sources/TTSService.swift
    - Sources/OnboardingViewModel.swift
    - Sources/OnboardingView.swift
    - Sources/ThemeManager.swift
    - Sources/MenuBarPopoverView.swift
    - Sources/SettingsView.swift

key-decisions:
  - "Groq path skips SFSpeech entirely in startRecording — no recognition request or task created, prevents timeout race"
  - "WAV recording uses native AVAudioEngine format (no AVAudioConverter) — Groq auto-downsamples, simplifies Wave 1"
  - "AVAudioPlayer stored as instance property (not local) — prevents ARC deallocation during playback"
  - "OpenAITTSDelegate as private NSObject subclass — wires audioPlayerDidFinishPlaying to isSpeaking = false"
  - "SettingsView uses fixed frame 460x520 — prevents layout instability with .formStyle(.grouped)"
  - "Mint and Pink themes added alphabetically — 10 total themes in ThemeManager"

patterns-established:
  - "BYOK conditional dispatch: check Keychain at call site, not at init — supports runtime key changes"
  - "Groq errors log + show 'Groq error' on LCD — no crash, no SFSpeech fallback in Groq mode"

requirements-completed: [VOICE-05, VOICE-06, VOICE-07]

# Metrics
duration: 45min
completed: 2026-03-25
---

# Phase 15 Plan 02: Voice Fixes BYOK Wiring Summary

**Groq Whisper and OpenAI TTS BYOK paths wired end-to-end: on-device fallback preserved, API keys activate higher-quality voice recording and speech synthesis**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-03-24T21:00:00Z
- **Completed:** 2026-03-25T00:00:00Z
- **Tasks:** 3 (2 auto + 1 human-verify checkpoint)
- **Files modified:** 10

## Accomplishments

- VoiceService now branches on Groq key presence: WAV recording + Groq Whisper upload when key set, SFSpeech on-device when not set — no regression to existing voice path
- TTSService now branches on OpenAI key presence: MP3 download and AVAudioPlayer playback when key set, Ava Premium AVSpeechSynthesizer when not set
- Onboarding wizard gains optional API Keys step (step 4) between Voices and Done — "upgrade your experience" framing, skippable
- Two new shell themes (Mint, Pink) added to ThemeManager and MenuBarPopoverView, bringing total to 10 themes
- Settings window fixed at 460x520 with .formStyle(.grouped) for stable layout

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Groq and OpenAI conditional paths** - `0b41c7e` (feat)
2. **Task 2: Add optional API Keys onboarding step** - `4936187` (feat)
3. **Task 3: Verify BYOK flow + commit checkpoint changes** - `0963f04` (feat)

**Plan metadata:** (docs commit — created below)

## Files Created/Modified

- `Sources/VoiceService.swift` - Groq WAV recording path + Groq transcription dispatch in stopRecording; SFSpeech path unchanged
- `Sources/TTSService.swift` - OpenAI TTS path with AVAudioPlayer + strong delegate; Ava path renamed speakWithAva, preserved
- `Sources/OnboardingAPIKeysStep.swift` - New view: SecureField inputs for Groq + OpenAI keys, Skip and Save & Continue buttons
- `Sources/OnboardingViewModel.swift` - Step enum updated: apiKeys = 4, done = 5 (CaseIterable auto-updates progress)
- `Sources/OnboardingView.swift` - Routes .apiKeys case to OnboardingAPIKeysStep
- `Sources/ThemeManager.swift` - Mint and Pink themes added alphabetically (10 total)
- `Sources/MenuBarPopoverView.swift` - Mint and Pink color dots added to theme selector
- `Sources/SettingsView.swift` - Fixed frame 460x520, .formStyle(.grouped), .scrollContentBackground(.visible)
- `Sources/shells/beeper-mint.png` - New mint shell image
- `Sources/shells/beeper-pink.png` - New pink shell image

## Decisions Made

- Groq mode skips SFSpeech entirely in `startRecording` — no recognition request or task created. Prevents the timeout race condition where SFSpeech would fire its 2-second fallback competing with Groq.
- WAV recording uses native AVAudioEngine format without AVAudioConverter — Groq accepts native sample rates, avoids Wave 1 complexity.
- `audioPlayer` stored as `TTSService` instance property, not a local variable — critical to prevent ARC deallocation mid-playback.
- OpenAI errors fall back to Ava (speakWithAva) — graceful degradation for TTS. Groq errors log only (no SFSpeech fallback) — different user expectation for transcription vs speech.

## Deviations from Plan

### Auto-fixed Issues

None during Tasks 1 and 2.

### Checkpoint Changes (Task 3)

Changes applied during the human-verify checkpoint session, committed as Task 3:
- SettingsView: `.formStyle(.grouped)` + fixed frame `460x520` + `.scrollContentBackground(.visible)`
- ThemeManager: Mint and Pink themes added (alphabetical order, 10 total)
- MenuBarPopoverView: Mint and Pink color dot cases added
- beeper-mint.png and beeper-pink.png shell images added

These were verified by the user during the checkpoint and committed on resume.

---

**Total deviations:** 0 plan deviations (checkpoint changes applied as approved user modifications)
**Impact on plan:** No scope creep — checkpoint changes were UI polish approved during human-verify.

## Issues Encountered

None — plan executed cleanly. swift build passed after each task.

## User Setup Required

None - no external service configuration required at build time. API keys are optional and entered at runtime via Settings or onboarding.

## Next Phase Readiness

- Phase 15 voice fixes complete — full BYOK voice loop works end-to-end
- Both on-device paths verified as default (no keys required to run app)
- Settings Voice section and onboarding both provide key entry points
- 10 shell themes ready for DMG packaging phase
- No blockers for next phase

## Self-Check: PASSED

- FOUND: Sources/VoiceService.swift
- FOUND: Sources/TTSService.swift
- FOUND: Sources/OnboardingAPIKeysStep.swift
- FOUND: Sources/shells/beeper-mint.png
- FOUND: Sources/shells/beeper-pink.png
- FOUND: .planning/phases/15-voice-fixes/15-02-SUMMARY.md
- FOUND commit: 0b41c7e (Task 1)
- FOUND commit: 4936187 (Task 2)
- FOUND commit: 0963f04 (Task 3)

---
*Phase: 15-voice-fixes*
*Completed: 2026-03-25*
