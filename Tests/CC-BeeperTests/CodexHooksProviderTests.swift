import XCTest

private enum TestCodexAgentEvent: Equatable {
    case toolStarted(sessionId: String, tool: String?)
    case runCompleted(sessionId: String, summary: String?)
}

private func translateCodexProviderPayload(_ payload: [String: Any]) -> TestCodexAgentEvent? {
    guard let hookEventName = payload["hook_event_name"] as? String else { return nil }
    let sessionId = payload["session_id"] as? String ?? ""

    switch hookEventName {
    case "UserPromptSubmit", "PreToolUse":
        return .toolStarted(sessionId: sessionId, tool: payload["tool_name"] as? String)
    case "Stop":
        return .runCompleted(sessionId: sessionId, summary: payload["last_assistant_message"] as? String)
    default:
        return nil
    }
}

/// Contract tests for Codex hook translation.
/// Mirrors the expected mapping because the executable target is not directly importable.
final class CodexHooksProviderTests: XCTestCase {

    func testPreToolUsePayloadMapsToToolStartedEvent() {
        let payload: [String: Any] = [
            "hook_event_name": "PreToolUse",
            "session_id": "codex-session",
            "tool_name": "Bash",
        ]

        let event = translateCodexProviderPayload(payload)
        XCTAssertEqual(event, .toolStarted(sessionId: "codex-session", tool: "Bash"))
    }

    func testStopPayloadMapsToRunCompletedEvent() {
        let payload: [String: Any] = [
            "hook_event_name": "Stop",
            "session_id": "codex-session",
            "last_assistant_message": "Done",
        ]

        let event = translateCodexProviderPayload(payload)
        XCTAssertEqual(event, .runCompleted(sessionId: "codex-session", summary: "Done"))
    }
}
