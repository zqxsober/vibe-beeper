---
phase: 01-hardening
verified: 2026-03-19T15:00:00Z
status: passed
score: 5/5 must-haves verified
re_verification: false
---

# Phase 1: Hardening Verification Report

**Phase Goal:** Known bugs are fixed and the IPC permission flow fails closed, not open
**Verified:** 2026-03-19
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (from ROADMAP.md Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | YOLO mode shows a distinct visual indicator in the menu bar (not orange like needsYou — a separate state) | VERIFIED | `enum EggIconState` with `.yolo` case maps to `.systemPurple`; `img.isTemplate = (state == .normal)` ensures color renders. `monitor.yoloIconState` wired into `MenuBarExtra` label at line 62. |
| 2 | The main window opens and closes reliably, regardless of its title string | VERIFIED | Both `toggleMainWindow()` (line 68) and `showMainWindow()` (line 76) use `window.identifier?.rawValue == "main"`. No occurrence of `window.title == "Claumagotchi"` remains in the file. |
| 3 | A malformed, empty, or missing-key response.json results in a deny decision — Claude Code never auto-allows due to bad data | VERIFIED | `resp.get("decision", "deny")` at line 246 of hook; `if decision not in ("allow", "deny"): decision = "deny"` at line 247-248. No `"decision", "allow"` remains in the hook. |
| 4 | Events with unexpected schema are rejected before processing, not silently passed through | VERIFIED | `processEvent` guard (lines 177-181) requires `event["sid"] is String` and `event["ts"] is Int` before any processing. Both checks are inside the same guard statement as `let type = event["event"] as? String`. |
| 5 | A response.json written before the permission request was issued is ignored (stale timestamp check) | VERIFIED | `pending_ts = int(time.time())` captured before `safe_write(PENDING_FILE, ...)` (line 209). `resp_mtime = os.path.getmtime(RESPONSE_FILE)` compared at `resp_mtime < pending_ts - 2` (lines 229-230). Stale file is removed and loop `continue`s. |

**Score:** 5/5 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Sources/ClaumagotchiApp.swift` | EggIconState enum, refactored EggIcon.image(state:), identifier-based window lookup | VERIFIED | `enum EggIconState` at line 87 with `.normal`/`.attention`/`.yolo`; `static func image(state: EggIconState)` at line 94; `.systemPurple` at line 99; `img.isTemplate = (state == .normal)` at line 127; both window functions use `identifier?.rawValue == "main"` |
| `Sources/ClaudeMonitor.swift` | yoloIconState computed property, schema validation guards | VERIFIED | `var yoloIconState: EggIconState` at lines 53-57; `if autoAccept { return .yolo }` at line 54; `event["sid"] is String` and `event["ts"] is Int` guards at lines 180-181 |
| `hooks/claumagotchi-hook.py` | Default-deny with whitelist validation, freshness check using mtime | VERIFIED | `resp.get("decision", "deny")` at line 246; `if decision not in ("allow", "deny"):` at line 247; `pending_ts = int(time.time())` at line 209; `os.path.getmtime(RESPONSE_FILE)` at line 229; `resp_mtime < pending_ts - 2` at line 230 |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `Sources/ClaumagotchiApp.swift` | `Sources/ClaudeMonitor.swift` | `monitor.yoloIconState` in MenuBarExtra label | WIRED | Line 62: `Image(nsImage: EggIcon.image(state: monitor.yoloIconState))` — the computed property is called directly in the menu bar label closure |
| `Sources/ClaudeMonitor.swift` | processEvent guard clause | `event["sid"] is String` and `event["ts"] is Int` type checks | WIRED | Lines 180-181 are inside the existing `guard let data ... let type ... else { return }` block — both checks integrated into the single guard, consistent error path |
| `hooks/claumagotchi-hook.py` | response.json decision handling | `resp.get("decision", "deny")` default + whitelist guard | WIRED | Lines 246-248: default-deny get() immediately followed by whitelist normalization, both upstream of the `output` dict that is printed |
| `hooks/claumagotchi-hook.py` | response.json freshness check | `os.path.getmtime` comparison against `pending_ts` | WIRED | `pending_ts` captured at line 209, used in freshness comparison at line 230 within the `if resp.get("id") == req_id:` block — stale path removes file and `continue`s polling loop |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| BUG-01 | 01-01-PLAN.md | YOLO mode shows a distinct visual indicator in the menu bar icon | SATISFIED | `EggIconState.yolo` maps to `.systemPurple` in `EggIcon.image(state:)`; `isTemplate = false` ensures color renders; `yoloIconState` wired to menu bar |
| BUG-02 | 01-01-PLAN.md | Window lookup uses a stable identifier instead of matching by title string | SATISFIED | Both `toggleMainWindow()` and `showMainWindow()` use `window.identifier?.rawValue == "main"`; no title-string lookup remains |
| BUG-03 | 01-02-PLAN.md | Malformed or empty permission response defaults to deny, not allow | SATISFIED | `resp.get("decision", "deny")` is the default; whitelist guard handles unexpected values |
| SEC-01 | 01-02-PLAN.md | Permission response file defaults to deny when decision key is missing or malformed | SATISFIED | Same implementation as BUG-03 — same code path covers both requirements |
| SEC-02 | 01-01-PLAN.md | Event JSON is validated against expected schema before processing | SATISFIED | `event["sid"] is String` and `event["ts"] is Int` guards reject non-conforming events before any state mutation |
| SEC-03 | 01-02-PLAN.md | Response file is checked for freshness (timestamp) to prevent stale/pre-written responses | SATISFIED | `resp_mtime < pending_ts - 2` freshness check; stale files are removed and polling continues |

**All 6 required IDs from REQUIREMENTS.md Phase 1 are satisfied. No orphaned requirements detected.**

---

### Anti-Patterns Found

No significant anti-patterns found in modified files.

- No TODO/FIXME/PLACEHOLDER comments in `Sources/ClaumagotchiApp.swift` or `Sources/ClaudeMonitor.swift`
- No stub returns (`return null`, `return {}`, empty handlers) in the changed code paths
- No `console.log`-only handlers
- `processEvent` guard correctly returns (not crashes) on invalid input — intentional fail-closed behavior, not a stub

---

### Human Verification Required

The following items cannot be verified programmatically:

#### 1. Menu bar icon color distinction at runtime

**Test:** Launch the app, enable YOLO mode via "Enable YOLO Mode" in the menu bar, observe the menu bar icon color.
**Expected:** Icon appears purple (not orange, not black/template) when YOLO mode is active; reverts to orange when a permission is pending with YOLO off; shows as black/adaptive template otherwise.
**Why human:** Color rendering in the macOS menu bar depends on system theme, compositing pipeline, and whether the icon `isTemplate` flag is honored correctly — cannot be verified from source alone.

#### 2. Window show/hide stability

**Test:** Click "Show / Hide" repeatedly. Also open a second terminal and run `open Claumagotchi.app` while the app is running. Verify the window toggles and reopens correctly.
**Expected:** Window toggles reliably; no "window not found" silent failure; reopening the app from Finder does not open a second window.
**Why human:** Window identifier lookup behavior at runtime depends on AppKit window lifecycle — the identifier assignment by SwiftUI's `Window(id:)` is verified in code but runtime behavior requires observation.

#### 3. Stale response.json rejection in a live IPC round-trip

**Test:** Pre-write a response.json with `{"id": "fake", "decision": "allow"}` to `~/.claude/claumagotchi/response.json`, then trigger a real permission request via Claude Code.
**Expected:** The pre-written file is ignored (mtime predates pending_ts); the hook continues waiting; a fresh user response is required.
**Why human:** The freshness check uses filesystem mtime which is environment-dependent; verifying the 2-second tolerance behavior requires a live round-trip test.

---

### Gaps Summary

No gaps found. All 5 observable truths are verified, all 3 artifacts are substantive and wired, all 4 key links are confirmed present in the actual codebase, and all 6 requirement IDs from REQUIREMENTS.md are satisfied.

The implementation matches the plan specifications exactly — no deviations, stubs, or orphaned code detected.

---

_Verified: 2026-03-19_
_Verifier: Claude (gsd-verifier)_
