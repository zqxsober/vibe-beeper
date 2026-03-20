# Phase 4: Notifications - Research

**Researched:** 2026-03-20
**Domain:** macOS UserNotifications framework (UNUserNotificationCenter), SwiftUI MenuBarExtra, UserDefaults persistence
**Confidence:** HIGH

## Summary

Phase 4 adds macOS Notification Center alerts for three events (permission request, session completion, tool error/timeout) plus a menu bar toggle to enable/disable them. The implementation integrates entirely into existing code: `ClaudeMonitor.swift` gains a `NotificationManager` helper and a `notificationsEnabled` UserDefaults-backed property, mirroring the established `soundEnabled` / `autoAccept` pattern. `ClaumagotchiApp.swift` gains one new `Button` in the `MenuBarExtra`.

The critical research finding is that `UNUserNotificationCenter` requires the app to be **code-signed** to display the system permission dialog and send notifications on macOS. The project's `build.sh` script creates a proper `.app` bundle with a `CFBundleIdentifier` (`com.claumagotchi.app`), but does not sign it. Ad-hoc signing (`codesign --force --deep --sign -`) will be sufficient for this non-App-Store distribution — the permission dialog will appear and notifications will work. No App Sandbox entitlement is needed. The `LSUIElement = true` (accessory policy, no Dock icon) has no negative effect on notification delivery.

`NSUserNotification` / `NSUserNotificationCenter` are deprecated since macOS 11. Use `UNUserNotificationCenter` (available since macOS 10.14; this project targets macOS 14).

**Primary recommendation:** Implement a `NotificationManager` class in a new `Sources/NotificationManager.swift` file. Wire permission requests, session completions, and errors to three distinct notification calls. Add `notificationsEnabled` to `ClaudeMonitor` using the same `@Published var + didSet UserDefaults` pattern already used for `soundEnabled` and `autoAccept`. Add a single toggle `Button` to the `MenuBarExtra` in `ClaumagotchiApp.swift`.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| NOTIF-01 | macOS Notification Center alert fires when a permission request arrives | `processEvent` already has a clear permission branch — call `NotificationManager.sendPermissionRequest(tool:summary:)` there |
| NOTIF-02 | Notification fires when a Claude session finishes | The `"stop"` case in `processEvent` triggers `playDoneChime()` — add a parallel `NotificationManager` call in the same guard block |
| NOTIF-03 | Notification fires on tool errors or permission timeouts | `post_tool_error` already handled in the `switch`; `permission_timeout` has a dedicated branch — add notification calls to both |
| NOTIF-04 | User can enable/disable notifications via menu bar toggle, persisting across restarts | `soundEnabled` is the exact pattern to clone: `@Published var notificationsEnabled: Bool { didSet { UserDefaults.standard.set(...) } }` plus a `Button` in `MenuBarExtra` |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `UserNotifications` | macOS 14 (built-in) | Request permission, send local notifications, delegate callbacks | Apple's official notification framework since macOS 10.14; `NSUserNotification` deprecated in macOS 11 |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `UserDefaults.standard` | built-in | Persist `notificationsEnabled` toggle | Same pattern already used for `soundEnabled`, `autoAccept` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `UNUserNotificationCenter` | `NSUserNotification` | `NSUserNotification` was deprecated in macOS 11 — do not use |
| Three distinct category IDs | Single category | Category IDs allow future per-type muting; cost is trivial |

**Installation:**
No new dependencies. `import UserNotifications` in the new file.

## Architecture Patterns

### Recommended Project Structure
```
Sources/
├── ClaumagotchiApp.swift     # Add toggle Button in MenuBarExtra
├── ClaudeMonitor.swift       # Add notificationsEnabled property + calls to NotificationManager
├── NotificationManager.swift # NEW — wraps UNUserNotificationCenter
├── ContentView.swift
├── ScreenView.swift
└── ThemeManager.swift
```

### Pattern 1: NotificationManager as a standalone helper (not ObservableObject)

