# Phase 3: UX Enhancements - Research

**Researched:** 2026-03-20
**Domain:** SwiftUI macOS companion app — LCD display, sprite animation, IPC data flow, global key monitoring
**Confidence:** HIGH

---

## Summary

Phase 3 adds four user-visible improvements to Claumagotchi: a session count on the LCD, an idle/sleep animation state, richer permission detail in the prompt display, and system-wide keyboard shortcuts to approve or deny permissions.

Each of the four requirements touches a different layer of the app. UX-01 (session count) is purely a display change — `sessionStates.count` is already tracked in `ClaudeMonitor` but not yet exposed as a `@Published` property. UX-02 (idle animation) requires a new sprite set plus a new `ClaudeState` case or a separate `isIdle` flag; the idle timer (`idleWork: DispatchWorkItem`) already fires after 60 seconds but currently does nothing visually distinctive. UX-03 (permission detail) is a near-zero-effort IPC fix — `pending.json` already contains a `summary` field computed by `summarize_input()` in the hook, and `ScreenView.displayDetail` already renders it, but it only shows `basename` for file operations, not the full path; the fix is in the hook's `summarize_input()` function. UX-04 (global hotkeys) requires `NSEvent.addGlobalMonitorForEvents` with an Accessibility permission gate — this is the only requirement with a non-trivial new subsystem.

**Primary recommendation:** Implement in order UX-01 → UX-03 → UX-02 → UX-04. UX-01 and UX-03 are trivial. UX-02 is self-contained but requires new sprite data. UX-04 has the most surface area and should be last.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| UX-01 | Active session count is displayed on the LCD screen | `sessionStates` dict already exists in `ClaudeMonitor`; needs `@Published var sessionCount: Int` computed from it, then rendered as a label in the LCD icon row |
| UX-02 | Character plays a sleeping/idle animation after a period of inactivity | `idleWork` DispatchWorkItem already fires after 60s on `stop`; needs a new `ClaudeState.idle` case (or `isIdle` flag) and corresponding sprite frames |
| UX-03 | Permission prompt shows full file path or command, not just tool name | `summarize_input()` in hook already computes summaries; `Write`/`Read`/`Edit`/`Glob` return only `basename()` — change to return full path; Bash already returns up to 50 chars of command |
| UX-04 | Global hotkeys Option+A to allow, Option+D to deny — system-wide | `NSEvent.addGlobalMonitorForEvents` requires Accessibility permission; must check `AXIsProcessTrustedWithOptions` at startup; register in `ClaudeMonitor.init()` or `AppDelegate` |
</phase_requirements>

---

## Standard Stack

### Core (all already in use)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ / macOS 14+ | UI rendering | Project baseline |
| AppKit | macOS 14+ | NSEvent global monitor, NSSound | Required for global hotkeys |
| Foundation | macOS 14+ | DispatchWorkItem, UserDefaults | Already used throughout |

### No New Dependencies

This phase adds no third-party libraries. The project's constraint is self-contained distribution. All four requirements are implementable with AppKit + Foundation APIs already imported.

**Installation:** None required.

---

## Architecture Patterns

### UX-01: Session Count Display

**What:** Expose `sessionStates.count` as a `@Published` computed property on `ClaudeMonitor`. Render it in `ScreenView`'s LCD icon row.

**Where to display:** The top icon row in `ScreenView` has three `LCDIcon` views with `Spacer()` between them. A small session count badge fits naturally in the existing `HStack` — either as a fourth element or replacing one of the spacers. A monospaced digit label fits the retro aesthetic.

**Pattern: Published Computed Property**

`sessionStates` is `private var`. To expose count without breaking encapsulation, either:
1. Add `@Published var sessionCount: Int = 0` and update it wherever `sessionStates` mutates (inside `updateAggregateState()`, `processEvent()`, `rehydrateSessions()`).
2. Or change `sessionStates` to internal visibility and let `ScreenView` compute `monitor.sessionStates.count`.

Option 1 is cleaner — a single `@Published` integer that SwiftUI reacts to, updated in all mutation sites.

