---
phase: 05-settings-window
plan: 01
subsystem: ui
tags: [keychain, security-framework, api-key-validation, swiftui-window, activation-policy, macos]

# Dependency graph
requires: []
provides:
  - KeychainHelper with save/load/delete for API keys via Security.framework
  - APIKeyValidator async validation for Anthropic (POST /v1/messages) and OpenAI (GET /v1/models)
  - APIProvider enum with keychainKey property
  - ValidationResult enum (valid / invalid / networkError)
  - Settings Window scene registered with id "settings", 550x400 default size
  - openSettingsWindow() static helper with activation policy juggling
  - Activation policy restoration to .accessory on settings window close
  - "Settings..." menu item with Cmd+, keyboard shortcut
affects: [05-settings-window, 07-ai-summary]

# Tech tracking
tech-stack:
  added: [Security.framework (Keychain), URLSession async/await for API validation]
  patterns:
    - Delete-then-add upsert pattern for Keychain (avoids errSecDuplicateItem)
    - Window identifier iteration pattern (mirrors existing toggleMainWindow)
    - Activation policy juggling: .accessory -> .regular on open, restore on willCloseNotification

key-files:
  created:
    - Sources/KeychainHelper.swift
    - Sources/APIKeyValidator.swift
  modified:
    - Sources/ClaumagotchiApp.swift

key-decisions:
  - "Used custom Window scene (id: settings) not SwiftUI Settings scene — openSettings broken on macOS 26 Tahoe"
  - "Keychain upsert via SecItemDelete+SecItemAdd (not SecItemUpdate) — simpler, avoids query/attributes split"
  - "Anthropic 529 mapped to networkError not invalid — temporary overload is not a key validity signal"
  - "Settings placeholder text in Window scene — Plan 02 replaces with full SettingsView()"
  - "Settings... menu item inserted between YOLO mode and sound toggles — logical grouping"

patterns-established:
  - "Pattern: Window scene with known identifier opened via NSApp.windows iteration (same as main window)"
  - "Pattern: Activation policy .regular on open, restored via willCloseNotification observer"
  - "Pattern: KeychainHelper enum (not class) with static functions — stateless, no instantiation needed"

requirements-completed: [SET-01, SET-04]

# Metrics
duration: 5min
completed: 2026-03-20
---

# Phase 05 Plan 01: Settings Window Infrastructure Summary

**Keychain-backed API key storage and Settings Window scene with activation policy juggling for menu bar app focus**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-20T16:35:26Z
- **Completed:** 2026-03-20T16:40:28Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- KeychainHelper.swift: thin Security.framework wrapper with save/load/delete using kSecClassGenericPassword, delete-before-add upsert pattern to avoid errSecDuplicateItem
- APIKeyValidator.swift: async URLSession-based validation for Anthropic (POST /v1/messages, 529 = networkError) and OpenAI (GET /v1/models), 10-second timeout
- ClaumagotchiApp.swift: Settings Window scene registered, openSettingsWindow() with activation policy juggling, willCloseNotification observer restoring .accessory, "Settings..." menu item with Cmd+,

## Task Commits

Each task was committed atomically:

1. **Task 1: Create KeychainHelper and APIKeyValidator** - `e2ac591` (feat)
2. **Task 2: Register Settings Window scene and add openSettingsWindow helper** - `dc9e9be` (feat)

## Files Created/Modified
- `Sources/KeychainHelper.swift` - Keychain save/load/delete for secure API key storage (new)
- `Sources/APIKeyValidator.swift` - Async API key validation for Anthropic and OpenAI (new)
- `Sources/ClaumagotchiApp.swift` - Settings Window scene, openSettingsWindow(), menu item (modified)

## Decisions Made
- Used custom `Window` scene with identifier "settings" instead of SwiftUI `Settings` scene — `openSettings` environment action is broken on macOS 26 Tahoe from MenuBarExtra
- Keychain upsert pattern: SecItemDelete + SecItemAdd (not SecItemUpdate) — simpler, avoids the confusing query/attributes split that SecItemUpdate requires
- Anthropic HTTP 529 mapped to `.networkError` not `.invalid` — 529 is a temporary overload status, not a key validity signal
- Settings placeholder `Text("Settings placeholder")` used in Window scene — SettingsView is wired in Plan 02
- "Settings..." menu item placed between YOLO mode toggle and sound toggles (with surrounding Dividers)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None — build passed cleanly on first attempt for both tasks.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All infrastructure for Plan 02 (SettingsView) is in place: KeychainHelper and APIKeyValidator are exported types, Window scene is registered with environmentObject injections for monitor and themeManager
- Plan 02 can replace `Text("Settings placeholder")` with `SettingsView()` and wire up all UI
- The Settings window will appear blank (placeholder text only) until Plan 02 completes

---
*Phase: 05-settings-window*
*Completed: 2026-03-20*
