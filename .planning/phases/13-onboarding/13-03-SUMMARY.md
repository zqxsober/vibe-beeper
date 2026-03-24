---
phase: 13-onboarding
plan: 03
subsystem: ui
tags: [swiftui, macos, onboarding, appstorage, environment, window-management]

# Dependency graph
requires:
  - phase: 13-onboarding-01
    provides: AppMover.moveToApplicationsIfNeeded() static method
  - phase: 13-onboarding-02
    provides: OnboardingView self-contained SwiftUI view (480x400)
provides:
  - onboarding Window scene wired into app lifecycle
  - first-launch guard showing onboarding and hiding beeper
  - "Setup..." menu bar entry reopening onboarding at any time
  - AppMover called before onboarding check on every launch
  - AX permission prompt scoped to returning users only
affects: [14-distribution, 15-voice-api]

# Tech tracking
tech-stack:
  added: []
  patterns: [use @Environment(\.openWindow) in App struct not AppDelegate, @AppStorage for UserDefaults-backed reactive flag in App struct]

key-files:
  created: []
  modified:
    - Sources/ClaumagotchiApp.swift

key-decisions:
  - "@Environment(\.openWindow) must live in App struct (or a SwiftUI view), not AppDelegate — AppDelegate is not in the SwiftUI environment"
  - "First-launch guard moved to ContentView.onAppear with .onAppear + DispatchQueue.main.asyncAfter(0.1s) to ensure window is ready"
  - "AX prompt retained for returning users (hasOnboarded && !AXIsProcessTrusted()) — onboarding handles new users"
  - "openWindow(id: 'onboarding') is idempotent — SwiftUI brings existing window to front if already open"

patterns-established:
  - "Pattern: openWindow(id:) from @Environment for cross-scene window management in macOS SwiftUI apps"
  - "Pattern: first-launch guard via @AppStorage flag checked in .onAppear, not in AppDelegate"

requirements-completed: [ONBD-05, ONBD-06, ONBD-07]

# Metrics
duration: 25min
completed: 2026-03-24
---

# Phase 13 Plan 03: Onboarding App Lifecycle Wiring Summary

**Onboarding Window scene wired into ClaumagotchiApp with first-launch guard via @AppStorage + @Environment(\.openWindow), AppMover integration, and "Setup..." menu bar entry**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-03-24T18:00:00Z
- **Completed:** 2026-03-24T18:45:00Z
- **Tasks:** 2 (1 auto + 1 human-verify checkpoint)
- **Files modified:** 1

## Accomplishments
- Added `Window("Setup CC-Beeper", id: "onboarding")` scene with `.windowStyle(.titleBar)`, `.windowResizability(.contentSize)`, `.defaultPosition(.center)`, `.defaultSize(width: 480, height: 400)`
- First-launch guard in `ContentView.onAppear` hides beeper and opens onboarding when `hasCompletedOnboarding == false`
- "Setup..." button in MenuBarExtra allows returning users to reopen the onboarding wizard at any time
- `AppMover.moveToApplicationsIfNeeded()` called in `applicationDidFinishLaunching` before onboarding check
- Removed legacy "Enable Global Hotkeys..." menu button (now handled by onboarding Permissions step)
- User-approved full onboarding flow: window opens on first launch, all 5 screens navigate correctly

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire onboarding Window scene, AppDelegate first-launch guard, and menu bar Setup entry** - `3198cab` (feat)
2. **Task 2: Fix openWindow call moved to ContentView.onAppear via @Environment** - `fbf1402` (fix)

**Plan metadata:** _(docs commit follows)_

## Files Created/Modified
- `Sources/ClaumagotchiApp.swift` - Added onboarding Window scene, first-launch guard in ContentView.onAppear, "Setup..." menu entry, AppMover call, removed legacy AX prompt block and "Enable Global Hotkeys" button

## Decisions Made
- `@Environment(\.openWindow)` must be in the App struct (SwiftUI environment), not AppDelegate. AppDelegate is an NSObject outside the SwiftUI view hierarchy and cannot access environment values.
- First-launch guard placed in `ContentView.onAppear` (not AppDelegate) so `openWindow` is available via environment.
- `DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)` used to allow SwiftUI to finish rendering the Window scene before hiding/showing windows.
- AX permission prompt retained for returning users who haven't granted it yet (`hasOnboarded && !AXIsProcessTrusted()`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Moved openWindow from AppDelegate to ContentView.onAppear**
- **Found during:** Task 1 build/test (discovered by orchestrator during human-verify phase)
- **Issue:** Plan specified opening the onboarding window in `AppDelegate.applicationDidFinishLaunching` via `NSApp.windows` loop, but `@Environment(\.openWindow)` cannot be called from AppDelegate (not a SwiftUI environment). The `NSApp.windows` loop-based approach also failed because SwiftUI Window scenes may not be registered in `NSApp.windows` at launch time.
- **Fix:** Moved first-launch guard to `ContentView.onAppear` with `@Environment(\.openWindow)`. Added `@AppStorage("hasCompletedOnboarding")` to `ClaumagotchiApp` struct. "Setup..." button also updated to use `openWindow(id: "onboarding")` directly.
- **Files modified:** Sources/ClaumagotchiApp.swift
- **Verification:** App built and launched; onboarding window opened correctly on first launch; user approved flow.
- **Committed in:** `fbf1402` (Task 2 fix commit)

---

**Total deviations:** 1 auto-fixed (1 bug — incorrect placement of openWindow call)
**Impact on plan:** Fix was necessary for correct operation. No scope creep. The architectural intent of the plan (onboarding-first launch) is fully preserved.

## Issues Encountered
- `@Environment(\.openWindow)` is only available in SwiftUI view hierarchy. AppDelegate (NSObject) cannot use it. Resolved by moving the first-launch guard into `ContentView.onAppear`.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Complete onboarding lifecycle is wired and user-verified
- `hasCompletedOnboarding` UserDefaults key is the handoff signal — OnboardingView (Plan 02) sets it to `true` on the final "Launch CC-Beeper" step
- Plans 04+ (voice API keys, Groq keychain) can build on top of this foundation
- Blocker noted: VOICE-06 (Groq API key prompt) bridges Phase 13 and 15 — Phase 15 Keychain service must be planned before finalizing that onboarding step

---
*Phase: 13-onboarding*
*Completed: 2026-03-24*
