---
phase: 15-voice-fixes
plan: 01
subsystem: api
tags: [keychain, security, groq, whisper, tts, byok, swiftui, xctest]

# Dependency graph
requires:
  - phase: 13-onboarding
    provides: "testTarget has no @testable import — tests use XCTest-only stubs"
provides:
  - "KeychainService: macOS Keychain CRUD wrapper (save/load/delete) with upsert and empty-string-deletes"
  - "GroqTranscriptionService: Groq Whisper multipart WAV upload returning transcribed text"
  - "SettingsVoiceSection: API Keys section with SecureField rows for Groq and OpenAI keys"
  - "KeychainServiceTests: 6-test suite covering round-trip, upsert, empty-string-deletes, isolation"
affects:
  - 15-02
  - voice-service-groq-path
  - tts-service-openai-path

# Tech tracking
tech-stack:
  added:
    - "Security framework (SecItemAdd, SecItemCopyMatching, SecItemUpdate, SecItemDelete)"
  patterns:
    - "Keychain upsert: try SecItemAdd; on errSecDuplicateItem, SecItemUpdate"
    - "Empty-string-deletes: save('') calls delete() instead of writing empty data"
    - "kSecAttrSynchronizable: false prevents iCloud sync of third-party API keys"
    - "Groq auth: lowercase 'bearer' header (not 'Bearer') — Groq-specific requirement"
    - "Multipart body: inline boundary builder for binary WAV data"
    - "Test stubs: embed implementation logic in test file when @testable import unavailable"

key-files:
  created:
    - Sources/KeychainService.swift
    - Sources/GroqTranscriptionService.swift
    - Tests/ClaumagotchiTests/KeychainServiceTests.swift
  modified:
    - Sources/SettingsVoiceSection.swift

key-decisions:
  - "KeychainService implemented as caseless enum (no instances) — matches GroqTranscriptionService pattern"
  - "Test file embeds TestableKeychainService stub — @testable import not available for .executableTarget (Phase 13 decision)"
  - "GroqTranscriptionService uses 'bearer' (lowercase) per Groq docs, verified critical to avoid 401"
  - "Settings UI uses .onAppear on the caption Text to load Keychain keys — scoped to avoid multiple triggers"

patterns-established:
  - "Pattern: BYOK optional framing — 'upgrade your experience', not 'you need this'"
  - "Pattern: Keychain upsert via errSecDuplicateItem guard, not optimistic add"
  - "Pattern: WAV multipart body built inline (no helper class) — 30 lines, verified format"

requirements-completed: [VOICE-06, VOICE-07]

# Metrics
duration: 3min
completed: 2026-03-24
---

# Phase 15 Plan 01: Voice Fixes Foundation Summary

**KeychainService Keychain CRUD wrapper + GroqTranscriptionService Whisper multipart upload + Settings API key entry fields with Keychain persistence**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-24T21:53:56Z
- **Completed:** 2026-03-24T21:56:31Z
- **Tasks:** 2 of 2
- **Files modified:** 4

## Accomplishments

- KeychainService enum with save/load/delete and upsert pattern (errSecDuplicateItem handled), empty-string-deletes, and iCloud sync disabled via kSecAttrSynchronizable: false
- GroqTranscriptionService enum that POSTs WAV files to Groq Whisper with lowercase `bearer` auth header, whisper-large-v3-turbo model, multipart body, and temp file cleanup after upload
- SettingsVoiceSection expanded with two SecureField rows for Groq and OpenAI keys that load from Keychain on appear and save on submit; optional framing preserved in caption

## Task Commits

1. **Task 1: Create KeychainService and GroqTranscriptionService** - `84321d3` (feat + test/TDD)
2. **Task 2: Add API Keys section to Settings Voice panel** - `fb811fa` (feat)

## Files Created/Modified

- `Sources/KeychainService.swift` - Keychain CRUD wrapper with upsert and empty-string-deletes; account constants groqAccount and openAIAccount
- `Sources/GroqTranscriptionService.swift` - Groq Whisper multipart upload; lowercase bearer auth; temp file cleanup; HTTP error details
- `Tests/ClaumagotchiTests/KeychainServiceTests.swift` - 6 tests (save/load, empty-deletes, upsert, delete-nonexistent, load-missing, account-isolation)
- `Sources/SettingsVoiceSection.swift` - Added SecureField rows for Groq/OpenAI with Keychain load on appear and save on submit

## Decisions Made

- KeychainService implemented as caseless enum (no instances needed) — matches existing `enum` service patterns like GroqTranscriptionService
- Tests embed a local `TestableKeychainService` stub because `@testable import` is not available for `.executableTarget` (Phase 13 decision). The stub is a verbatim copy of the production logic; if the production implementation diverges, the test stub must be updated too.
- `.onAppear` attached to the caption Text (last element in the section) to trigger Keychain load — one clean attachment point for the group
- Groq auth header uses lowercase `bearer` — explicitly verified against RESEARCH.md pitfall #1; OpenAI would use `Bearer` (capital B) in Plan 02

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required. Users provide their own API keys via Settings.

## Next Phase Readiness

- Plan 02 (VoiceService and TTSService wiring) can proceed immediately
- KeychainService.load(account: KeychainService.groqAccount) is the gate condition for selecting Groq vs SFSpeech path
- KeychainService.load(account: KeychainService.openAIAccount) is the gate condition for selecting OpenAI TTS vs Ava
- GroqTranscriptionService.transcribe(wavURL:apiKey:) is the async entry point for Plan 02

---
*Phase: 15-voice-fixes*
*Completed: 2026-03-24*