**Mutation sites in `ClaudeMonitor` that touch `sessionStates`:**
- `rehydrateSessions()` — bulk populate
- `processEvent()` — `sessionStates[sid] = .thinking`, `sessionStates[sid] = .needsYou`, `sessionStates.removeValue(forKey: sid)`
- `updateAggregateState()` — removes stale keys

All of these already call `updateAggregateState()` except direct `processEvent()` mutations for `needsYou`. The cleanest approach: update `sessionCount = sessionStates.count` at the end of `updateAggregateState()` AND after the `needsYou` branch in `processEvent()`.

```swift
// In ClaudeMonitor
@Published var sessionCount: Int = 0

// At end of updateAggregateState()
sessionCount = sessionStates.count

// After needsYou branch in processEvent()
if !sid.isEmpty { sessionStates[sid] = .needsYou }
sessionCount = sessionStates.count
```

**In ScreenView — LCD icon row addition:**
```swift
// After the three LCDIcon views, inside the HStack
if monitor.sessionCount > 0 {
    Text("\(monitor.sessionCount)")
        .font(.system(size: 7, weight: .black, design: .monospaced))
        .foregroundColor(themeManager.lcdOn.opacity(0.85))
}
```

Alternatively, the session count can go in the `displayDetail` line when no permission is pending — e.g., show "2 sessions" when thinking and no permission is active.

**LCD space constraint:** The screen is 116×88 pts. The top icon row already uses `HStack(spacing: 0)` with `Spacer()` between three icons — there is room for a small digit label without overflow.

---

### UX-02: Idle/Sleep Animation

**What:** After a period of inactivity (no active sessions, no pending permission), the character transitions to a sleeping sprite.

**Current state:** `startIdleTimer(interval: 60)` is called on `stop` events when `state == .finished`. The `DispatchWorkItem` fires after 60 seconds and sets `state = .finished` — which is the same state it was already in. The idle timer is a no-op visually.

**Pattern options:**

**Option A — New `ClaudeState.idle` case**
- Add `.idle` to the `ClaudeState` enum
- `startIdleTimer` sets `state = .idle` instead of `.finished`
- `PixelCharacterView.spritesForState()` gets a new `.idle` branch returning sleeping sprites
- `ScreenView.displayLabel` returns "ZZZ..." for `.idle`
- `ScreenView.displayDetail` returns `""` for `.idle`
- Any new activity resets state to `.thinking` which clears idle naturally

Tradeoff: `ClaudeState` grows a fourth case. All switch statements over `ClaudeState` need updating (there are ~5 in the codebase).

**Option B — Separate `@Published var isIdle: Bool`**
- `isIdle = true` when idle timer fires, `isIdle = false` on any new event
- `PixelCharacterView` checks `isIdle` alongside `state`
- `ClaudeState` enum stays at 3 cases

Tradeoff: Two-variable state can be inconsistent (`state == .thinking` and `isIdle == true` is a contradiction). Requires defensive guards.

**Recommendation: Option A.** Adding `.idle` to `ClaudeState` is the correct model. It avoids boolean flag inconsistency and keeps state-driven rendering clean. The switch exhaustiveness check will catch any missed sites at compile time.

**Idle timer interval:** Currently hardcoded at 60 seconds. A `UserDefaults`-backed preference is out of scope for this phase. Keep 60 seconds.

**Sleeping sprite design:** The existing sprites are 14 columns × 12 rows. A sleeping sprite should show eyes closed (two `##` blocks replaced with `--` or just dots), mouth changed to a neutral line, and optionally a "Z" or two floating above the head. The Sprites enum gets two new static properties: `sleep1` and `sleep2` (gentle breathing animation — body slightly taller, then normal).

```
sleep1 example (eyes closed, neutral mouth):
"......##......",
"....######....",
"..##########..",
".#..........#.",
".#..--..--..#.",   // dashes = closed eyes
".#..........#.",
".#....##....#.",   // flat mouth
".#..........#.",
"..##########..",
"....######....",
"..............",
"..##......##..",
```

