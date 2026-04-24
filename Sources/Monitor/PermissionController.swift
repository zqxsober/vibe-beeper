import Foundation

// MARK: - Permission Types

/// Reflects `permissions.defaultMode` in ~/.claude/settings.json.
enum PermissionMode: Equatable {
    case cautious   // "default" or field missing
    case guided     // "plan"
    case bypass     // "bypass" (covers both Guarded YOLO and Full YOLO)
}

func readPermissionMode() -> PermissionMode {
    let path = NSHomeDirectory() + "/.claude/settings.json"
    guard let data = FileManager.default.contents(atPath: path),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        return .cautious
    }
    if let perms = json["permissions"] as? [String: Any],
       let mode = perms["defaultMode"] as? String {
        switch mode {
        case "plan": return .guided
        case "bypassPermissions": return .bypass
        default: return .cautious
        }
    }
    if let mode = json["permission_mode"] as? String {
        switch mode {
        case "plan": return .guided
        case "bypass": return .bypass
        default: break
        }
    }
    return .cautious
}

// MARK: - Permission Controller (ARCH-03)

extension ClaudeMonitor {

    func promoteNextPendingPermissionOrResolveState() {
        if let next = httpServer.pendingDeferredConnections.first {
            pendingPermission = PendingPermission(
                sessionId: next.id,
                provider: next.provider,
                tool: "",
                summary: "Pending permission"
            )
            awaitingUserAction = true
            state = .approveQuestion
            return
        }

        pendingPermission = nil
        awaitingUserAction = false
        updateAggregateState()
    }

    func respondToPermission(allow: Bool) {
        guard let permission = pendingPermission else { return }
        let decision: [String: Any] = allow
            ? ["behavior": "allow"]
            : ["behavior": "deny", "message": "Denied via vibe-beeper"]
        let response: [String: Any] = [
            "hookSpecificOutput": [
                "hookEventName": "PermissionRequest",
                "decision": decision
            ]
        ]
        let hasMore = httpServer.sendPermissionResponse(
            response,
            for: permission.provider,
            sessionId: permission.sessionId
        )

        // Always clear the session's approveQuestion state so updateAggregateState
        // doesn't immediately restore it. If Claude Code is alive, the next hook
        // event will re-add the session with the correct state.
        sessionStore.removeSession(permission.sessionId, provider: permission.provider)

        pendingPermission = nil
        awaitingUserAction = false

        if hasMore {
            promoteNextPendingPermissionOrResolveState()
        } else {
            // Let aggregate state resolve from all active sessions rather than
            // hardcoding — prevents hiding other working sessions (AUDIT-FIX).
            updateAggregateState()
        }
    }
}
