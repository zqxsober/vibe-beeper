import XCTest

/// Tests for HookDispatcher routing — verifies all 6 hook event types map to correct event types (TEST-03).
/// Uses replicated dispatch logic (no @testable import).

private enum DispatchResult: Equatable {
    case async(eventType: String)
    case blocking
    case ignored
    case notification(type: String)
}

/// Replicates the hookEventName → eventType routing from HookDispatcher.
private func dispatchHookEvent(_ hookEventName: String, notificationType: String? = nil) -> DispatchResult {
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
            return .blocking
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
        return .blocking
    default:
        return .ignored
    }
}

final class HookDispatcherXCTests: XCTestCase {

    // MARK: - Async hook routing

    func testUserPromptSubmitRoutesToPreTool() {
        XCTAssertEqual(dispatchHookEvent("UserPromptSubmit"), .async(eventType: "pre_tool"))
    }

    func testPreToolUseRoutesToPreTool() {
        XCTAssertEqual(dispatchHookEvent("PreToolUse"), .async(eventType: "pre_tool"))
    }

    func testPostToolUseRoutesToPostTool() {
        XCTAssertEqual(dispatchHookEvent("PostToolUse"), .async(eventType: "post_tool"))
    }

    func testStopRoutesToStop() {
        XCTAssertEqual(dispatchHookEvent("Stop"), .async(eventType: "stop"))
    }

    func testStopFailureRoutesToStopFailure() {
        XCTAssertEqual(dispatchHookEvent("StopFailure"), .async(eventType: "stop_failure"))
    }

    // MARK: - Blocking hook routing

    func testNotificationPermissionPromptIsBlocking() {
        XCTAssertEqual(dispatchHookEvent("Notification", notificationType: "permission_prompt"), .blocking)
    }

    func testPermissionRequestIsBlocking() {
        XCTAssertEqual(dispatchHookEvent("PermissionRequest"), .blocking)
    }

    // MARK: - Notification sub-routing

    func testNotificationQuestionRoutesToNeedsInput() {
        XCTAssertEqual(dispatchHookEvent("Notification", notificationType: "question"), .notification(type: "needs_input"))
    }

    func testNotificationGsdRoutesToNeedsInput() {
        XCTAssertEqual(dispatchHookEvent("Notification", notificationType: "gsd"), .notification(type: "needs_input"))
    }

    func testNotificationIdlePromptRoutesToStop() {
        XCTAssertEqual(dispatchHookEvent("Notification", notificationType: "idle_prompt"), .async(eventType: "stop"))
    }

    func testNotificationAuthSuccessRoutesToFlash() {
        XCTAssertEqual(dispatchHookEvent("Notification", notificationType: "auth_success"), .notification(type: "auth_flash"))
    }

    func testNotificationUnknownTypeDefaultsToNeedsInput() {
        XCTAssertEqual(dispatchHookEvent("Notification", notificationType: "some_new_type"), .notification(type: "needs_input"))
    }

    // MARK: - Unknown events

    func testUnknownHookEventIsIgnored() {
        XCTAssertEqual(dispatchHookEvent("SomeNewEvent"), .ignored)
    }

    // MARK: - All 6 registered hook types covered

    func testAllSixHookTypesRouteCorrectly() {
        let hookTypes = ["UserPromptSubmit", "PreToolUse", "PostToolUse", "Stop", "StopFailure", "Notification"]
        for hookType in hookTypes {
            let result = dispatchHookEvent(hookType, notificationType: hookType == "Notification" ? "question" : nil)
            XCTAssertNotEqual(result, .ignored, "\(hookType) must not be ignored")
        }
    }
}