**What:** A lightweight class (or enum with static methods) that encapsulates `UNUserNotificationCenter`. `ClaudeMonitor` holds a private instance and calls its methods at the three event points.

**When to use:** The notification system has no published state of its own — it fires and forgets. An `ObservableObject` with `@Published` properties would add unnecessary overhead. A plain class with three public send-methods is sufficient.

**Example:**
```swift
// Source: UserNotifications framework — Apple Developer Documentation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
        registerCategories()
    }

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            // macOS 14: system remembers this; won't re-prompt unless user revokes
        }
    }

    // Called when a notification arrives while app is in foreground.
    // Without this delegate + completion handler, macOS suppresses the banner.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    private func registerCategories() {
        let permissionCategory = UNNotificationCategory(
            identifier: "PERMISSION_REQUEST",
            actions: [],
            intentIdentifiers: []
        )
        let doneCategory = UNNotificationCategory(
            identifier: "SESSION_DONE",
            actions: [],
            intentIdentifiers: []
        )
        let errorCategory = UNNotificationCategory(
            identifier: "TOOL_ERROR",
            actions: [],
            intentIdentifiers: []
        )
        center.setNotificationCategories([permissionCategory, doneCategory, errorCategory])
    }

    func sendPermissionRequest(tool: String, summary: String) {
        send(
            id: "permission-\(UUID().uuidString)",
            categoryId: "PERMISSION_REQUEST",
            title: "Claude Needs Your Permission",
            body: "\(tool): \(summary)"
        )
    }

    func sendSessionDone() {
        send(
            id: "done-\(UUID().uuidString)",
            categoryId: "SESSION_DONE",
            title: "Claude Is Done",
            body: "Session completed."
        )
    }

    func sendToolError(tool: String) {
        send(
            id: "error-\(UUID().uuidString)",
            categoryId: "TOOL_ERROR",
            title: "Claude Tool Error",
            body: "\(tool) encountered an error."
        )
    }

    private func send(id: String, categoryId: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = categoryId

        // timeInterval must be > 0; 0.1 delivers immediately in practice
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }
}
```

### Pattern 2: notificationsEnabled follows soundEnabled pattern exactly

**What:** A `@Published var` on `ClaudeMonitor` backed by `UserDefaults`, with a `didSet` observer.

**Example:**
```swift
// In ClaudeMonitor.swift — mirrors soundEnabled
@Published var notificationsEnabled: Bool {
    didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled") }
}

// In init():
notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
```

### Pattern 3: Guard on notificationsEnabled before every send

**What:** Each call site in `processEvent` checks `notificationsEnabled` before calling `NotificationManager`.

**Example:**
```swift
// In processEvent, permission branch:
if !autoAccept && notificationsEnabled {
    notificationManager.sendPermissionRequest(tool: tool, summary: summary)
}

// In stop case:
if state == .finished && notificationsEnabled {
    notificationManager.sendSessionDone()
}
```

### Pattern 4: requestPermission at app start, not lazily

**What:** Call `notificationManager.requestPermission()` in `ClaudeMonitor.init()` so the system permission dialog appears on first launch.

**Why:** If `requestAuthorization` is called lazily (at first notification), the user may miss the first notification entirely while the dialog is pending.

### Pattern 5: MenuBarExtra toggle mirrors soundEnabled button

```swift
// In ClaumagotchiApp.swift MenuBarExtra content:
Button(monitor.notificationsEnabled ? "Disable Notifications" : "Enable Notifications") {
    monitor.notificationsEnabled.toggle()
}
.keyboardShortcut("n")
```

