<p align="center">
  <!-- TODO: Replace with new hero GIF showing full IDLE → WORKING → APPROVE? → DONE cycle -->
  <img src="docs/cover.png" alt="CC-Beeper" width="700">
</p>

# CC-Beeper

<p align="center">
  A retro pager companion for Claude Code. See what Claude is doing. Talk back.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-26%2B-black?style=flat-square" alt="macOS 26+">
  <img src="https://img.shields.io/badge/Swift-6.2-orange?style=flat-square" alt="Swift 6.2">
  <img src="https://img.shields.io/badge/license-GPL--3.0-blue?style=flat-square" alt="GPL-3.0 License">
</p>

<p align="center">
  <a href="https://github.com/vecartier/cc-beeper/releases/latest"><strong>Download CC-Beeper</strong></a> · <code>brew install vecartier/tap/cc-beeper</code>
</p>

---

## Install

### Download (recommended)

[Download CC-Beeper.dmg](https://github.com/vecartier/cc-beeper/releases/latest) — open, drag to Applications, follow the setup wizard. Done in under 60 seconds.

### Homebrew

```bash
brew install vecartier/tap/cc-beeper
```

### Build from source

```bash
git clone https://github.com/vecartier/cc-beeper.git
cd cc-beeper
make install
```

`make install` builds the app, installs the Claude Code hooks, and launches CC-Beeper. Requires Xcode Command Line Tools (Swift 6.2).

---

## What is CC-Beeper?

CC-Beeper is a floating macOS widget that sits on your desktop like a retro pager. Its LCD display updates in real time as Claude Code works — no terminal watching, no tab-switching. Just glance at the beeper to know what Claude is doing, and respond with a tap or a hotkey.

<!-- TODO: Screenshot of beeper on desktop next to terminal -->

---

## LCD States

The LCD display is the heart of CC-Beeper. Each state has a distinct pixel-art character animation, color, and rhythm so you can tell what's happening from across the room.

<!-- TODO: Strip image showing all states side by side -->

| State | LCD Text | What it means | Animation |
|-------|----------|---------------|-----------|
| **IDLE** | `ZZZ...` | No active session. Beeper is sleeping. | Static — no animation. Dim backlight. |
| **WORKING** | `WORKING` + tool context | Claude is busy — running commands, editing files, reasoning. | Horizontal scanner bar. Active green tint. |
| **DONE** | `DONE!` | Claude finished. Your turn. | Brief green flash, then fades to idle after 3 seconds. |
| **APPROVE?** | `APPROVE?` + tool context | Claude needs permission for a tool. **Go now.** | Fast blink (0.8s cycle). Warm yellow/orange. Urgent. |
| **NEEDS INPUT** | `NEEDS INPUT` | Claude asked you a question. Not a permission — a real question. | Slow steady blink (2s cycle). Cool blue/cyan. Calm. |
| **ERROR** | `ERROR` + reason | Something broke — rate limit, connection lost, crash. | Single red flash, then static hold until next event. |
| **LISTENING** | `LISTENING` | Recording your voice — speak your message to Claude. | Mic pulse animation. |
| **SPEAKING** | `SPEAKING` | Reading Claude's response aloud. | Speaker pulse animation. |

### APPROVE? vs NEEDS INPUT

These are the two "go check your terminal" states. They look and feel completely different on purpose:

- **APPROVE?** = Claude is **blocked and waiting**. Fast blink, warm color. The feeling is *go now*.
- **NEEDS INPUT** = Claude **asked a question**. Slow blink, cool color. The feeling is *when you get a chance*.

In YOLO mode, permission prompts (APPROVE?) are auto-approved silently. Questions (NEEDS INPUT) always surface — they're not permissions, they're Claude asking you something real.

---

## Permission Spectrum

Switch Claude Code's permission behavior from the menu bar without touching JSON files. Four presets, one click.

<!-- TODO: Screenshot of permission menu with all 4 presets -->

| Preset | What it does | LCD Badge |
|--------|-------------|-----------|
| **Strict** | Ask before every action. Full manual control. | STRICT |
| **Relaxed** | Auto-approve reads (Read, Glob, Grep). Ask for writes and commands. | RELAXED |
| **Cautious** | Auto-approve all file operations. Ask for shell commands. | CAUTIOUS |
| **YOLO** | Auto-approve everything. No prompts. Full speed. | YOLO |

The current preset is shown as a badge on the LCD. In YOLO mode, the pixel-art character swaps to a rabbit — because you're living fast.

<!-- TODO: Side-by-side of normal character vs YOLO rabbit -->

Preset changes write directly to Claude Code's `~/.claude/settings.json`. Non-YOLO presets auto-approve matching tools through CC-Beeper's hook responses. YOLO sets Claude Code's native bypass mode.

---

## Widget Sizes

Three sizes depending on how much screen real estate you want to give up.

<!-- TODO: Screenshot strip showing all 3 sizes -->

| Size | What you see | How to interact |
|------|-------------|-----------------|
| **Large** | Full beeper with LCD + buttons (Accept/Deny, Record, Sound, Terminal) | Click buttons or use hotkeys |
| **Compact** | LCD screen only — no buttons, smaller footprint | Hotkeys only |
| **Menu Only** | No widget on screen — just the menu bar icon | Menu bar + hotkeys |

Switch between sizes from the menu bar icon > Size menu. Your choice persists across launches.

---

## Voice

CC-Beeper has two voice features: talking to Claude and hearing Claude talk back.

### Voice Record (Speech-to-Text)

Press the record button or hit **Option R** from any app. Speak your message. CC-Beeper transcribes it on-device using WhisperKit and injects the text directly into your active Claude Code session.

- On-device — nothing leaves your machine
- 99 languages supported
- Selectable model size (small / medium) in settings

### Voice Reader (Text-to-Speech)

When Claude finishes a response, CC-Beeper can read it aloud. Uses Kokoro (on-device AI voices) with Apple TTS as fallback.

- 9 language codes: English (US/UK), French, Spanish, Italian, Portuguese, Hindi, Japanese, Chinese
- Multiple voices per language — male and female options
- Single language preference drives both STT and TTS

---

## Themes

10 shell colors with dark mode support. Pick your pager.

<!-- TODO: Grid showing all 10 color shells -->

Black, Blue, Green, Mint, Orange, Pink, Purple, Red, White, Yellow.

Dark mode changes the LCD colors to match — toggle in settings or follow system.

---

## Global Hotkeys

All hotkeys use **Option** as the modifier. Remap them in settings.

| Shortcut | Action |
|----------|--------|
| **Option A** | Accept permission |
| **Option D** | Deny permission |
| **Option R** | Voice record (push to talk) |
| **Option T** | Go to terminal |
| **Option M** | Voice reader / stop |

Hotkeys are layout-independent — they resolve the physical key via your current keyboard layout (AZERTY, QWERTZ, etc.).

---

## How it works

CC-Beeper registers lightweight hooks with Claude Code's [hooks system](https://docs.anthropic.com/en/docs/claude-code/hooks). When Claude uses a tool, finishes a task, or needs your input, it fires an HTTP event to CC-Beeper's local server. CC-Beeper updates the LCD instantly.

```
Claude Code  ──►  Hook (curl)  ──►  http://localhost:{port}/hook  ──►  CC-Beeper.app
                                                                         │
                                    Permission? ◄─── HTTP response ◄────┘
                                    (allow/deny)     (held open until
                                                      user decides)
```

- **Monitoring hooks** (PreToolUse, PostToolUse, Stop, StopFailure) are async — CC-Beeper never blocks Claude.
- **Permission hooks** (Notification, PermissionRequest) are blocking — CC-Beeper holds the connection until you approve or deny, then sends the decision back through the HTTP response.
- If CC-Beeper isn't running, hooks timeout silently. Zero impact on Claude Code.

---

## Requirements

- macOS 26 or later
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- (Optional) On-device voice models (~930 MB) — downloaded through the setup wizard

---

## Important disclaimer

> CC-Beeper lets you approve or deny Claude Code tool requests directly from the widget. **You are responsible for reviewing what you approve.** Clicking "Allow" grants Claude Code permission to execute the requested action on your machine.
>
> **YOLO mode** automatically approves every permission request without prompting. When enabled, Claude Code will execute all tool calls — including file modifications, shell commands, and network requests — without asking for confirmation. **Use YOLO mode at your own risk.**
>
> The authors are not liable for any damage, data loss, or unintended consequences. By using CC-Beeper, you accept these risks.

---

## Contributing

Contributions are welcome.

1. Fork the repo and create a feature branch
2. CC-Beeper is a Swift Package — open `Package.swift` in Xcode or build with `make build`
3. Submit a pull request with a clear description

CC-Beeper uses Claude Code's [hooks system](https://docs.anthropic.com/en/docs/claude-code/hooks) for communication. See the hook architecture in [How it works](#how-it-works).

- **Bug reports:** open a GitHub issue
- **Feature requests:** open a GitHub discussion

---

## License

GPL-3.0 — see [LICENSE](LICENSE)
