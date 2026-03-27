---
phase: 24
plan: 01
subsystem: voice
tags: [stt, parakeet, fluidaudio, streaming, offline]
dependency_graph:
  requires: [23-01]
  provides: [ParakeetService, Parakeet-recording-path-in-VoiceService]
  affects: [VoiceService, OnboardingViewModel]
tech_stack:
  added: [FluidAudio.StreamingEouAsrManager]
  patterns: [actor-singleton, delta-injection, EOU-debounce, hasSubmitted-guard]
key_files:
  created:
    - Sources/ParakeetService.swift
  modified:
    - Sources/VoiceService.swift
decisions:
  - "configureCallbacks marked async — setPartialCallback/setEouCallback are actor-isolated and require await"
  - "D-02 implemented via delta tracking: lastInjectedText tracks injected prefix, only new characters injected"
  - "clearTerminalInput uses Cmd+A + Delete for model text revision handling"
  - "Groq path fully removed from VoiceService — GroqTranscriptionService.swift file stays until Phase 26"
metrics:
  duration: "~3.5 minutes"
  completed: "2026-03-27"
  tasks: 2
  files: 2
---

# Phase 24 Plan 01: Parakeet STT Service + VoiceService Wiring Summary

**One-liner:** Parakeet TDT on-device streaming STT via FluidAudio's StreamingEouAsrManager with live terminal delta injection, replacing the Groq cloud transcription path.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create ParakeetService actor | e980a24 | Sources/ParakeetService.swift (created) |
| 2 | Wire Parakeet into VoiceService, remove Groq, live injection | 34b1436 | Sources/VoiceService.swift (modified), Sources/ParakeetService.swift (fixed) |

## What Was Built

### ParakeetService (Sources/ParakeetService.swift)

Actor singleton wrapping FluidAudio's `StreamingEouAsrManager` lifecycle:

- `static let shared` — singleton for cross-service use (VoiceService + OnboardingViewModel)
- `static var modelsDownloaded` — cheap `checkResourceIsReachable()` disk stat, no model load
- `downloadModels(onProgress:)` — HuggingFace download with three-phase progress (listing/downloading/compiling)
- `initialize()` — loads model from `~/Library/Application Support/FluidAudio/Models/parakeet-eou-streaming/`
- `configureCallbacks(onPartial:onEou:)` — sets streaming callbacks before each session
- `process(_:)` — feeds `AVAudioPCMBuffer` directly; FluidAudio resamples to 16kHz mono internally
- `finish()` — flushes final audio chunk, returns complete transcript
- `reset()` — clears session state for next recording (no re-initialization)
- `isReady` — computed property checking manager != nil

### VoiceService changes (Sources/VoiceService.swift)

**Parakeet path added:**
- `startRecordingParakeet(inputNode:)` — Parakeet recording with live terminal injection (D-02)
- `injectPartialDelta(_:)` — tracks `lastInjectedText`, injects only delta (new characters)
- `injectTextOnly(_:)` — same clipboard/CGEvent logic as `injectAndSubmit` but without Enter
- `clearTerminalInput()` — Cmd+A + Delete when model revises earlier words
- `submitTerminal()` — presses Enter only (text already in terminal)
- `stopRecordingEngine()` — shared helper called by EOU callback and manual stop
- `hasSubmitted: Bool` — prevents double-submit from EOU + Stop race (Pitfall 5)
- `lastInjectedText: String` — delta tracking state
- `isParakeetSession: Bool` — which path is active
- `sttEngineLabel: String` — computed property for Settings display (D-05)

**Groq path removed:**
- `startRecordingGroq(inputNode:nativeFormat:)` — deleted
- `wavFileURL`, `wavAudioFile` properties — deleted
- `useGroq` computed property — deleted
- Groq branch in `stopRecording()` — deleted
- `GroqTranscriptionService` call site — deleted (service file stays until Phase 26)

**SFSpeech fallback unchanged** — `startRecordingSFSpeech` preserved exactly as before.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed actor-isolated method call requiring async**
- **Found during:** Task 2 (swift build)
- **Issue:** `configureCallbacks` called `manager?.setPartialCallback()` and `manager?.setEouCallback()` synchronously, but `StreamingEouAsrManager` is an actor — these are actor-isolated methods requiring `await`
- **Fix:** Marked `configureCallbacks` as `async` and added `await` to both calls in ParakeetService.swift
- **Files modified:** Sources/ParakeetService.swift
- **Commit:** 34b1436 (included in Task 2 commit)

## Known Stubs

None — ParakeetService is fully wired. VoiceService correctly routes to Parakeet when `modelsDownloaded == true` and falls back to SFSpeech otherwise. The model download step (called from onboarding) is addressed in Plan 02.

## Self-Check: PASSED

- [x] Sources/ParakeetService.swift exists and contains all required symbols
- [x] Sources/VoiceService.swift contains all required Parakeet symbols
- [x] Sources/VoiceService.swift has no Groq symbols
- [x] Commits e980a24 and 34b1436 verified in git log
- [x] `swift build` reports "Build complete!"
