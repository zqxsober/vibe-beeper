# Requirements: Claumagotchi

**Defined:** 2026-03-21
**Core Value:** Users can see what Claude is doing, respond to it, and give it instructions — without leaving their current workflow

## v2.0 Requirements

Requirements for the Game Boy milestone. Each maps to roadmap phases.

### UI

- [ ] **UI-01**: Widget displays a skeuomorphic Game Boy Color shell with plastic texture, bevels, and themed colors
- [ ] **UI-02**: Screen area is larger than v1.1 and shows character animation, permission details (tool, file path, action), and session status
- [ ] **UI-03**: Button panel has physical-looking A/B buttons, D-pad (visual), Select/Start buttons, speaker grille, and power LED
- [ ] **UI-04**: "CLAUMAGOTCHI" branding appears on the screen bezel in pixel font

### Voice

- [ ] **VOICE-01**: User can toggle voice recording (tap to start, tap to stop) via Select button or hotkey
- [ ] **VOICE-02**: Transcribed voice text is injected into the terminal and submitted (Enter), then the previous app is refocused — user never sees the terminal switch
- [ ] **VOICE-03**: When Claude finishes and auto-speak is enabled, the last response is summarized via Apple Intelligence and spoken aloud using Ava Premium TTS
- [ ] **VOICE-04**: User can stop TTS mid-sentence via mute button or hotkey

### Controls

- [ ] **CTRL-01**: User can accept a pending permission via A button or hotkey
- [ ] **CTRL-02**: User can deny a pending permission via B button or hotkey
- [ ] **CTRL-03**: User can toggle YOLO mode (auto-accept all permissions) via a slider-style toggle on the shell
- [ ] **CTRL-04**: User can power off the companion (disables all monitoring, no sounds, no permission handling) and power back on
- [ ] **CTRL-05**: User can hide the widget to the menu bar and restore it from the menu

### Infrastructure

- [ ] **INFRA-01**: A Python hook fires on Claude Code stop events, extracts the last assistant text from the session JSONL, and writes it to `~/.claude/claumagotchi/last_summary.txt`
- [ ] **INFRA-02**: Every button action has a configurable keyboard shortcut (hotkey)
- [ ] **INFRA-03**: User can view and remap hotkeys from the menu bar
- [ ] **INFRA-04**: Menu bar provides toggles for: show/hide widget, sound effects, auto-speak, and power on/off
- [ ] **INFRA-05**: All features work across all projects and Claude Code sessions on the same machine

## Future Requirements

### Quality of Life

- **QOL-01**: Custom TTS voice selection (beyond Ava Premium)
- **QOL-02**: Per-project settings (different YOLO/voice preferences per project)
- **QOL-03**: Conversation history panel (past summaries)

### Distribution

- **DIST-01**: Automated test suite
- **DIST-02**: App Store distribution

## Out of Scope

| Feature | Reason |
|---------|--------|
| Settings window | Controls live on widget + menu bar, no separate window needed |
| Activity feed UI | Summaries replace raw activity log |
| BYOK API keys | Apple Intelligence is free and on-device |
| External TTS (OpenAI, ElevenLabs) | Ava Premium is free and adequate |
| Actionable notification buttons | Widget is always floating |
| iOS/iPad companion | macOS only |
| Swift Concurrency migration | Separate refactor milestone |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| UI-01 | Phase 9 | Pending |
| UI-02 | Phase 9 | Pending |
| UI-03 | Phase 9 | Pending |
| UI-04 | Phase 9 | Pending |
| VOICE-01 | Phase 11 | Pending |
| VOICE-02 | Phase 11 | Pending |
| VOICE-03 | Phase 12 | Pending |
| VOICE-04 | Phase 12 | Pending |
| CTRL-01 | Phase 13 | Pending |
| CTRL-02 | Phase 13 | Pending |
| CTRL-03 | Phase 13 | Pending |
| CTRL-04 | Phase 13 | Pending |
| CTRL-05 | Phase 13 | Pending |
| INFRA-01 | Phase 10 | Pending |
| INFRA-02 | Phase 13 | Pending |
| INFRA-03 | Phase 13 | Pending |
| INFRA-04 | Phase 10 | Pending |
| INFRA-05 | Phase 10 | Pending |

**Coverage:**
- v2.0 requirements: 18 total
- Mapped to phases: 18
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-21*