**State transitions involving `.idle`:**
- `idle` → `thinking`: any `pre_tool`, `post_tool`, `session_start`, `session_end`, `permission` event
- `thinking` → `idle`: idle timer fires (only when `state == .finished` first, then timer transitions to `.idle`)
- `idle` → `needsYou`: permission event
- `needsYou` → `idle`: not possible (permission resolution goes to `.thinking` or `.finished`)

The current `startIdleTimer` is only called when `state == .finished`. This means `.idle` is only reached from `.finished`, which is correct — idle means "was done and stayed quiet for 60 seconds."

**Guard in idle timer:** The existing guard `guard let self, self.pendingPermission == nil else { return }` is correct. The new behavior simply changes the body from `self.state = .finished` to `self.state = .idle`.

**Waking from idle:** Any event that calls `processEvent()` will call `updateAggregateState()` or set `state = .thinking/.needsYou` directly. When `state` changes away from `.idle`, the character wakes. No additional wakeup logic needed.

---

### UX-03: Richer Permission Info

**What:** Show the actual file path or command being requested, not just the basename.

**Current hook behavior (`summarize_input()`):**
- `Bash`: returns `cmd[:50]` — already good (first 50 chars of command)
- `Write`/`Read`/`Edit`/`Glob`: returns `os.path.basename(path)` — only filename, not full path
- `Grep`: returns pattern
- `Agent`: returns description
- Others: returns `tool.lower()`

**Current Swift display (`ScreenView.displayDetail`):**
```swift
if let p = monitor.pendingPermission {
    return "\(p.tool): \(p.summary)"
}
```

The detail line is `font(.system(size: 6.5))` with `lineLimit(2)` and a fixed `height: 14` — it can show two short lines.

**Fix needed:** In `summarize_input()`, change `Write`/`Read`/`Edit`/`Glob` to return the full path (or a truncated version for very long paths):

```python
elif tool in ("Write", "Read", "Edit", "Glob"):
    path = tool_input.get("file_path", "") or tool_input.get("pattern", "")
    if not path:
        return tool.lower()
    # Truncate from the left if too long (keep the meaningful end)
    return path if len(path) <= 40 else "..." + path[-37:]
```

**Why the LCD can handle longer strings:** `displayDetail` has `lineLimit(2)` and `multilineTextAlignment(.center)` — it will wrap a long path across two lines. The 6.5pt monospaced font fits ~25 characters per line at 116pt width. Paths up to ~50 characters display cleanly.

**No Swift changes needed for UX-03** — the display layer already receives and renders `summary` from `PendingPermission`. The only change is in the hook.

**IPC data flow confirmation:**
1. Hook writes `pending.json` → `{"id": ..., "tool": "Write", "summary": "/Users/foo/bar/baz.swift", "ts": ...}`
2. Hook writes `permission` event to `events.jsonl`
3. Swift `loadPendingPermission()` reads `pending.json` → `PendingPermission(id:, tool:, summary:)`
4. `ScreenView.displayDetail` renders `"\(p.tool): \(p.summary)"`

The full path flows end-to-end with no additional changes.

---

### UX-04: Global Hotkeys

**What:** Option+A allows, Option+D denies a pending permission from anywhere on the system — without clicking the companion window.

**API:** `NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in ... }`

**Critical requirement: Accessibility permission**

Global key event monitoring requires the app to be trusted for Accessibility in System Preferences → Privacy & Security → Accessibility. Without this permission, `addGlobalMonitorForEvents` installs silently but the handler never fires for key events.

**Checking permission at runtime:**
```swift
import ApplicationServices

let trusted = AXIsProcessTrusted()
// OR with prompt:
let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
let trusted = AXIsProcessTrustedWithOptions(options)
```

`AXIsProcessTrustedWithOptions` with the prompt option opens System Preferences directly when permission is not yet granted. The prompt should be shown on first launch (or first time the permission is needed).

**When to prompt:** Only when a permission request arrives (i.e., when `state == .needsYou`). Showing the Accessibility dialog at app launch would be intrusive. Show it lazily when the user actually needs global hotkeys.

