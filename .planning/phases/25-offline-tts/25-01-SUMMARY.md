---
phase: 25-offline-tts
plan: "01"
subsystem: tts
tags: [kokoro, fluidaudio, offline-tts, actor, swift-concurrency]
dependency_graph:
  requires: [phase-23-fluidaudio-spm]
  provides: [KokoroService, speakWithKokoro, kokoroVoice-setting]
  affects: [TTSService.swift, ClaudeMonitor.swift]
tech_stack:
  added: [KokoroTtsManager, KokoroService actor]
  patterns: [actor-singleton, lazy-init-on-first-use, AVAudioPlayer-WAV-playback]
key_files:
  created: [Sources/KokoroService.swift]
  modified: [Sources/TTSService.swift, Sources/ClaudeMonitor.swift]
decisions:
  - "KokoroService actor wraps KokoroTtsManager with singleton pattern mirroring ParakeetService"
  - "speakWithKokoro lazy-initializes manager on first call avoiding startup cost"
  - "OpenAITTSDelegate reused for Kokoro WAV playback completion — renamed not needed"
  - "default dispatcher case covers apple + all legacy provider strings (groq, openai)"
metrics:
  duration: "4 minutes"
  completed: "2026-03-27"
  tasks_completed: 2
  files_modified: 3
---

# Phase 25 Plan 01: Kokoro TTS Integration Summary

**One-liner:** Replaced Groq/OpenAI cloud TTS with on-device Kokoro-82M via KokoroService actor — zero API keys, AVAudioPlayer WAV playback, Apple Ava fallback when model not downloaded.

## Completed Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create KokoroService actor + speakWithKokoro | a4141cd | Sources/KokoroService.swift (new), Sources/TTSService.swift |
| 2 | ClaudeMonitor default provider + migration + kokoroVoice | 93c606c | Sources/ClaudeMonitor.swift |

## What Was Built

### KokoroService.swift (new)
Actor singleton wrapping `KokoroTtsManager` lifecycle — mirrors `ParakeetService` pattern:
- `modelsDownloaded` static computed property: cheap disk stat checking `~/.cache/fluidaudio/Models/kokoro/{defaultVariant}.mlmodelc`
- `downloadModels(onProgress:)`: for use from onboarding (Phase 25 Plan 02)
- `initialize(defaultVoice:)`: load already-downloaded models into memory
- `synthesize(text:voice:)`: returns 16-bit PCM WAV Data at 24kHz via `KokoroTtsManager`
- `setDefaultVoice(_:)`: propagates voice selection changes
- `isReady`: true when manager is loaded

### TTSService.swift (updated)
- Removed `speakWithGroq()` and `speakWithOpenAI()` entirely
- Added `speakWithKokoro()`: lazy-initializes manager on first call, synthesizes WAV, plays via `AVAudioPlayer(data:fileTypeHint:.wav)` reusing `OpenAITTSDelegate`
- Updated `speak()` dispatcher: `"kokoro"` case checks `KokoroService.modelsDownloaded` before calling `speakWithKokoro()`, falls back to `speakWithAva()` if model not downloaded
- `default:` case covers `"apple"` and all unknown/legacy values (`"groq"`, `"openai"`)

### ClaudeMonitor.swift (updated)
- Default `ttsProvider` changed from `"apple"` to `"kokoro"` for new installs
- One-time migration in `init()`: if stored value is `"groq"` or `"openai"`, resets to `"kokoro"` (triggers `didSet` → writes to UserDefaults)
- New `@Published var kokoroVoice: String` persisted to `UserDefaults` key `"kokoroVoice"`, propagates changes to `KokoroService.shared.setDefaultVoice()` async

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all wiring is complete. `downloadModels(onProgress:)` is implemented but called from onboarding (Phase 25 Plan 02 scope — intentional placeholder for now).

## Self-Check: PASSED

Files exist:
- FOUND: /Users/vcartier/Desktop/CC-Beeper/Sources/KokoroService.swift
- FOUND: /Users/vcartier/Desktop/CC-Beeper/Sources/TTSService.swift
- FOUND: /Users/vcartier/Desktop/CC-Beeper/Sources/ClaudeMonitor.swift

Commits exist:
- FOUND: a4141cd (feat(25-01): create KokoroService actor + replace Groq/OpenAI with speakWithKokoro)
- FOUND: 93c606c (feat(25-01): update ClaudeMonitor default TTS provider + migration + kokoroVoice)

Build: `swift build` completes with zero errors.
