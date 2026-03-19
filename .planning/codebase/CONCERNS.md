# Concerns

## Technical Debt

### File Watcher Fragility
- `Sources/ClaudeMonitor.swift:142-161` — uses raw `open()` file descriptor + `DispatchSource` for kqueue monitoring
- If `events.jsonl` is deleted and recreated, the file descriptor becomes stale; watcher silently stops working
- No recovery mechanism — requires app restart

### Retry Without Backoff
- `Sources/ClaudeMonitor.swift:263-277` — `loadPendingPermission()` retries 5 times at fixed 0.15s intervals
- Not a major issue at current scale but pattern doesn't degrade gracefully

### Timer Management
- `Sources/ClaudeMonitor.swift:281-285` — manual `Timer.scheduledTimer` for idle detection
- `Sources/ScreenView.swift:8` — `Timer.publish(every: 0.45)` runs continuously even when app is hidden
- No pause/resume based on window visibility

### Mixed Concurrency Models
- Hook auto-launch uses `DispatchQueue.main.asyncAfter` (GCD)
- File watcher uses `DispatchSource` (GCD)
- UI uses SwiftUI's `@Published` / `@StateObject`
- No Swift Concurrency (async/await) despite targeting macOS 14+

## Known Bugs

### YOLO Mode Icon State
- `Sources/ClaumagotchiApp.swift:62` — `EggIcon.image(attention:)` uses `monitor.state.needsAttention`
- In YOLO mode, `needsAttention` is false (permissions auto-accepted), so icon never turns orange
- YOLO mode has no distinct visual indicator in the menu bar

### Window Lookup by Title
- `Sources/ClaumagotchiApp.swift:68,76` — `toggleMainWindow()` and `showMainWindow()` find window by `window.title == "Claumagotchi"`
- Fragile — breaks if window title changes or if another window has the same title

## Security Concerns

### IPC Directory Permissions
- Both hook (`hooks/claumagotchi-hook.py:36-38`) and app (`Sources/ClaudeMonitor.swift:86-92`) enforce 0700 on IPC dir
- `safe_write` and `safe_append` reject symlinks — good defense against symlink attacks
- `response.json` contains permission decisions — if compromised, attacker could auto-approve tool use

### Permission Response Validation
- `hooks/claumagotchi-hook.py:236` — decision defaults to `"allow"` if key missing: `resp.get("decision", "allow")`
- A malformed or empty response file would default to allowing the action

### No Input Validation on Events
- `Sources/ClaudeMonitor.swift:170-173` — `processEvent()` parses JSON without validating expected schema
- Malformed events are silently ignored (acceptable) but no logging for debugging

### Terminal Activation by Bundle ID
- `Sources/ClaudeMonitor.swift:128-138` — hardcoded list of terminal bundle IDs
- Not a security issue per se, but `activateTerminal()` activates the first match which may not be the correct terminal

## Performance

### Sprite Animation Timer
- `Sources/ScreenView.swift:8` — `Timer.publish(every: 0.45)` fires continuously
- Triggers `Canvas` re-render on every tick even when character hasn't changed visually
- Minor CPU overhead but unnecessary when window is hidden

### Noise Texture Rendering
- `Sources/ContentView.swift:186-208` — `NoiseView` uses `Canvas` with pixel-by-pixel rendering
- `SeededRNG` ensures deterministic output (good) but re-renders on any view update
- Static texture should ideally be rendered once and cached as an image

### Full State Recompute
- `Sources/ClaudeMonitor.swift:241-258` — `updateAggregateState()` reads `sessions.json` from disk on every event
- At current scale (few sessions) this is fine, but file I/O on every event is inefficient

### Event File Truncation
- `hooks/claumagotchi-hook.py:125-129` — truncates `events.jsonl` to last 20 lines when >50KB
- Reads entire file into memory, then rewrites — acceptable at 50KB but pattern doesn't scale

## Fragile Areas

### State Machine Complexity
- `Sources/ClaudeMonitor.swift:170-237` — `processEvent()` has complex branching with permission priority, awaiting-user guard, and per-session state
- `awaitingUserAction` flag creates hidden coupling between permission events and all other events
- Untested — high risk of regression

### Pixel Rendering
- `Sources/ContentView.swift:330-425` — `PixelTitle` renders "CLAUMAGOTCHI" character by character with 3 passes (shadow, highlight, main)
- `Sources/ScreenView.swift:122-167` — `PixelCharacterView` renders sprites pixel by pixel
- Any change to sprite dimensions or font data requires careful manual verification

### Color Hex Parsing
- `Sources/ContentView.swift:430-441` — `Color(hex:)` only handles 6-char hex, returns black for anything else
- `Sources/ThemeManager.swift:106-114` — `darken()` duplicates hex parsing logic independently
- Two separate hex parsers that could diverge

## Missing Features (Not Blocking)
- No persistent event log / history
- No rate limiting on event processing
- No signature verification on response.json
- No terminal fallback if none of the hardcoded bundle IDs match
- No localization / i18n support
- No accessibility audit (VoiceOver labels exist on buttons but not comprehensive)