**Key codes (macOS Virtual Keycodes, hardware-independent):**
- `a` key: keyCode `0` (kVK_ANSI_A)
- `d` key: keyCode `2` (kVK_ANSI_D)

Using `event.keyCode` is more reliable than `event.characters` (which varies by keyboard layout and modifier state). `event.modifierFlags` must contain `.option` and not contain `.command`, `.control`, or `.shift` to avoid interfering with other shortcuts.

**Conflict analysis for Option+A / Option+D:**
- Option+A on macOS typically produces the `å` character (US keyboard layout). It is not a standard system shortcut.
- Option+D produces `∂` (partial differential). Also not a system shortcut.
- These keys are used by terminal apps for text entry when the Option key is configured as Meta. This is a meaningful conflict: if the user is in a terminal with Option-as-Meta, pressing Option+A or Option+D would fire both the terminal's Meta+A/Meta+D binding AND Claumagotchi's handler.
- Mitigation: Only process the hotkey when `monitor.pendingPermission != nil` (i.e., a permission is actively waiting). When no permission is pending, the handler is a no-op.

**Implementation location:** `ClaudeMonitor` or `AppDelegate`. `ClaudeMonitor` is preferred because it owns `respondToPermission()` and has access to `pendingPermission`. The monitor reference is an `@StateObject` in `ClaumagotchiApp` — `AppDelegate` does not have access to it without a shared reference.

The cleanest pattern: install the global monitor in `ClaudeMonitor.init()`, storing the returned opaque monitor object. Cancel it in `deinit`.

```swift
// In ClaudeMonitor
private var globalKeyMonitor: Any?

// In init() — after setting up state
setupGlobalHotkeys()

// In deinit
if let m = globalKeyMonitor { NSEvent.removeMonitor(m) }

private func setupGlobalHotkeys() {
    guard AXIsProcessTrusted() else { return }
    globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
        guard let self, self.pendingPermission != nil else { return }
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags == .option else { return }
        switch event.keyCode {
        case 0: self.respondToPermission(allow: true)   // A
        case 2: self.respondToPermission(allow: false)  // D
        default: break
        }
    }
}
```

**Accessibility permission UX:** Add a check in `processEvent` when transitioning to `needsYou`. If `!AXIsProcessTrusted()`, display a note in the UI — either in `displayDetail` or via a temporary state. The simplest approach: in `ScreenView.displayDetail`, when `state == .needsYou` and `pendingPermission != nil` and accessibility is not trusted, append a hint. But this is complex. Simpler: just show the existing permission detail and let global hotkeys silently not work until the user grants access. Add an "Enable Global Hotkeys" menu item in the menu bar that calls `AXIsProcessTrustedWithOptions` with the prompt.

**Re-installing the monitor:** After the user grants Accessibility in System Preferences, the monitor needs to be re-installed (the process must be re-evaluated). A `NSWorkspace.didActivateApplicationNotification` or `DistributedNotificationCenter` observer can watch for the Accessibility permission change. Simpler: call `setupGlobalHotkeys()` each time a permission event arrives (`processEvent` → `permission` branch), which is idempotent if guarded against double-installation.

```swift
// Guard against double-install
private func setupGlobalHotkeys() {
    guard globalKeyMonitor == nil, AXIsProcessTrusted() else { return }
    globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(...)
}
```

Call `setupGlobalHotkeys()` from both `init()` and the `permission` event handler.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Global hotkey library | Custom Carbon RegisterEventHotKey | `NSEvent.addGlobalMonitorForEvents` (AppKit, already imported) |
| Accessibility permission dialog | Custom UI | `AXIsProcessTrustedWithOptions` with `kAXTrustedCheckOptionPrompt` |
| Key code lookup table | Hardcoded string → int map | Use `kVK_ANSI_A = 0`, `kVK_ANSI_D = 2` from Carbon/HIToolbox or just hardcode the well-known values |

**Key insight:** All four requirements are achievable with APIs already in the import graph. No new frameworks or third-party libraries are needed.

---

## Common Pitfalls

