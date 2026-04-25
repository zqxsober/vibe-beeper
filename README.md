<div align="center">

# vibe-beeper

**A floating macOS desktop pager for Claude Code and Codex.**

*Stop babysitting your terminal. Never miss a completion, error, or permission prompt.*

<img src="assets/hero.gif" width="320" alt="vibe-beeper demo">

<br><br>

<a href="https://github.com/zqxsober/vibe-beeper/releases/latest/download/vibe-beeper.dmg">
  <img src="https://img.shields.io/badge/%EF%A3%BF_DOWNLOAD_FOR_MAC-DMG-black?style=for-the-badge&labelColor=555555" alt="Download for Mac">
</a>

<br><br>

[![Release](https://img.shields.io/github/v/release/zqxsober/vibe-beeper?style=flat-square)](https://github.com/zqxsober/vibe-beeper/releases/latest)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue?style=flat-square)](https://github.com/zqxsober/vibe-beeper)
[![Swift](https://img.shields.io/badge/Swift-6-orange?style=flat-square)](https://github.com/zqxsober/vibe-beeper)
[![License](https://img.shields.io/badge/license-GPL--3.0-green?style=flat-square)](LICENSE)

[中文说明](README.zh-CN.md)

</div>

---

## Why vibe-beeper exists

You launch a task in Claude Code or Codex, switch back to real work, and a few minutes later your agent is either:

- done
- waiting for approval
- blocked on a question
- buried under three terminal tabs you forgot to check

vibe-beeper pulls those events onto the desktop. It gives you a persistent LCD-style widget, menu bar status, hotkeys, audio feedback, and optional voice interaction so you can respond without breaking flow.

---

## Provider support

| Provider | Status | Notes |
| --- | --- | --- |
| Claude Code | Stable | Hooks, state sync, permission prompts, auto-approve presets, voice input, read-aloud |
| Codex | Basic integration | Detection, config markers, event translation, UI state entry points; still evolving toward parity |

If your main workflow is Claude Code, vibe-beeper is ready today. Codex support is usable, but should still be treated as an actively developing path.

---

## Features

### Desktop states at a glance

vibe-beeper tracks eight agent states and surfaces the highest-priority one across active sessions:

| State | Preview | Meaning |
| --- | --- | --- |
| **SNOOZING** | <img src="assets/states/snoozing.png" width="200"> | No active session |
| **WORKING** | <img src="assets/states/working.png" width="200"> | Agent is currently running tools |
| **DONE!** | <img src="assets/states/done.png" width="200"> | Task completed successfully |
| **ERROR** | <img src="assets/states/error.png" width="200"> | The run failed |
| **ALLOW?** | <img src="assets/states/allow.png" width="200"> | A permission request is waiting for you |
| **INPUT?** | <img src="assets/states/input.png" width="200"> | The agent asked a question |
| **LISTENING** | <img src="assets/states/listening.png" width="200"> | Voice dictation is recording |
| **RECAP** | <img src="assets/states/recap.png" width="200"> | A response is being read aloud |

### Auto-approve presets

Switch between approval modes depending on how much trust and speed you want:

| Mode | Behavior |
| --- | --- |
| **Strict** | Ask every time |
| **Relaxed** | Allow reads automatically, ask before writes and commands |
| **Trusted** | Allow file operations automatically, ask before shell commands |
| **YOLO** | Approve everything automatically |

`YOLO` is intentionally high-risk. It can approve file writes, deletes, commands, and network-related actions on your behalf.

### Voice input and read-aloud

- **WhisperKit** for on-device dictation
- **Apple Speech** as fallback transcription
- **Kokoro** for local TTS playback
- **Apple Speech** as fallback read-aloud
- Global record toggle with `⌥R`
- Optional **double clap** activation for hands-free dictation

### Widget sizes, themes, and feedback

- 10 shell colors
- 3 display modes: **Large**, **Compact**, **Menu Only**
- Sound alerts, completion chimes, vibration feedback
- A menu bar companion that mirrors the current state

![Shell colors](assets/shell-colors.png)

---

## Installation

### Requirements

- macOS 14 Sonoma or newer
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI for the full supported workflow
- Codex CLI if you want to enable Codex integration
- Xcode Command Line Tools / Swift 6 if you plan to build from source

### Option 1: Install from a release

1. Download the latest [release](https://github.com/zqxsober/vibe-beeper/releases).
2. Move `vibe-beeper.app` into `/Applications`.
3. Launch the app.
4. Complete onboarding to install hooks, choose theme/size, configure permissions, and optionally download voice models.

This is the simplest path for most users.

### Option 2: Build from source

```bash
git clone https://github.com/zqxsober/vibe-beeper.git
cd vibe-beeper
swift test
SKIP_INSTALL=1 ./build.sh
open vibe-beeper.app
```

Notes:

- `SKIP_INSTALL=1 ./build.sh` builds a local `.app` bundle in the repo without touching `/Applications`.
- Running `./build.sh` without `SKIP_INSTALL=1` will replace `/Applications/vibe-beeper.app`.
- `make install` builds the app, runs the Claude hook setup helper, and opens the installed app.

---

## First launch checklist

When vibe-beeper starts for the first time, the recommended flow is:

1. Detect installed CLIs
2. Install Claude Code hooks
3. Install Codex hooks if Codex is present and you want it enabled
4. Grant accessibility, microphone, and speech recognition permissions as needed
5. Download optional local voice models for WhisperKit and Kokoro
6. Pick a shell color, widget size, approval preset, and hotkeys
7. Restart any Claude Code or Codex sessions that were already running before hooks were installed

If something looks stale later, open **Settings → Setup** and reinstall hooks or reopen onboarding.

---

## Everyday usage

### Responding to permissions

- Use the on-screen buttons on the large widget
- Or use global hotkeys:
  - `⌥A` approve
  - `⌥D` deny

### Voice workflows

- `⌥R` toggles dictation
- `⌥M` stops or replays spoken output
- Double clap can start dictation if enabled in settings

### Jumping back to your terminal

- `⌥T` focuses the active terminal window
- The widget and menu bar are meant to reduce terminal tab babysitting, not replace your CLI

### Menu bar behavior

The menu bar companion exposes:

- current state
- mute / unmute
- sleep / wake
- clap dictation toggle
- approval mode switching
- widget size switching
- settings and hook repair entry points

---

## Development commands

Useful commands when working on the project locally:

```bash
swift test                     # run the Swift test suite
SKIP_INSTALL=1 ./build.sh      # build a local app bundle only
make install                   # build, configure Claude hooks, launch the app
make uninstall                 # remove installed hooks and stop the app
make dmg                       # build a DMG from the current source tree
```

Behavior notes:

- `scripts/setup.py` installs Claude hooks into `~/.claude/settings.json`
- Codex integration is managed through the app onboarding/settings flow
- `scripts/uninstall.py` removes both Claude and Codex hook/config traces managed by vibe-beeper

---

## How it works

### Local-only event transport

vibe-beeper listens on `127.0.0.1` and receives hook payloads from local CLI integrations. No cloud relay is required.

### Claude Code

Claude hook configuration is written into:

```text
~/.claude/settings.json
```

The helper script and IPC metadata live under:

```text
~/.claude/hooks
~/.claude/cc-beeper
```

### Codex

Codex-related markers and hook metadata are managed in the user's local Codex configuration files:

```text
~/.codex/config.toml
~/.codex/hooks.json
```

### Multi-session priority

If several sessions are active at once, vibe-beeper shows the highest-priority state instead of the most recent one, so urgent prompts do not get hidden behind lower-priority completions.

---

## Privacy

> **Everything is designed to stay on your Mac.**

- No telemetry
- No analytics
- No sign-in
- No mandatory cloud account
- No API key required for the built-in local voice pipeline
- WhisperKit and Kokoro run on-device

You can inspect or remove local hook configuration at any time.

---

## Limitations and risk boundaries

- `YOLO` mode can approve risky operations automatically. Use it only when you fully trust the current workspace and task.
- Codex support is still not at full Claude Code parity.
- The app depends on local CLI hook behavior, so existing sessions may need a restart after setup changes.

---

## Contributing

Issues, docs improvements, bug reports, and pull requests are welcome.

Suggested flow:

1. Fork the repo
2. Create a branch
3. Run `swift test`
4. Make your changes
5. Open a pull request

---

## Disclaimer

vibe-beeper is an independent open-source project. It is not affiliated with, endorsed by, or sponsored by Anthropic or OpenAI.

The project started from the CC-Beeper lineage and continues as a community-maintained macOS companion for agent workflows.

---

## License

GPL-3.0. See [LICENSE](LICENSE).

---

<div align="center">

Open Source · Native macOS · Built for agent-heavy workflows

If vibe-beeper saves you from one missed permission prompt, a GitHub star helps a lot.

</div>
