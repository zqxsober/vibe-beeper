import XCTest

/// Integration tests verifying the hook → dispatch → state update pipeline (TEST-05).
/// Replicates the full flow: HTTP POST payload → hookEventName dispatch → processEvent → state resolution.

/// Minimal state machine replicating ClaudeMonitor's session tracking + aggregate state.
private class TestMonitor {
    var state: TestState = .idle
    var sessionStates: [String: TestState] = [:]
    var pendingPermission: String? = nil
    var awaitingUserAction: Bool = false
    var errorDetail: String? = nil
    var inputMessage: String? = nil

    enum TestState: Equatable {
        case idle, working, done, error, approveQuestion, needsInput

        var priority: Int {
            switch self {
            case .error: return 7
            case .approveQuestion: return 6
            case .needsInput: return 5
            case .working: return 2
            case .done: return 1
            case .idle: return 0
            }
        }
    }

    /// Simulate receiving an HTTP hook payload and processing it through the full pipeline.
    func receiveHookPayload(_ payload: [String: Any]) {
        guard let hookEventName = payload["hook_event_name"] as? String else { return }
        let sessionId = payload["session_id"] as? String ?? ""

        // Dispatch phase
        switch hookEventName {
        case "UserPromptSubmit", "PreToolUse":
            applySessionState(sid: sessionId, state: .working)
        case "PostToolUse":
            applySessionState(sid: sessionId, state: .working)
        case "Stop":
            applySessionState(sid: sessionId, state: .done)
        case "StopFailure":
            errorDetail = (payload["message"] as? String) ?? "Unknown error"
            applySessionState(sid: sessionId, state: .error)
        case "Notification":
            let notifType = payload["notification_type"] as? String ?? ""
            switch notifType {
            case "permission_prompt":
                pendingPermission = sessionId
                awaitingUserAction = true
                sessionStates[sessionId] = .approveQuestion
                state = .approveQuestion
                return
            case "question", "gsd", "discuss":
                inputMessage = payload["message"] as? String
                sessionStates[sessionId] = .needsInput
                awaitingUserAction = true
            case "idle_prompt":
                applySessionState(sid: sessionId, state: .done)
                return
            default:
                sessionStates[sessionId] = .needsInput
            }
        case "PermissionRequest":
            pendingPermission = sessionId
            awaitingUserAction = true
            sessionStates[sessionId] = .approveQuestion
            state = .approveQuestion
            return
        default:
            return
        }

        updateAggregateState()
    }

    private func applySessionState(sid: String, state: TestState) {
        if !sid.isEmpty { sessionStates[sid] = state }
        updateAggregateState()
    }

    private func updateAggregateState() {
        if awaitingUserAction && pendingPermission != nil {
            state = .approveQuestion
            return
        }
        let values = Array(sessionStates.values)
        guard !values.isEmpty else { return }
        let highest = values.max(by: { $0.priority < $1.priority }) ?? .idle
        // Match real ClaudeMonitor: always update if new state is higher priority,
        // OR if current state is done/idle (always overridable),
        // OR if the highest comes from session state (authoritative source)
        state = highest
    }
}

final class HookToLCDIntegrationXCTests: XCTestCase {

    // MARK: - PreToolUse → WORKING

    func testPreToolUsePayloadSetsWorkingState() {
        let monitor = TestMonitor()
        monitor.receiveHookPayload([
            "hook_event_name": "PreToolUse",
            "session_id": "sess-1",
            "tool_name": "Bash",
        ])
        XCTAssertEqual(monitor.state, .working)
        XCTAssertEqual(monitor.sessionStates["sess-1"], .working)
    }

    // MARK: - UserPromptSubmit → WORKING

    func testUserPromptSubmitSetsWorkingState() {
        let monitor = TestMonitor()
        monitor.receiveHookPayload([
            "hook_event_name": "UserPromptSubmit",
            "session_id": "sess-1",
        ])
        XCTAssertEqual(monitor.state, .working)
    }

    // MARK: - Stop → DONE

    func testStopPayloadSetsDoneState() {
        let monitor = TestMonitor()
        // Start working first via PreToolUse
        monitor.receiveHookPayload([
            "hook_event_name": "PreToolUse",
            "session_id": "sess-1",
            "tool_name": "Bash",
        ])
        XCTAssertEqual(monitor.state, .working)
        // Now stop — same session transitions working→done
        monitor.receiveHookPayload([
            "hook_event_name": "Stop",
            "session_id": "sess-1",
        ])
        XCTAssertEqual(monitor.state, .done)
    }

    // MARK: - StopFailure → ERROR

    func testStopFailurePayloadSetsErrorState() {
        let monitor = TestMonitor()
        monitor.receiveHookPayload([
            "hook_event_name": "StopFailure",
            "session_id": "sess-1",
            "message": "Tool execution failed",
        ])
        XCTAssertEqual(monitor.state, .error)
        XCTAssertEqual(monitor.errorDetail, "Tool execution failed")
    }

    // MARK: - Notification permission_prompt → APPROVE?

    func testPermissionPromptNotificationSetsApproveState() {
        let monitor = TestMonitor()
        monitor.receiveHookPayload([
            "hook_event_name": "Notification",
            "session_id": "sess-1",
            "notification_type": "permission_prompt",
            "message": "Claude wants to use Bash",
        ])
        XCTAssertEqual(monitor.state, .approveQuestion)
        XCTAssertTrue(monitor.awaitingUserAction)
    }

    // MARK: - Notification question → NEEDS INPUT

    func testQuestionNotificationSetsNeedsInputState() {
        let monitor = TestMonitor()
        monitor.receiveHookPayload([
            "hook_event_name": "Notification",
            "session_id": "sess-1",
            "notification_type": "question",
            "message": "Which database?",
        ])
        XCTAssertEqual(monitor.state, .needsInput)
        XCTAssertEqual(monitor.inputMessage, "Which database?")
    }

    // MARK: - idle_prompt → DONE (not NEEDS INPUT)

    func testIdlePromptNotificationRoutesToDone() {
        let monitor = TestMonitor()
        // Start working first
        monitor.receiveHookPayload([
            "hook_event_name": "PreToolUse",
            "session_id": "sess-1",
            "tool_name": "Read",
        ])
        XCTAssertEqual(monitor.state, .working)
        // idle_prompt should transition to done
        monitor.receiveHookPayload([
            "hook_event_name": "Notification",
            "session_id": "sess-1",
            "notification_type": "idle_prompt",
        ])
        XCTAssertEqual(monitor.state, .done, "idle_prompt must route to DONE, not NEEDS INPUT (AUDIT-01)")
    }

    // MARK: - Multi-session priority resolution

    func testErrorWinsOverWorkingInMultiSession() {
        let monitor = TestMonitor()
        monitor.receiveHookPayload([
            "hook_event_name": "PreToolUse",
            "session_id": "sess-1",
            "tool_name": "Read",
        ])
        XCTAssertEqual(monitor.state, .working)

        monitor.receiveHookPayload([
            "hook_event_name": "StopFailure",
            "session_id": "sess-2",
            "message": "crash",
        ])
        XCTAssertEqual(monitor.state, .error, "Error (priority 7) must win over working (priority 2)")
    }

    // MARK: - PermissionRequest → APPROVE?

    func testPermissionRequestSetsApproveState() {
        let monitor = TestMonitor()
        monitor.receiveHookPayload([
            "hook_event_name": "PermissionRequest",
            "session_id": "sess-1",
            "tool_name": "Bash",
        ])
        XCTAssertEqual(monitor.state, .approveQuestion)
        XCTAssertNotNil(monitor.pendingPermission)
    }
}
