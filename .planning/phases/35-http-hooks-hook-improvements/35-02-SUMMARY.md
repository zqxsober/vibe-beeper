---
phase: 35-http-hooks-hook-improvements
plan: "02"
subsystem: monitor
tags: [http-hooks, ipc, state-machine, tts, cleanup]
dependency_graph:
  requires: [35-01]
  provides: [HTTP-wired ClaudeMonitor, file-IPC-removed, Python-hook-deleted]
  affects: [Sources/Monitor/ClaudeMonitor.swift, Sources/App/CCBeeperApp.swift, Package.swift]
tech_stack:
  added: []
  patterns: [HTTP-payload-translation, synthetic-JSONL-event, age-based-session-pruning]
key_files:
  created: []
  modified:
    - Sources/Monitor/ClaudeMonitor.swift
    - Sources/App/CCBeeperApp.swift
    - Package.swift
  deleted:
    - Sources/cc-beeper-hook.py
decisions:
  - "deinit cannot call @MainActor httpServer.stop() directly — port file cleanup moved to applicationWillTerminate in AppDelegate instead"
  - "sessionLastSeen [String: Date] dict replaces sessions.json-based pruning — no file I/O needed for session lifecycle"
  - "permission_prompt handler returns sentinel dict to HTTPHookServer to hold connection; non-permission notifications are passed through as-is"
metrics:
  duration: "319s"
  completed_date: "2026-03-29"
  tasks_completed: 2
  files_changed: 4
---

# Phase 35 Plan 02: HTTP Hook Wiring + File IPC Removal Summary

HTTP-wired ClaudeMonitor with handleHookPayload() translator, Stop-event TTS via last_assistant_message, and full removal of all file-based IPC (JSONL watcher, summary watcher, Python hook script, pending/response.json).

## What Was Built

### Task 1: Wire HTTP Server to ClaudeMonitor, Remove All File-Based IPC

Rewrote `ClaudeMonitor.swift` to:

1. **Added `HTTPHookServer` property** — `private let httpServer = HTTPHookServer()` started in `init()` and `isActive.didSet`.

2. **Added `handleHookPayload()` method** — translates HTTP hook payloads to synthetic JSONL events and routes them through the existing `processEvent()` state machine:
   - `PreToolUse` → `pre_tool`
   - `PostToolUse` → `post_tool`
   - `Notification` (permission_prompt) → builds synthetic event with summary/tool, returns sentinel to hold HTTP connection
   - `Notification` (other) → `notification` (state machine ignores unknown types)
   - `Stop` → `stop` + extracts `last_assistant_message` for TTS
   - `StopFailure` → `stop` (error context is Phase 36)

3. **TTS from Stop events** — `last_assistant_message` field extracted directly from HTTP payload, no more `last_summary.txt` file parsing.

4. **Rewrote `respondToPermission()`** — sends `hookSpecificOutput` JSON response via `httpServer.sendPermissionResponse()` instead of writing `response.json`.

5. **Updated `processEvent()` permission handler** — reads permission details from synthetic event dict (tool + summary), no more `loadPendingPermission()` / `pending.json` reads.

6. **Updated `updateAggregateState()`** — replaced `sessions.json`-based pruning with `sessionLastSeen: [String: Date]` dictionary. Sessions not seen for 2 hours are pruned.

7. **Updated `isActive.didSet`** — calls `httpServer.start()` / `httpServer.stop()` instead of file watcher setup/teardown.

8. **Deleted methods/properties:**
   - `setupFileWatcher()`, `restartFileWatcher()`
   - `setupSummaryWatcher()`, `onSummaryFileChanged()`
   - `readNewEvents()`, `rehydrateSessions()`, `loadPendingPermission()`
   - `static let eventsFile`, `pendingFile`, `responseFile`
   - `private static let summaryFile`
   - `fileHandle`, `source`, `summarySource`, `lastSummaryHash`

9. **Updated `applicationWillTerminate`** in `CCBeeperApp.swift` to remove port file on quit (since `deinit` cannot call `@MainActor httpServer.stop()` directly).

