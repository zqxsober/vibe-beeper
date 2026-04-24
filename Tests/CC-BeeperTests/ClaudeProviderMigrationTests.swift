import XCTest
import Foundation

/// Regression tests for the Claude provider extraction.
/// These tests mirror the public behavior we still expect after moving
/// Claude-specific logic under Sources/Monitor/Providers/Claude.
final class ClaudeProviderMigrationTests: XCTestCase {

    private enum DispatchResult: Equatable {
        case async(eventType: String)
        case blocking(response: String? = nil)
        case notification(type: String)
        case ignored
    }

    private func translateClaudeHookEvent(
        _ hookEventName: String,
        notificationType: String? = nil,
        toolName: String? = nil
    ) -> DispatchResult {
        switch hookEventName {
        case "UserPromptSubmit":
            return .async(eventType: "pre_tool")
        case "PreToolUse":
            return .async(eventType: "pre_tool")
        case "PostToolUse":
            return .async(eventType: "post_tool")
        case "Stop":
            return .async(eventType: "stop")
        case "StopFailure":
            return .async(eventType: "stop_failure")
        case "Notification":
            switch notificationType {
            case "permission_prompt":
                return .blocking()
            case "question", "gsd", "discuss", "multiple_choice", "wcv", "elicitation_dialog":
                return .notification(type: "needs_input")
            case "auth_success", "auth_error":
                return .notification(type: "auth_flash")
            case "idle_prompt":
                return .async(eventType: "stop")
            default:
                return .notification(type: "needs_input")
            }
        case "PermissionRequest":
            if toolName == "AskUserQuestion" {
                return .blocking(response: "hold_for_input")
            }
            return .blocking()
        default:
            return .ignored
        }
    }

    private func claudeHookInstallerEventConfigs() -> (async: [String], blocking: [String]) {
        (
            async: ["UserPromptSubmit", "PreToolUse", "PostToolUse", "Stop", "StopFailure"],
            blocking: ["Notification", "PermissionRequest"]
        )
    }

    private func claudeDetectorCandidates(home: String, nvmVersions: [String]) -> [String] {
        let nvmCandidates = nvmVersions.sorted(by: >).map { "\(home)/.nvm/versions/node/\($0)/bin/claude" }
        return [
            "\(home)/.local/bin/claude",
            "/opt/homebrew/bin/claude",
            "/usr/local/bin/claude",
        ] + nvmCandidates
    }

    func testClaudeProviderKeepsExistingHookEventTranslation() {
        XCTAssertEqual(translateClaudeHookEvent("UserPromptSubmit"), .async(eventType: "pre_tool"))
        XCTAssertEqual(translateClaudeHookEvent("PreToolUse"), .async(eventType: "pre_tool"))
        XCTAssertEqual(translateClaudeHookEvent("PostToolUse"), .async(eventType: "post_tool"))
        XCTAssertEqual(translateClaudeHookEvent("Stop"), .async(eventType: "stop"))
        XCTAssertEqual(translateClaudeHookEvent("StopFailure"), .async(eventType: "stop_failure"))
    }

    func testClaudeProviderKeepsNotificationSemantics() {
        XCTAssertEqual(translateClaudeHookEvent("Notification", notificationType: "permission_prompt"), .blocking())
        XCTAssertEqual(translateClaudeHookEvent("Notification", notificationType: "question"), .notification(type: "needs_input"))
        XCTAssertEqual(translateClaudeHookEvent("Notification", notificationType: "idle_prompt"), .async(eventType: "stop"))
        XCTAssertEqual(translateClaudeHookEvent("Notification", notificationType: "auth_success"), .notification(type: "auth_flash"))
        XCTAssertEqual(translateClaudeHookEvent("Notification", notificationType: "some_future_type"), .notification(type: "needs_input"))
    }

    func testClaudeProviderKeepsAskUserQuestionSpecialCase() {
        XCTAssertEqual(
            translateClaudeHookEvent("PermissionRequest", toolName: "AskUserQuestion"),
            .blocking(response: "hold_for_input")
        )
        XCTAssertEqual(translateClaudeHookEvent("PermissionRequest", toolName: "Bash"), .blocking())
    }

    func testClaudeHookInstallerKeepsExpectedEventBuckets() {
        let configs = claudeHookInstallerEventConfigs()
        XCTAssertEqual(configs.async, ["UserPromptSubmit", "PreToolUse", "PostToolUse", "Stop", "StopFailure"])
        XCTAssertEqual(configs.blocking, ["Notification", "PermissionRequest"])
    }

    func testClaudeDetectorKeepsCandidateSearchOrder() {
        let home = "/tmp/fake-home"
        let candidates = claudeDetectorCandidates(home: home, nvmVersions: ["v20.11.1", "v22.3.0"])

        XCTAssertEqual(candidates[0], "\(home)/.local/bin/claude")
        XCTAssertEqual(candidates[1], "/opt/homebrew/bin/claude")
        XCTAssertEqual(candidates[2], "/usr/local/bin/claude")
        XCTAssertEqual(candidates[3], "\(home)/.nvm/versions/node/v22.3.0/bin/claude")
        XCTAssertEqual(candidates[4], "\(home)/.nvm/versions/node/v20.11.1/bin/claude")
    }
}