### Anti-Patterns to Avoid
- **Sending notifications without a `UNUserNotificationCenterDelegate`:** If the app is in the foreground (which it always is as an always-running menu bar app), macOS suppresses banners unless the delegate returns `[.banner, .sound]` in `willPresent`.
- **Using `trigger: nil`:** On macOS, a nil trigger causes the notification to be delivered immediately but some versions of macOS have shown inconsistent behavior. Always use `UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)`.
- **Setting the delegate after sending the first notification:** Set `center.delegate = self` in `init()` before `requestPermission()`.
- **Reusing the same notification `identifier`:** Using the same `id` for multiple notifications causes the system to replace the previous one. Use UUID-based IDs.
- **Cloning soundEnabled guard without cloning the UserDefaults init:** Forgetting `as? Bool ?? true` in `init()` causes `notificationsEnabled` to default to `false` on first launch.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Notification scheduling | Custom timer + NSAlert | `UNUserNotificationCenter` | System handles Do Not Disturb, Focus modes, notification grouping, persistence in Notification Center |
| Permission dialog | Custom NSPanel asking for permission | `requestAuthorization(options:)` | OS-level: appears with trusted system UI, remembered in System Settings > Notifications |
| Foreground banner suppression | Custom overlay view | `willPresent` delegate returning `[.banner, .sound]` | System-standard behavior; no custom UI needed |

## Common Pitfalls

### Pitfall 1: Foreground notifications are silently dropped

**What goes wrong:** Notifications are requested and added to the center with `center.add(request)`, but no banner ever appears when the app is running.

**Why it happens:** By default, macOS suppresses notification banners when the originating app is in the foreground. For a menu bar app that is always running, this means every notification is suppressed unless you implement the delegate.

**How to avoid:** Implement `UNUserNotificationCenterDelegate` and set it as `center.delegate = self` in `NotificationManager.init()`. In `userNotificationCenter(_:willPresent:withCompletionHandler:)`, call `completionHandler([.banner, .sound])`.

**Warning signs:** Notifications appear in Notification Center history but no banner fires live.

### Pitfall 2: Notifications work locally but fail on first run (unsigned binary)

**What goes wrong:** `requestAuthorization` callback returns `granted = false` with no visible dialog.

**Why it happens:** `UNUserNotificationCenter` requires the process to be code-signed. The build script creates an `.app` bundle with a proper `CFBundleIdentifier` but does **not** sign it. Running an unsigned `.app` prevents the permission dialog from appearing.

**How to avoid:** Add ad-hoc signing to `build.sh`:
```bash
codesign --force --deep --sign - Claumagotchi.app
```
Ad-hoc signing (`-`) is sufficient for local distribution. No Apple Developer account required.

**Warning signs:** `requestAuthorization` completion handler fires immediately with `granted = false`. No system dialog appears. Notification sends silently fail.

### Pitfall 3: The first permission request notification is missed

**What goes wrong:** User never sees the very first permission notification because `requestAuthorization` hasn't been called yet when the first event fires.

**Why it happens:** If authorization is requested lazily (only when the first notification is sent), the permission dialog and the notification arrive at the same time. The system may queue or drop the notification while the dialog is pending.

**How to avoid:** Call `notificationManager.requestPermission()` during `ClaudeMonitor.init()` so authorization is settled before any events arrive.

### Pitfall 4: "Enable/disable notifications" toggle bypasses system-level permission

**What goes wrong:** Developer implements the toggle but forgets that the *system* can also disable notifications (System Settings > Notifications > Claumagotchi). The app's toggle says "enabled" but no notifications appear.

**Why it happens:** `notificationsEnabled` is an in-app preference. The system-level authorization is separate.

**How to avoid:** The toggle only needs to guard sends at the code level. There is no need to reconcile with system settings — if the user disabled at the OS level, that's intentional. Do not add complexity for this edge case (REQUIREMENTS.md explicitly marks "actionable notification buttons" as out of scope, keeping the feature simple).

### Pitfall 5: NOTIF-03 fires on every `post_tool_error` including common ones

**What goes wrong:** Every tool retry or minor error triggers a notification banner, creating noise.

**Why it happens:** `post_tool_error` fires for all tool errors, including minor ones that Claude recovers from automatically.

**How to avoid:** This is noted in REQUIREMENTS.md scope without further qualification — the simplest correct implementation sends a notification on every `post_tool_error` event (not just fatal ones). The planner should implement it literally as specified: one notification per `post_tool_error` event. Users who find it noisy can disable all notifications via NOTIF-04.

