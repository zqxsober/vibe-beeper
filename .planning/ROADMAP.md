# Roadmap: Claumagotchi

## Milestones

- ✅ **v1.1 Polish + Hardening** - Phases 1-4 (shipped 2026-03-20)
- ❌ **v2.0 Voice & Intelligence** - Phases 5-8 (reverted 2026-03-21)
- 🚧 **v2.0 Game Boy** - Phases 9-13 (in progress)

## Overview

v1.1 hardened the foundation. The first v2.0 attempt (settings, activity feed, AI summaries, voice) was reverted due to reliability issues. v2.0 Game Boy is a fresh take: a Game Boy Color form factor with voice input, auto-speak summaries, and a full button panel — so users never need to touch the terminal. Built on lessons from the VoiceLoop prototype.

## Phases

<details>
<summary>✅ v1.1 Polish + Hardening (Phases 1-4) - SHIPPED 2026-03-20</summary>

### Phase 1: Hardening
**Plans:** 2/2 complete

### Phase 2: Reliability + Performance
**Plans:** 2/2 complete

### Phase 3: UX Enhancements
**Plans:** 2/2 complete

### Phase 4: Notifications
**Plans:** 2/2 complete

</details>

### v2.0 Game Boy (In Progress)

**Milestone Goal:** Transform Claumagotchi from a Tamagotchi egg into a Game Boy Color companion with voice I/O, auto-speak summaries, and hands-free interaction across all sessions.

## Phase Details

### Phase 9: Game Boy Shell + Screen
**Goal**: The widget looks and feels like a Game Boy Color — skeuomorphic shell with a larger screen that shows richer information
**Depends on**: v1.1 (phases 1-4)
**Requirements**: UI-01, UI-02, UI-03, UI-04
**Success Criteria** (what must be TRUE):
  1. The widget displays a Game Boy Color body with plastic texture, bevels, and rim highlights matching the current theme
  2. The screen area is visibly larger than v1.1 and displays the character animation, session status, and "CLAUMAGOTCHI" pixel title
  3. A/B buttons, D-pad (visual), Select/Start buttons, speaker grille, and power LED are rendered as physical-looking controls below the screen
  4. When a permission request arrives, the screen shows the tool name, file path, and action description — not just "NEEDS YOU"

### Phase 10: Infrastructure + Hook
**Goal**: The summary hook, cross-session support, and menu bar controls are wired so all downstream features have a foundation
**Depends on**: Phase 9
**Requirements**: INFRA-01, INFRA-04, INFRA-05
**Success Criteria** (what must be TRUE):
  1. When Claude finishes a response in any project, the summary hook writes the last assistant text to `~/.claude/claumagotchi/last_summary.txt`
  2. The app watches `last_summary.txt` and detects changes in real-time
  3. Menu bar provides toggles for: show/hide widget, sound effects on/off, auto-speak on/off, and power on/off
  4. Switching between Claude Code sessions in different projects does not break monitoring or summary detection

### Phase 11: Voice Input + Injection
**Goal**: Users can speak to Claude from any app — voice is recorded, transcribed on-device, and injected into the terminal without the user seeing the switch
**Depends on**: Phase 10
**Requirements**: VOICE-01, VOICE-02
**Success Criteria** (what must be TRUE):
  1. Pressing the Select button (or hotkey) starts recording; pressing again stops and submits
  2. The mic button shows a clear visual recording state (color change, animation)
  3. After transcription, text is injected into the terminal and Enter is pressed — then the previous app is refocused within 500ms
  4. Voice input works while the user is in any app (Figma, browser, etc.) — they never see the terminal switch

### Phase 12: Auto-Speak + TTS
**Goal**: When Claude finishes and auto-speak is enabled, the response is summarized and spoken aloud — users hear what Claude did without looking at the terminal
**Depends on**: Phase 10, Phase 11
**Requirements**: VOICE-03, VOICE-04
**Success Criteria** (what must be TRUE):
  1. When auto-speak is enabled and Claude finishes, the last response is summarized via Apple Intelligence and spoken using Ava Premium TTS
  2. When auto-speak is disabled, no TTS fires — the summary file is still written but not spoken
  3. User can press the mute button (or hotkey) to stop TTS mid-sentence
  4. Pressing record while TTS is speaking immediately cuts the voice and starts recording
  5. When Apple Intelligence is unavailable, the last paragraph of the response is spoken as fallback

### Phase 13: Controls + Hotkeys
**Goal**: Every action has a button and a hotkey — YOLO, power, hide, accept, deny — and hotkeys are viewable and remappable
**Depends on**: Phase 9
**Requirements**: CTRL-01, CTRL-02, CTRL-03, CTRL-04, CTRL-05, INFRA-02, INFRA-03
**Success Criteria** (what must be TRUE):
  1. A button accepts and B button denies a pending permission (with hotkeys)
  2. YOLO toggle on the shell enables/disables auto-accept with a visual slider state change
  3. Power off disables all monitoring, sounds, and permission handling — power on re-enables
  4. Hide minimizes the widget; show restores it from the menu bar
  5. Every button action has a keyboard shortcut
  6. User can view all hotkeys and remap them from the menu bar

## Progress

**Execution Order:** 9 -> 10 -> 11 -> 12 -> 13

| Phase | Milestone | Plans Complete | Status |
|-------|-----------|----------------|--------|
| 9. Game Boy Shell + Screen | v2.0 | 0/? | Pending |
| 10. Infrastructure + Hook | v2.0 | 0/? | Pending |
| 11. Voice Input + Injection | v2.0 | 0/? | Pending |
| 12. Auto-Speak + TTS | v2.0 | 0/? | Pending |
| 13. Controls + Hotkeys | v2.0 | 0/? | Pending |
