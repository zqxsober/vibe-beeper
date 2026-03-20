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

    // MARK: UNUserNotificationCenterDelegate

    /// Called when a notification arrives while the app is in the foreground.
    /// Without this, macOS suppresses banners for foreground apps — critical for a menu bar app
    /// that is always running.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // MARK: Categories

    private func registerCategories() {
        center.setNotificationCategories([
            UNNotificationCategory(identifier: "PERMISSION_REQUEST", actions: [], intentIdentifiers: []),
            UNNotificationCategory(identifier: "SESSION_DONE",        actions: [], intentIdentifiers: []),
            UNNotificationCategory(identifier: "TOOL_ERROR",          actions: [], intentIdentifiers: []),
        ])
    }

    // MARK: Public Send Methods

    func sendPermissionRequest(tool: String, summary: String) {
        send(
            id: "perm-\(UUID().uuidString)",
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
            id: "err-\(UUID().uuidString)",
            categoryId: "TOOL_ERROR",
            title: "Claude Tool Error",
            body: "\(tool) encountered an error."
        )
    }

    func sendPermissionTimeout() {
        send(
            id: "timeout-\(UUID().uuidString)",
            categoryId: "TOOL_ERROR",
            title: "Permission Timed Out",
            body: "A permission request was not answered in time."
        )
    }

    // MARK: Private Helper

    private func send(id: String, categoryId: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = categoryId
        // timeInterval must be > 0; 0.1 delivers immediately in practice.
        // A nil trigger can show inconsistent behaviour on macOS — always use interval trigger.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