## Code Examples

### Full NotificationManager skeleton
```swift
// Source: UserNotifications framework — Apple Developer Documentation
// https://developer.apple.com/documentation/usernotifications/unusernotificationcenter
import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
        registerCategories()
    }

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    private func registerCategories() {
        center.setNotificationCategories([
            UNNotificationCategory(identifier: "PERMISSION_REQUEST", actions: [], intentIdentifiers: []),
            UNNotificationCategory(identifier: "SESSION_DONE",        actions: [], intentIdentifiers: []),
            UNNotificationCategory(identifier: "TOOL_ERROR",          actions: [], intentIdentifiers: []),
        ])
    }

    func sendPermissionRequest(tool: String, summary: String) {
        send(id: "perm-\(UUID().uuidString)", categoryId: "PERMISSION_REQUEST",
             title: "Claude Needs Your Permission", body: "\(tool): \(summary)")
    }

    func sendSessionDone() {
        send(id: "done-\(UUID().uuidString)", categoryId: "SESSION_DONE",
             title: "Claude Is Done", body: "Session completed.")
    }

    func sendToolError(tool: String) {
        send(id: "err-\(UUID().uuidString)", categoryId: "TOOL_ERROR",
             title: "Claude Tool Error", body: "\(tool) encountered an error.")
    }

    private func send(id: String, categoryId: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = categoryId
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
```

### ClaudeMonitor: adding notificationsEnabled (mirrors soundEnabled)
```swift
// In ClaudeMonitor — new property alongside soundEnabled
@Published var notificationsEnabled: Bool {
    didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled") }
}
private let notificationManager = NotificationManager()

// In init(), alongside soundEnabled init:
notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
notificationManager.requestPermission()
```

### build.sh: adding ad-hoc code signing
```bash
# Add after "echo 'Built Claumagotchi.app'" line:
codesign --force --deep --sign - Claumagotchi.app
echo "Signed Claumagotchi.app (ad-hoc)"
```