### Pitfall 1: Global monitor fires for its own app
**What goes wrong:** `addGlobalMonitorForEvents` does NOT fire when the Claumagotchi window itself is focused and a key is pressed. It only fires for events dispatched to OTHER applications.
**Why it happens:** This is by design per Apple docs: "Monitors events dispatched to applications other than the calling application."
**How to avoid:** Also install a LOCAL monitor (`addLocalMonitorForEvents`) if you want hotkeys to work when the companion window has focus. For this use case (permission response), the window is floating but typically unfocused — the global monitor covers the main scenario. Adding a local monitor for completeness is a small addition.
**Warning signs:** Hotkeys work when another app is focused but not when clicking the companion window directly.

### Pitfall 2: Accessibility permission granted after app launch
**What goes wrong:** `AXIsProcessTrusted()` returns `false` at init. User grants permission in System Preferences. The global monitor was never installed. Hotkeys remain non-functional until app restart.
**Why it happens:** macOS does not notify the app when Accessibility trust changes. The monitor must be explicitly re-registered.
**How to avoid:** Call `setupGlobalHotkeys()` each time a `permission` event arrives. This is called at most once per permission request. Guard with `globalKeyMonitor == nil` to prevent double-installation.

### Pitfall 3: `.idle` state not cleared on session rehydration
**What goes wrong:** App was in `.idle` state. User quits and relaunches. `rehydrateSessions()` repopulates `sessionStates`, then calls `state = .thinking` — but `.idle` might persist if rehydration doesn't update the state correctly.
**How to avoid:** The current `rehydrateSessions()` already sets `state = .thinking` at the end if `!sessionStates.isEmpty`. No change needed. But add `.idle` to the `ClaudeState.needsAttention` and `canGoToConvo` computed properties as appropriate (`.idle` should return `false` for both).

### Pitfall 4: `sessionCount` not updated on `needsYou` branch
**What goes wrong:** When a `permission` event arrives, `sessionStates[sid] = .needsYou` is set and then returns early — `updateAggregateState()` is never called, so `sessionCount` is stale.
**How to avoid:** After `sessionStates[sid] = .needsYou` in the `permission` branch, explicitly set `sessionCount = sessionStates.count`.

### Pitfall 5: Option+key conflicts with terminal Meta key
**What goes wrong:** User's terminal app has Option configured as Meta key. Pressing Option+D in the terminal sends `∂` AND fires Claumagotchi's deny handler simultaneously.
**Why it happens:** Global monitors receive copies of all events — they cannot block delivery to the target app.
**How to avoid:** Only process the hotkey when `pendingPermission != nil`. The risk of accidentally denying a permission while doing unrelated work in a terminal is real but low — the user would need to press Option+D specifically while a permission dialog is active.

### Pitfall 6: LCD screen has no space for session count in top row
**What goes wrong:** Adding a session count label to the existing `HStack` wraps or overflows the 116pt screen width.
**How to avoid:** The top row has three icons with `Spacer()` between them. The spacers compress to zero if needed. At 7pt monospaced, a two-digit count ("12") is ~10pt wide — well within one spacer's typical width. Test with 2-digit counts.

---

## Code Examples

### Global Monitor Registration

```swift
// Source: Apple Docs — addGlobalMonitorForEvents(matching:handler:)
// + developer.apple.com/library/archive EventOverview/MonitoringEvents

import AppKit
import ApplicationServices

private var globalKeyMonitor: Any?
private var localKeyMonitor: Any?

private func setupGlobalHotkeys() {
    guard globalKeyMonitor == nil, AXIsProcessTrusted() else { return }
    globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
        self?.handleHotKey(event)
    }
    // Also handle when companion window itself is focused
    localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
        self?.handleHotKey(event)
        return event  // must return event for local monitor
    }
}

private func handleHotKey(_ event: NSEvent) {
    guard pendingPermission != nil else { return }
    let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
    guard flags == .option else { return }
    switch event.keyCode {
    case 0: respondToPermission(allow: true)   // kVK_ANSI_A
    case 2: respondToPermission(allow: false)  // kVK_ANSI_D
    default: break
    }
}

// Cleanup in deinit:
if let m = globalKeyMonitor { NSEvent.removeMonitor(m) }
if let m = localKeyMonitor  { NSEvent.removeMonitor(m) }
```

