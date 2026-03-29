---
phase: 32-language-preference-system
plan: 01
subsystem: voice
tags: [kokoro, whisper, whisperkit, tts, stt, multilingual, swift]

# Dependency graph
requires:
  - phase: 31-kokoro-multilingual
    provides: KokoroVoiceCatalog with langCodesRequiringDeps, kokoroLangCode property in ClaudeMonitor
  - phase: 30-whisper-stt
    provides: WhisperService.transcribe(), DecodingOptions, WhisperKit integration

provides:
  - kokoroLangToISO mapping (Kokoro lang codes → ISO 639-1 for WhisperKit)
  - kokoroLangCode(fromSystemLocale:) helper for BCP-47 → Kokoro lang code mapping
  - WhisperService.transcribe(languageHint:) for improved multilingual STT accuracy
  - VoiceService.languageCode property propagated from ClaudeMonitor
  - ClaudeMonitor first-launch system language detection
  - ClaudeMonitor.depsNeededForCurrentLang published flag for Japanese/Chinese dep prompts

affects: [33-language-onboarding, settings-voice-section, dep-install-ui]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Language preference flows: ClaudeMonitor.kokoroLangCode.didSet → VoiceService.languageCode → WhisperService.transcribe(languageHint:)"
    - "First-launch detection via UserDefaults.object(forKey:) == nil (not string(forKey:))"
    - "ISO hint bypasses Whisper language detection (detectLanguage: false when hint provided)"

key-files:
  created: []
  modified:
    - Sources/Voice/KokoroVoiceCatalog.swift
    - Sources/Voice/WhisperService.swift
    - Sources/Voice/VoiceService.swift
    - Sources/Monitor/ClaudeMonitor.swift

key-decisions:
  - "object(forKey:) used for first-launch check — returns nil only when key was never written (string(forKey:) cannot distinguish never-set from empty string)"
  - "detectLanguage: false when languageHint is provided — passing both causes WhisperKit pitfall (hint ignored)"
  - "depsNeededForCurrentLang is published but NOT auto-triggering install — UI-triggered only per LANG-03"
  - "Both TTS and STT share a single language preference (kokoroLangCode) — no separate per-service setting"

patterns-established:
  - "Language propagation chain: kokoroLangCode.didSet sets voiceService.languageCode, which flows to whisperService.transcribe(languageHint:) on next recording"
  - "Init order: load from UserDefaults first → then check for first-launch → then propagate to VoiceService"

requirements-completed: [LANG-01, LANG-02, LANG-03, LANG-04]

# Metrics
duration: 12min
completed: 2026-03-29
---

# Phase 32 Plan 01: Language Preference System Summary

**Unified language preference wiring: kokoroLangCode now drives both Kokoro TTS and WhisperKit STT, with system locale first-launch detection and a dep-install flag for Japanese/Chinese.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-03-29T20:44:59Z
- **Completed:** 2026-03-29T20:56:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- KokoroVoiceCatalog now provides `kokoroLangToISO` (9-entry mapping) and `kokoroLangCode(fromSystemLocale:)` for BCP-47 locale to Kokoro lang code
- WhisperService.transcribe() accepts an optional `languageHint` — skips auto-detection when language is known, improving STT accuracy for non-English users
- VoiceService gains `languageCode` property and passes the derived ISO hint to every transcription
- ClaudeMonitor propagates language preference to VoiceService on init and on every `kokoroLangCode` change
- First-launch system language detection reads `Locale.preferredLanguages.first` and maps to the correct Kokoro lang code — falls back to "a" (American English) if language is unsupported
- `depsNeededForCurrentLang` published flag is true for Japanese ("j") and Chinese ("z"), ready for Settings/onboarding dep-install UI

## Task Commits

Each task was committed atomically:

1. **Task 1: Add language mappings to KokoroVoiceCatalog and language hint to WhisperService** - `a732ccc` (feat)
2. **Task 2: Wire ClaudeMonitor first-launch detection, VoiceService language propagation, and dep flag** - `2989b66` (feat)

**Plan metadata:** _(docs commit — pending)_

## Files Created/Modified

- `Sources/Voice/KokoroVoiceCatalog.swift` - Added `kokoroLangToISO` static dict and `kokoroLangCode(fromSystemLocale:)` static func
- `Sources/Voice/WhisperService.swift` - Updated `transcribe()` signature with optional `languageHint: String?` parameter
- `Sources/Voice/VoiceService.swift` - Added `languageCode: String` property; passes ISO hint to `whisperService.transcribe()`
- `Sources/Monitor/ClaudeMonitor.swift` - Added `depsNeededForCurrentLang` flag, first-launch detection, voiceService propagation in init and didSet

## Decisions Made

- Used `UserDefaults.standard.object(forKey:)` (not `string(forKey:)`) for first-launch detection — `object(forKey:)` returns nil only when the key has never been set, correctly distinguishing first launch from explicit "a" preference
- `detectLanguage: false` is set alongside any provided language hint — WhisperKit ignores the hint if `detectLanguage: true` is also set (per research pitfall 4)
- `depsNeededForCurrentLang` is a published flag only — it does NOT auto-trigger pip install; that responsibility belongs to the UI (onboarding or Settings) per LANG-03

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

- `swift build -c release` does not produce a `.app` bundle — used `./build.sh` (which wraps swift build + app bundle assembly + codesigning) to produce `CC-Beeper.app` before copying to `/Applications`

## Known Stubs

None — all language preference data flows from real UserDefaults/system locale sources.

## Next Phase Readiness

- Language preference system is fully wired: single `kokoroLangCode` drives both TTS and STT
- `depsNeededForCurrentLang` flag is ready for Phase 33 onboarding voice picker to display dep-install prompts for Japanese/Chinese
- Settings language picker (Phase 31-02) continues to work unchanged — the picker already writes to `kokoroLangCode`

---
*Phase: 32-language-preference-system*
*Completed: 2026-03-29*
