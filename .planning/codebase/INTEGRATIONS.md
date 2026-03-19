# External Integrations

**Analysis Date:** 2026-03-19

## APIs & External Services

**Claude Code:**
- Integration: Receives events via hook system
- Hook registration: Installed to `~/.claude/hooks/claumagotchi-hook.py`
- Event types: PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest, Notification, Stop, SessionStart, SessionEnd
- Communication: Hook writes JSON events to IPC files

## Data Storage

**Databases:**
- None - All state is ephemeral or persisted locally

**File Storage:**
- Local filesystem only (no cloud storage)
- Configuration directory: `~/.claude/claumagotchi/` (IPC directory)

**Caching:**
- In-memory only (UserDefaults for persistent preferences)
- Events file auto-truncates at 50KB to prevent unbounded growth

## Persistent Configuration

**User Preferences (via UserDefaults):**
- `soundEnabled` - Audio notifications toggle (default: true)
- `autoAccept` - Auto-approve all permissions toggle (default: false)
- `themeId` - Selected color theme (default: "sunset")
- `darkMode` - Dark mode toggle (default: false)

**Files Created During Setup:**
- `~/.claude/claumagotchi/` - IPC directory (created with 0700 permissions)
- `~/.claude/hooks/claumagotchi-hook.py` - Hook script
- `~/.claude/hooks/claumagotchi-app-path` - Path to app bundle
- `~/.claude/claumagotchi/claumagotchi.pid` - Process ID file (cleanup on exit)

## IPC Communication Protocol

**Event File:**
- Location: `~/.claude/claumagotchi/events.jsonl`
- Format: Newline-delimited JSON
- Read by: SwiftUI app watches with DispatchSource for file changes
- Max size: 50KB (auto-truncates oldest events)
- Example event: `{"event": "thinking", "tool": "Bash", "ts": 1234567890, "sid": "session-123"}`

**Permission Request:**
- Pending file: `~/.claude/claumagotchi/pending.json`
- Hook writes: `{"id": "hex-token", "tool": "Bash", "summary": "echo hello", "ts": 1234567890}`
- App reads and displays in UI
- Timeout: 55 seconds (hook timeout is 60s)

**Permission Response:**
- Response file: `~/.claude/claumagotchi/response.json`
- App writes: `{"id": "matching-hex-token", "decision": "allow" | "deny"}`
- Hook reads and forwards decision to Claude Code
- File cleanup: Both pending.json and response.json deleted after read

**Session Tracking:**
- Sessions file: `~/.claude/claumagotchi/sessions.json`
- Tracks active session IDs with timestamps
- Sessions pruned after 2 hours (matches hook's 7200s pruning)
- Used for aggregating state across multiple concurrent Claude Code sessions

## Authentication & Identity

**Auth Provider:**
- None - Claumagotchi is a local system utility without authentication

**Process Authorization:**
- Runs as user (via menu bar accessory)
- Requires Claude Code CLI configured locally
- Single-instance enforcement via PID file at `~/.claude/claumagotchi/claumagotchi.pid`

## System Integration

**Terminal Detection:**
- Looks for running terminal applications by bundle identifier
- Supported: Terminal, iTerm2, Warp, Alacritty, Kitty, WezTerm
- Used by "Go to Conversation" button to switch focus

**Desktop Integration:**
- Menu bar extra (system menu bar icon)
- Floating window (level = floating, no title bar)
- Window appears on all spaces (`collectionBehavior = canJoinAllSpaces`)
- Auto-constrained to screen bounds

**Audio Alerts:**
- Notification sound: "Ping" (system sound)
- Completion sound: "Pop" (system sound)
- Toggled via `soundEnabled` UserDefaults

**Window Management:**
- Single-instance enforcement prevents multiple Claumagotchi windows
- Auto-launch on Claude Code session start (via hook)
- Manual launch via `open Claumagotchi.app`

## Webhooks & Callbacks

**Incoming:**
- Hook receives JSON on stdin from Claude Code
- Maps hook event names to internal events
- Writes response to stdout for hook system integration

**Outgoing:**
- No outgoing webhooks or HTTP requests
- Communicates only via local file system (IPC)

## File Security

**IPC Directory Permissions:**
- Created with mode `0o700` (owner read/write/execute only)
- Enforced before creating any IPC files

**File Permissions:**
- Event file: `0o600` (owner read/write only)
- Pending file: `0o600` (owner read/write only)
- Response file: `0o600` (owner read/write only)
- Sessions file: `0o700` (owner read/write/execute only)
- Lock file: `0o600` (owner read/write only)

**Symlink Protection:**
- All write operations (`safe_write` and `safe_append` in hook)
- Reject symlinks before writing to prevent file substitution attacks
- Atomic writes via tempfile + rename pattern

## Logging & Observability

**Error Tracking:**
- None - Debug/error information printed to stdout/stderr during build

**Logs:**
- App process logging: Accessible via Console.app or `log stream`
- Hook logging: Prints JSON output to stdout (captured by Claude Code)
- No persistent log files created

## Integration Points with Claude Code

**Hook Events Handled:**
1. **SessionStart** - Triggers auto-launch of app if not running
2. **SessionEnd** - Tracks session end for aggregation
3. **PermissionRequest** - Blocks hook, waits for user decision in app, forwards response
4. **PreToolUse** - Records tool name and type
5. **PostToolUse** - Records completion
6. **PostToolUseFailure** - Records error tool execution
7. **Notification** - Passes through with notification type
8. **Stop** - Records session stop event

**Hook Configuration:**
- Event-based hook registration via Claude Code settings.json
- Different timeouts per event type (5-60 seconds)
- Command: `python3 ~/.claude/hooks/claumagotchi-hook.py`

---

*Integration audit: 2026-03-19*
