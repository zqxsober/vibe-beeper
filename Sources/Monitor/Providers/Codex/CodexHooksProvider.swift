import Foundation

@MainActor
final class CodexHooksProvider {
    let kind: ProviderKind = .codex

    func translateHookPayload(_ payload: [String: Any]) -> AgentEvent? {
        guard let hookEventName = payload["hook_event_name"] as? String else { return nil }
        let sessionId = payload["session_id"] as? String ?? ""
        let tool = payload["tool_name"] as? String

        switch hookEventName {
        case "UserPromptSubmit", "PreToolUse":
            return .toolStarted(sessionId: sessionId, provider: .codex, tool: tool)
        case "PostToolUse":
            return .toolFinished(sessionId: sessionId, provider: .codex, tool: tool)
        case "Stop":
            return .runCompleted(
                sessionId: sessionId,
                provider: .codex,
                summary: payload["last_assistant_message"] as? String
            )
        case "StopFailure":
            return .runFailed(
                sessionId: sessionId,
                provider: .codex,
                message: payload["message"] as? String
            )
        case "PermissionRequest":
            return .approvalRequested(
                sessionId: sessionId,
                provider: .codex,
                tool: tool ?? "",
                summary: payload["message"] as? String ?? payload["description"] as? String ?? ""
            )
        default:
            return nil
        }
    }
}