### Accessibility Permission Check and Prompt

```swift
// Source: AXIsProcessTrustedWithOptions — ApplicationServices framework

import ApplicationServices

/// Check if trusted; optionally prompt user to open System Preferences.
func checkAccessibilityPermission(prompt: Bool = false) -> Bool {
    if prompt {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(opts as CFDictionary)
    }
    return AXIsProcessTrusted()
}
```

### Sleeping Sprite (14×12, same format as existing sprites)

```swift
// In Sprites enum — same style as existing sprites
static let sleep1: [String] = [
    "......##......",
    "....######....",
    "..##########..",
    ".#..........#.",
    ".#..--..--..#.",   // eyes closed (use dots for off-pixels)
    ".#..........#.",
    ".#....##....#.",   // neutral mouth
    ".#..........#.",
    "..##########..",
    "....######....",
    "..............",
    "..##......##..",
]
static let sleep2: [String] = [
    "......##......",
    "....######....",
    "..##########..",
    ".#..........#.",
    ".#...--.--.#.",    // slightly different eye position (breathing)
    ".#..........#.",
    ".#....##....#.",
    ".#..........#.",
    "..##########..",
    "....######....",
    "...#......#...",
    "..##......##..",
]
```

Note: Sprite rows use `.` for off-pixels and `#` for on-pixels. The `--` notation above is illustrative — in actual data, those would be `.` characters (off-pixels), making the eyes simply absent/closed.

### Session Count in LCD

