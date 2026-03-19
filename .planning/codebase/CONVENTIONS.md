# Coding Conventions

**Analysis Date:** 2026-03-19

## Naming Patterns

**Files:**
- Views: PascalCase + "View" suffix (e.g., `ContentView.swift`, `ScreenView.swift`)
- Services/Managers: PascalCase + functional suffix (e.g., `ClaudeMonitor.swift`, `ThemeManager.swift`)
- Enums/Types: PascalCase (e.g., `ClaudeState`, `PendingPermission`, `Sprites`)
- App entry: `ClaumagotchiApp.swift`

**Functions:**
- camelCase for instance and static methods
- Private helper functions prefixed with underscore (e.g., `_Void`, `_CGFloat`)
- Lifecycle methods (didSet, willSet) declared inline on properties
- Action callbacks follow pattern: `respondToPermission()`, `goToConversation()`

**Variables:**
- camelCase for all properties and local variables
- `@Published` for observable properties (ClaudeMonitor, ThemeManager)
- `@State` for local component state
- `@EnvironmentObject` for injected dependencies
- Private fields prefixed with underscore (rarely used; privacy via access control preferred)
- Boolean properties use verb phrases: `soundEnabled`, `autoAccept`, `needsAttention`, `canGoToConvo`

**Types:**
- Struct for simple data (PendingPermission, ShellTheme)
- Final class for reference types with lifecycle (ClaudeMonitor, ThemeManager, AppDelegate)
- Enum for state machines (ClaudeState) and sprite constants (Sprites)

## Code Style

**Formatting:**
- Swift code (no specific formatter detected)
- Consistent 4-space indentation
- Multiple type definitions per file allowed (e.g., ContentView + helper views in same file)
- Related types grouped with `// MARK: - [Section]` comments

**Linting:**
- No linting configuration detected (no .swiftlint.yml, eslint, or similar)
- Code quality relies on manual review and convention adherence

## Import Organization

**Order:**
1. Foundation-level imports (Foundation, Combine, AppKit)
2. SwiftUI (always Foundation first, then UI frameworks)

**Example from `ClaumagotchiApp.swift`:**
```swift
import SwiftUI
import AppKit
```

**Example from `ClaudeMonitor.swift`:**
```swift
import Foundation
import Combine
import AppKit
```

**Path Aliases:**
- No path aliases detected — all imports are direct framework imports

## Error Handling

**Patterns:**
- Silent failures common: `try?` used throughout to avoid crashes from file I/O
- No error propagation or custom error types defined
- File operations wrapped in `try?` with nil coalescing defaults

**Examples from `ClaudeMonitor.swift`:**
```swift
try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
try? data.write(to: URL(fileURLWithPath: Self.responseFile))
try? fileHandle?.close()
```

**Examples from `ClaumagotchiApp.swift` (AppDelegate):**
```swift
try? FileManager.default.removeItem(atPath: pidFile)
try? "\(pid)\n".write(toFile: pidFile, atomically: true, encoding: .utf8)
```

## Logging

**Framework:** None detected — uses direct print or NSSound for feedback

**Patterns:**
- No structured logging
- No logger instances
- Sound feedback used instead of console output (`NSSound(named: "Ping")?.play()`)
- File-based IPC for inter-process communication (events.jsonl, pending.json, response.json)

## Comments

**When to Comment:**
- Section dividers: `// MARK: - [Section Name]` for major logical groups
- Inline comments for non-obvious logic (e.g., "Permission ALWAYS wins", "Enforce single instance via PID file")
- Documentation for public methods in classes (e.g., AppDelegate methods)
- Explain "why" rather than "what" (e.g., comments on PID file strategy, compositing operations)

**JSDoc/TSDoc:**
- Not used in Swift codebase
- Documentation comments above public functions are minimal
- Most documentation via method names and comment blocks

## Function Design

**Size:**
- Tight coupling to features; functions generally 10-50 lines
- Longer functions in Canvas-based views for rendering logic (NoiseView, PixelTitle)
- Helper functions extracted when logic repeats (e.g., `spritesForState()`, `displayLabel`, `centerButton`)

**Parameters:**
- Inject dependencies via environment objects rather than parameter passing
- View parameters minimal; prefer `@EnvironmentObject` for shared state
- Closure-based callbacks for button actions

**Return Values:**
- Void for state mutations (all monitor actions)
- Computed properties for derived UI state (e.g., `displayLabel`, `centerButton`, `currentSprite`)
- Optional types return nil on missing data (e.g., `loadPendingPermission()` tries JSON parsing)

## Module Design

**Exports:**
- All public types (views, enums, classes) defined at module level
- No explicit `public` keywords (macOS app, not a library)
- Private members use `private` access control
- Static members for class-level constants (e.g., `ClaudeMonitor.ipcDir`, `AppDelegate.pidFile`)

**Barrel Files:**
- Not used — single file per type (following SwiftUI Pro skill guidelines)
- Related views grouped in same file when tightly coupled (e.g., ActionButton, PixelTitle in ContentView.swift)

## Concurrency

**Pattern:**
- DispatchQueue.main for main thread work
- Timer.publish().autoconnect() for periodic updates (ScreenView)
- DispatchQueue.main.asyncAfter() for delayed operations (auto-accept permissions)
- No async/await detected (Swift 5.10 target allows it; not used in this codebase)
- Weak self captures in closures to prevent retain cycles

## Configuration

**Environment Variables:**
- No .env file pattern
- All configuration via UserDefaults (soundEnabled, autoAccept, themeId)
- Hardcoded IPC paths in `ClaudeMonitor` (e.g., `~/.claude/claumagotchi/`)
- System sound names via `NSSound(named:)`

---

*Convention analysis: 2026-03-19*
