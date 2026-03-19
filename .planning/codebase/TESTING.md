# Testing

## Current State
**No tests exist.** The project has no test targets, no test files, and no CI configuration.

## Test Framework
- `Package.swift` defines only an executable target — no `.testTarget` configured
- No `Tests/` directory present
- No XCTest or Swift Testing imports anywhere

## Build Verification
- Build is verified manually via `make build` → `build.sh` → `swift build -c release`
- No automated build checks or CI pipeline

## Areas That Would Benefit From Testing

### Unit Tests (High Value)
- **ClaudeState** — state transitions, `needsAttention`, `canGoToConvo` computed properties
- **Event processing** — `processEvent()` in `ClaudeMonitor` (state machine transitions)
- **Aggregate state** — `updateAggregateState()` priority logic (needsYou > thinking > finished)
- **Color hex parsing** — `Color(hex:)` extension edge cases
- **Theme colors** — `darken()` function, dark mode color computation
- **Sprite data** — all sprites have consistent dimensions (14x12)
- **SeededRNG** — deterministic output for given seed

### Integration Tests (Medium Value)
- **IPC round-trip** — hook writes event → monitor reads and processes
- **Permission flow** — pending.json → response.json → hook returns decision
- **Session tracking** — start/end/rehydration/pruning
- **File watcher** — events.jsonl append triggers `readNewEvents()`

### Python Hook Tests (High Value)
- **Event mapping** — all `EVENT_MAP` entries produce correct output
- **`summarize_input()`** — each tool type produces expected summary
- **`safe_write` / `safe_append`** — symlink rejection, atomic writes, permissions
- **Permission timeout** — 55s timeout returns correctly
- **Session pruning** — sessions older than 7200s are removed
- **App discovery** — `get_app_path()` candidate path priority

## Recommended Test Setup
```swift
// Package.swift addition:
.testTarget(
    name: "ClaumagotchiTests",
    dependencies: ["Claumagotchi"],
    path: "Tests"
)
```

For Python hook tests: `pytest` with temporary IPC directories.

## Coverage Gaps
- No regression protection for state machine logic
- No validation that sprites render correctly
- No automated check that hook ↔ app IPC protocol stays in sync
- No performance baseline for sprite animation timer (0.45s)
