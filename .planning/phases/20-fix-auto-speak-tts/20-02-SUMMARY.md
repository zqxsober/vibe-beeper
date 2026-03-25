---
phase: 20-fix-auto-speak-tts
plan: "02"
subsystem: TTS
tags: [tts, groq, settings, audio, provider-routing]
dependency_graph:
  requires: []
  provides: [speakWithGroq, ttsProvider-property, TTS-provider-picker]
  affects: [Sources/TTSService.swift, Sources/ClaudeMonitor.swift, Sources/SettingsAudioSection.swift]
tech_stack:
  added: []
  patterns: [UserDefaults-published-property, provider-switch-dispatcher, AVAudioPlayer-mp3-playback]
key_files:
  modified:
    - Sources/TTSService.swift
    - Sources/ClaudeMonitor.swift
    - Sources/SettingsAudioSection.swift
decisions:
  - "Passed ttsProvider as parameter through speakSummary() -> speak() rather than injecting into TTSService directly — cleaner, avoids extra property on service class"
  - "Used .menu picker style for TTS Provider dropdown — matches macOS Settings patterns"
  - "Groq voice hardcoded to Arista-PlayAI per D-05 (voice selection deferred to POST-05)"
metrics:
  duration_minutes: 4
  completed_date: "2026-03-25"
  tasks_completed: 2
  files_modified: 3
---

# Phase 20 Plan 02: Add Groq TTS Provider and Settings Picker Summary

Groq TTS added as a selectable provider with provider-based routing in TTSService and a Settings dropdown, completing FIX-02.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add ttsProvider to ClaudeMonitor, speakWithGroq to TTSService, update speak dispatcher | b1cf5e5 | Sources/TTSService.swift, Sources/ClaudeMonitor.swift |
| 2 | Add TTS Provider picker to Settings Audio section | b7b4443 | Sources/SettingsAudioSection.swift |

## What Was Built

**TTSService.swift:**
- `speakSummary(_ text: String, provider: String = "apple")` — updated signature accepts provider parameter
- `speak(_ text: String, provider: String = "apple")` — replaced binary if/else with 3-way switch on provider string (groq/openai/apple)
- `speakWithGroq(_ text: String, apiKey: String)` — new method using `https://api.groq.com/openai/v1/audio/speech` with `playai-tts` model and `Arista-PlayAI` voice; mirrors speakWithOpenAI pattern; falls back to speakWithAva() on any error
- Fixed incorrect comment claiming Groq uses lowercase bearer (both providers use standard capital-B Bearer)

**ClaudeMonitor.swift:**
- `@Published var ttsProvider: String = "apple"` — new property with UserDefaults persistence (key: `"ttsProvider"`)
- Loads `ttsProvider` from UserDefaults in `init()` after `autoSpeak`
- `onSummaryFileChanged()` now passes `self.ttsProvider` to `ttsService.speakSummary()`

**SettingsAudioSection.swift:**
- `Picker("TTS Provider", ...)` — dropdown after Auto-Speak toggle, before Vibration toggle
- Options: Apple (tag: "apple"), Groq (tag: "groq"), OpenAI (tag: "openai")
- Bound to `$monitor.ttsProvider`, persists via ClaudeMonitor's UserDefaults didSet

## Decisions Made

1. **Provider passed as parameter** — ttsProvider flows from ClaudeMonitor through speakSummary() to speak() as a parameter rather than being injected as a property on TTSService. Cleaner — no extra mutable state on the service class, consistent with the existing pattern where TTSService has no knowledge of ClaudeMonitor.

2. **Hardcoded Arista-PlayAI voice** — Per D-05 and Claude's Discretion, no voice picker added. Voice selection deferred to POST-05.

3. **.menu picker style** — Dropdown is the correct macOS Settings pattern for a 3-option selection.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all three provider paths (Groq, OpenAI, Apple) are fully wired. The ttsProvider setting is persisted and drives real API calls.

## Self-Check: PASSED

Files verified:
- FOUND: Sources/TTSService.swift (speakWithGroq defined and called, api.groq.com present, playai-tts present, Arista-PlayAI present, provider switch with groq/openai cases)
- FOUND: Sources/ClaudeMonitor.swift (ttsProvider @Published property, forKey: "ttsProvider" persistence, provider: parameter in speakSummary call)
- FOUND: Sources/SettingsAudioSection.swift (ttsProvider binding, apple/groq/openai tags, .pickerStyle)

Commits verified:
- FOUND: b1cf5e5 (Task 1 — TTSService + ClaudeMonitor)
- FOUND: b7b4443 (Task 2 — SettingsAudioSection)

Build: `swift build` completed with no warnings after both tasks.