### MenuBarExtra toggle button
```swift
// In ClaumagotchiApp.swift MenuBarExtra content, alongside soundEnabled button:
Button(monitor.notificationsEnabled ? "Disable Notifications" : "Enable Notifications") {
    monitor.notificationsEnabled.toggle()
}
.keyboardShortcut("n")
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `NSUserNotification` / `NSUserNotificationCenter` | `UNUserNotificationCenter` (UserNotifications framework) | Deprecated macOS 11 (2020); replacement available since macOS 10.14 | Project targets macOS 14 — use `UNUserNotificationCenter` exclusively |
| Synchronous `requestAuthorization` callback | `async/await` form: `try await center.requestAuthorization(options:)` | Swift 5.5 / macOS 12 | Either form works on macOS 14; callback form is fine since no async context is needed in `init()` |

**Deprecated/outdated:**
- `NSUserNotification`: deprecated macOS 11, do not use
- `NSUserNotificationCenter`: deprecated macOS 11, do not use
- `UNNotificationPresentationOptions.alert`: renamed to `.banner` in macOS 12. Use `.banner` on macOS 14 target.

## Open Questions

1. **Does the existing Claumagotchi.app receive ad-hoc signing during normal distribution (GitHub releases)?**
   - What we know: `build.sh` does not currently call `codesign`. The DMG creation script (`create-dmg.sh`) may sign or quarantine-clear.
   - What's unclear: Whether users who downloaded the app via GitHub releases ever see the notification permission dialog today.
   - Recommendation: Read `create-dmg.sh` before planning. If it doesn't sign, add `codesign --force --deep --sign - Claumagotchi.app` to `build.sh` as part of this phase. This is a zero-risk change for local distribution.

2. **Should NOTIF-03 fire for `permission_timeout` events as well?**
   - What we know: REQUIREMENTS.md says "Notification fires on tool errors or permission timeouts." `processEvent` has a `permission_timeout` branch that currently returns early.
   - What's unclear: Whether `permission_timeout` is a frequent/expected event or a rare edge case.
   - Recommendation: Implement it — send a "Permission timed out" notification in the `permission_timeout` branch. REQUIREMENTS.md says "or permission timeouts" explicitly.

## Validation Architecture

> `workflow.nyquist_validation` is absent from `.planning/config.json` — treating as enabled.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None detected — no test targets in `Package.swift`, no `Tests/` directory |
| Config file | None — see Wave 0 |
| Quick run command | N/A |
| Full suite command | N/A |

### Phase Requirements → Test Map

This project has no automated test infrastructure. All validation is manual smoke testing. The TEST-01 / TEST-02 / TEST-03 requirements are explicitly deferred to v2 (see REQUIREMENTS.md).

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NOTIF-01 | Banner appears when permission event fires | manual smoke | — manual only | N/A |
| NOTIF-02 | Banner appears when session finishes (stop event) | manual smoke | — manual only | N/A |
| NOTIF-03 | Banner appears on `post_tool_error` and `permission_timeout` | manual smoke | — manual only | N/A |
| NOTIF-04 | Toggle persists across app restarts | manual smoke | — manual only | N/A |

**Justification for manual-only:** There is no test harness and the requirements are deferred to v2. UI/notification framework interaction requires a running app on macOS. Unit tests for UserNotifications would require mocking `UNUserNotificationCenter`, which is out of scope for v1.1.

### Sampling Rate
- **Per task:** Build the app (`make build`), verify no compilation errors, verify notification permission dialog appears on first launch.
- **Phase gate:** Four manual smoke tests (one per requirement) before marking phase complete.

### Wave 0 Gaps
- None — no automated test infrastructure is planned for this phase. Manual verification covers all requirements.

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation — `UNUserNotificationCenter` (https://developer.apple.com/documentation/usernotifications/unusernotificationcenter)
- Apple Developer Documentation — `UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:)` (https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate/usernotificationcenter(_:willpresent:withcompletionhandler:))
- Apple Developer Documentation — `requestAuthorization(options:completionHandler:)` (https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/requestauthorization(options:completionhandler:))
- Apple Developer Documentation — Asking permission to use notifications (https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications)
- Apple Developer Documentation — `NSUserNotification` deprecation note (https://developer.apple.com/documentation/foundation/nsusernotification)
- Project source code — `ClaudeMonitor.swift`, `ClaumagotchiApp.swift`, `build.sh`, `Package.swift` (direct read)

### Secondary (MEDIUM confidence)
- `desktop-notifier` Python library docs (https://github.com/samschott/desktop-notifier) — confirms code signing is required for `UNUserNotificationCenter` on macOS; confirmed independently by Apple forum content
- createwithswift.com — async/await authorization pattern (https://www.createwithswift.com/notifications-tutorial-requesting-user-authorization-for-notifications-with-async-await/)
- peerdh.com — SwiftUI macOS notifications integration pattern (https://peerdh.com/blogs/programming-insights/integrating-swiftui-with-macos-notifications-for-real-time-updates-1)

### Tertiary (LOW confidence)
- Apple Developer Forums thread 115322 — `UNUserNotificationCenter` on macOS (content not renderable, forum metadata only)
- Apple Developer Forums thread 679326 — LaunchAgent + UNUserNotificationCenter limitations (search summary only, not full content)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — `UNUserNotificationCenter` is the unambiguous replacement for deprecated `NSUserNotification`; confirmed by Apple deprecation notes
- Architecture: HIGH — `NotificationManager` pattern and `willPresent` delegate requirement confirmed by multiple sources; `soundEnabled` mirror pattern confirmed by direct source read
- Code signing requirement: HIGH — confirmed by `desktop-notifier` library docs and Apple forum references; critical pitfall
- Pitfalls: HIGH for delegate/foreground suppression and signing; MEDIUM for NOTIF-03 noise (judgment call, not a technical uncertainty)

**Research date:** 2026-03-20
**Valid until:** 2026-09-20 (stable API — UserNotifications framework changes infrequently)
