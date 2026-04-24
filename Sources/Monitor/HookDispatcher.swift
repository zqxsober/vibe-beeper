import Foundation

extension ClaudeMonitor {
    func handleHookPayload(provider: ProviderKind, payload: [String: Any]) -> [String: Any]? {
        switch provider {
        case .claude:
            return handleClaudeHookPayload(payload)
        case .codex:
            guard let hookEventName = payload["hook_event_name"] as? String else { return nil }
            let sessionId = payload["session_id"] as? String ?? ""

            if hookEventName == "PermissionRequest" {
                let tool = payload["tool_name"] as? String ?? ""
                let isAutoApproved = currentPreset == .yolo ||
                    (currentPreset.allowedTools?.contains(tool) == true)
                if isAutoApproved {
                    return Self.autoApproveResponse
                }
            } else if awaitingUserAction &&
                        ["UserPromptSubmit", "PreToolUse", "PostToolUse", "Stop", "StopFailure"].contains(hookEventName) {
                httpServer.cancelOrphanedPermission(for: sessionId, provider: .codex)
                promoteNextPendingPermissionOrResolveState()
            }

            guard let event = codexHooksProvider.translateHookPayload(payload) else { return nil }
            applyAgentEvent(event)
            if hookEventName == "PermissionRequest" {
                return LocalHTTPHookServer.deferredResponseMarker(id: sessionId)
            }
            return nil
        }
    }

    func handleHookPayload(_ payload: [String: Any]) -> [String: Any]? {
        handleHookPayload(provider: ProviderKind.from(payload: payload), payload: payload)
    }
}