### Task 2: Delete Python Hook Script, Clean Package.swift

- Deleted `Sources/cc-beeper-hook.py` (373 lines, entire Python hook script)
- Removed `.copy("cc-beeper-hook.py")` resource entry from Package.swift
- Removed the now-empty `resources:` block entirely from `executableTarget`
- Build verified clean

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| `deinit` cannot call `httpServer.stop()` | `HTTPHookServer` is `@MainActor`, `deinit` is `nonisolated` — calling across actor context requires async, which deinit can't do. Port file cleanup moved to `applicationWillTerminate` instead. |
| `sessionLastSeen` dict replaces `sessions.json` | The HTTP server doesn't write sessions.json — session lifecycle is tracked naturally from events arriving. Age-based pruning (2h) handles stale sessions without file I/O. |
| Sentinel return `["_hold_connection": true]` for permission_prompt | Matches HTTPHookServer's existing logic: non-nil return = blocking hook, holds NWConnection for deferred response via `sendPermissionResponse()`. |
| `Notification` events without `permission_prompt` type passed through | Non-permission notifications (auth_success, idle_prompt, etc.) are processed as generic notification events — state machine ignores unknown types, safe to pass through. |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] deinit actor isolation conflict with httpServer.stop()**
- **Found during:** Task 1 compilation
- **Issue:** `httpServer.stop()` is `@MainActor`, but `ClaudeMonitor.deinit` is `nonisolated` — Swift compiler error: "call to main actor-isolated instance method 'stop()' in a synchronous nonisolated context"
- **Fix:** Removed `httpServer.stop()` from `deinit`. Added `try? FileManager.default.removeItem(atPath: HTTPHookServer.portFile)` to `applicationWillTerminate` in `AppDelegate` for port file cleanup on quit. The `isActive.didSet` already calls `httpServer.stop()` when toggled off, covering the runtime lifecycle path.
- **Files modified:** `Sources/Monitor/ClaudeMonitor.swift`, `Sources/App/CCBeeperApp.swift`
- **Commit:** af6d9c5

## Verification Results

- `swift test` — 16/16 tests pass
- `Sources/Monitor/ClaudeMonitor.swift` contains `private let httpServer = HTTPHookServer()` ✓
- `Sources/Monitor/ClaudeMonitor.swift` contains `httpServer.start` ✓
- `Sources/Monitor/ClaudeMonitor.swift` contains `httpServer.stop()` ✓
- `Sources/Monitor/ClaudeMonitor.swift` contains `handleHookPayload` ✓
- `Sources/Monitor/ClaudeMonitor.swift` contains `hook_event_name` ✓
- `Sources/Monitor/ClaudeMonitor.swift` contains `last_assistant_message` ✓
- `Sources/Monitor/ClaudeMonitor.swift` contains `voice.log` ✓
- `Sources/Monitor/ClaudeMonitor.swift` contains `httpServer.sendPermissionResponse` ✓
- No file watcher methods remain ✓
- No file path constants (`eventsFile`, `pendingFile`, `responseFile`, `summaryFile`) remain ✓
- `Sources/cc-beeper-hook.py` does NOT exist ✓
- `Package.swift` does NOT contain `cc-beeper-hook.py` ✓
- `Package.swift` does NOT contain empty `resources:` array ✓
- `swift build` completes without errors ✓

## Commits

| Task | Commit | Message |
|------|--------|---------|
| Task 1 | af6d9c5 | feat(35-02): wire HTTP server to ClaudeMonitor, remove all file-based IPC |
| Task 2 | c5fbe25 | chore(35-02): delete Python hook script and remove from Package.swift resources |

## Known Stubs

None.

## Self-Check: PASSED

- `Sources/Monitor/ClaudeMonitor.swift` — FOUND
- `Sources/App/CCBeeperApp.swift` — FOUND
- `Package.swift` — FOUND
- `Sources/cc-beeper-hook.py` — CONFIRMED DELETED
- Commits af6d9c5 and c5fbe25 — FOUND