```swift
// In ScreenView body — top icon row modification
HStack(spacing: 0) {
    LCDIcon(symbol: "exclamationmark.triangle.fill",
            active: monitor.state == .needsYou,
            color: themeManager.lcdOn)
    Spacer()
    // Session count badge — only show when sessions are active
    if monitor.sessionCount > 0 {
        Text("\(monitor.sessionCount)")
            .font(.system(size: 7, weight: .black, design: .monospaced))
            .foregroundColor(themeManager.lcdOn.opacity(0.85))
    } else {
        Spacer().frame(width: 10)
    }
    Spacer()
    LCDIcon(symbol: isYoloActive ? "flame.fill" : "bolt.fill",
            active: isYoloActive ? true : monitor.state == .thinking,
            color: themeManager.lcdOn)
    Spacer()
    LCDIcon(symbol: "checkmark.circle.fill",
            active: monitor.state == .finished,
            color: themeManager.lcdOn)
}
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| `Timer.scheduledTimer` for idle | `DispatchWorkItem` (Phase 2) | No RunLoop dependency, clean cancel — already done |
| `sessionStates` private, count unexposed | Add `@Published var sessionCount` | UX-01 |
| Idle timer is a no-op (sets `.finished` when already `.finished`) | Idle timer sets `.idle` state | UX-02 |
| `summarize_input` returns `basename()` for file tools | Return full path (truncated at 40 chars) | UX-03 |
| No global hotkey support | `NSEvent.addGlobalMonitorForEvents` with Accessibility | UX-04 |

---

## Open Questions

1. **Idle timer interval — make it configurable?**
   - What we know: Currently hardcoded at 60 seconds in `startIdleTimer(interval: 60)`.
   - What's unclear: Whether users want to adjust this.
   - Recommendation: Keep 60 seconds for Phase 3. The interval parameter exists in `startIdleTimer` — a future phase can expose it via `UserDefaults` without rearchitecting.

2. **Should local monitor also handle Option+A/D?**
   - What we know: `addGlobalMonitorForEvents` does not fire when the Claumagotchi window itself has focus.
   - What's unclear: In practice, does the companion window ever receive focus while a permission is pending?
   - Recommendation: Add a local monitor alongside the global one. It's two lines of code and eliminates a surprising edge case.

3. **`ClaudeState.idle` vs `isIdle: Bool` — label implications**
   - What we know: `ClaudeState.label` is used in `ScreenView.displayLabel` and in `ClaumagotchiApp`'s `MenuBarExtra` status text.
   - What's unclear: What label should `.idle` show? "ZZZ..." fits the aesthetic.
   - Recommendation: Add `case idle` with `var label: String { "ZZZ..." }` and update `needsAttention` and `canGoToConvo` to return `false` for `.idle`.

4. **Accessibility permission — where to prompt?**
   - What we know: `AXIsProcessTrustedWithOptions` with prompt opens System Preferences.
   - What's unclear: Whether to prompt at launch or lazily.
   - Recommendation: Lazy prompt — only when the first `permission` event arrives and `!AXIsProcessTrusted()`. Add a "Enable Global Hotkeys" menu item that triggers the prompt manually.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None detected — no test targets in Package.swift or test directories |
| Config file | None — Wave 0 gap |
| Quick run command | N/A (manual verification only) |
| Full suite command | N/A |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| UX-01 | `sessionCount` updates when sessions mutate | unit | N/A — no test target | ❌ Wave 0 |
| UX-02 | `.idle` state entered after 60s inactivity | unit (manual) | N/A | ❌ Wave 0 |
| UX-03 | `summarize_input` returns full path for Write/Read/Edit/Glob | unit (Python) | `python3 -c "..."` inline | ❌ Wave 0 |
| UX-04 | Global monitor registered only when `AXIsProcessTrusted()` | manual | N/A | ❌ Wave 0 |

**Note:** The existing codebase has no test infrastructure (TEST-01/02/03 are v2 requirements). All validation for Phase 3 is manual functional testing:
- Build and run; trigger test sessions via hook
- Verify LCD shows session count
- Wait 60+ seconds idle; verify sleeping sprite appears
- Trigger a permission for a file path; verify full path appears
- Grant Accessibility permission; verify Option+A/D work system-wide

### Wave 0 Gaps
- No test infrastructure exists — this is deferred to v2 per REQUIREMENTS.md (TEST-01/02/03)
- UX-03 (hook change) can be spot-checked with: `echo '{"hook_event_name":"PermissionRequest","tool_name":"Write","tool_input":{"file_path":"/Users/test/very/long/path/file.swift"},"session_id":"abc"}' | python3 hooks/claumagotchi-hook.py` and inspecting `~/.claude/claumagotchi/pending.json`

---

## Sources

### Primary (HIGH confidence)
- Apple Developer Docs — `addGlobalMonitorForEvents(matching:handler:)` — confirmed global monitors require Accessibility permission for key events, are read-only, and do not fire for own-app events
- Apple Archive Docs — Monitoring Events (EventOverview) — confirmed event monitor scope and limitations
- Code analysis — `ClaudeMonitor.swift`, `ScreenView.swift`, `ClaumagotchiApp.swift`, `hooks/claumagotchi-hook.py` — direct inspection of current state

### Secondary (MEDIUM confidence)
- WebSearch verified with Apple forums — `AXIsProcessTrustedWithOptions` usage pattern for prompting Accessibility permission
- WebSearch — Key code values: `kVK_ANSI_A = 0`, `kVK_ANSI_D = 2` (well-known macOS virtual key codes, consistent across multiple sources)

### Tertiary (LOW confidence)
- WebSearch only — Terminal Option-as-Meta key conflict analysis (single-source assessment; behavior depends on user's terminal configuration)

---

## Metadata

**Confidence breakdown:**
- Standard Stack: HIGH — no new libraries, all APIs confirmed in Apple docs
- Architecture (UX-01, UX-02, UX-03): HIGH — direct code inspection, clear implementation path
- Architecture (UX-04 global hotkeys): HIGH — API confirmed in Apple docs; Accessibility requirement confirmed from multiple sources
- Pitfalls: MEDIUM-HIGH — global monitor own-app limitation confirmed by Apple docs; Terminal conflict is LOW (single source)
- Sprite design: MEDIUM — format is confirmed by existing sprites; specific pixel art content is speculative and will need visual iteration

**Research date:** 2026-03-20
**Valid until:** 2026-06-20 (stable AppKit APIs; sprite content is timeless)
