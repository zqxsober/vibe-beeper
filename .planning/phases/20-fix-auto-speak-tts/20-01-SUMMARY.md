---
phase: 20-fix-auto-speak-tts
plan: 01
subsystem: hook
tags: [python, tts, hook, ipc, claude-code]

requires:
  - phase: 19-cleanup
    provides: clean codebase with zero Claumagotchi references; cc-beeper-hook.py as canonical hook

provides:
  - Stop event in cc-beeper-hook.py now extracts last assistant text and writes last_summary.txt
  - ClaudeMonitor's existing file watcher can now trigger TTS on session end

affects:
  - 20-02 (TTS provider/Groq plan, depends on summary file being written correctly)

tech-stack:
  added: []
  patterns:
    - "Stop handler branch in main() after event write — use safe_write(SUMMARY_FILE) for atomic, symlink-safe file output"
    - "Session JSONL walk with fallback to most-recently-modified file — session_id first, then most recent"

key-files:
  created: []
  modified:
    - Sources/cc-beeper-hook.py
  deleted:
    - hooks/summary-hook.py

key-decisions:
  - "D-01 honored: merged summary extraction directly into cc-beeper-hook.py Stop handler — no second hook registration needed"
  - "hooks/summary-hook.py deleted — Sources/cc-beeper-hook.py is now the single canonical copy"
  - "Used safe_write() for atomic, symlink-safe file write — required for ClaudeMonitor DispatchSource watcher to pick up .rename event"

patterns-established:
  - "Stop handler pattern: after event write, branch on event_name == 'Stop', extract JSONL text, write via safe_write"

requirements-completed: [FIX-01]

duration: 1min
completed: 2026-03-25
---

# Phase 20 Plan 01: Fix Auto-Speak TTS — Hook Wiring Summary

**Stop event in cc-beeper-hook.py now extracts last assistant text from session JSONL and writes ~/.claude/cc-beeper/last_summary.txt via safe_write, enabling ClaudeMonitor's file watcher to trigger TTS on session end**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-03-25T22:35:56Z
- **Completed:** 2026-03-25T22:37:20Z
- **Tasks:** 1
- **Files modified:** 2 (1 modified, 1 deleted)

## Accomplishments

- Added `SUMMARY_FILE` constant to `Sources/cc-beeper-hook.py` pointing to `~/.claude/cc-beeper/last_summary.txt`
- Added `get_session_jsonl()`, `get_most_recent_jsonl()`, and `extract_last_assistant_text()` functions (ported from the standalone `hooks/summary-hook.py`)
- Added Stop event branch in `main()` that writes the last assistant message to `SUMMARY_FILE` using `safe_write()` for atomic, symlink-safe output
- Deleted `hooks/summary-hook.py` — its logic now lives entirely in `Sources/cc-beeper-hook.py`

## Task Commits

Each task was committed atomically:

1. **Task 1: Merge summary extraction into cc-beeper-hook.py Stop handler and delete standalone script** - `4f8b1e4` (fix)

**Plan metadata:** (docs commit to follow)

## Files Created/Modified

- `Sources/cc-beeper-hook.py` - Added SUMMARY_FILE constant, three JSONL helper functions, and Stop event summary write branch
- `hooks/summary-hook.py` - DELETED (logic merged into Sources/cc-beeper-hook.py)

## Decisions Made

- D-01 honored: merging into the existing Stop handler means HookInstaller.swift requires no changes (it already registers Stop with cc-beeper-hook.py)
- Used `safe_write()` rather than plain `open().write()` — ensures atomic rename, which triggers the `.rename` event in ClaudeMonitor's DispatchSource watcher
- No changes to HookInstaller.swift or ClaudeMonitor.swift as specified in plan

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- The Stop-to-summary-file pipeline is now fully wired
- Plan 02 (TTS provider selection: Groq/OpenAI/Apple) can proceed — it depends on ClaudeMonitor reading the summary file (already wired) and TTSService routing by provider (the next plan's scope)
- No blockers

---
*Phase: 20-fix-auto-speak-tts*
*Completed: 2026-03-25*
