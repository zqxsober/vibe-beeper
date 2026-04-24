import Foundation
import Network

typealias HTTPHookServer = LocalHTTPHookServer

extension LocalHTTPHookServer {

    /// Compatibility shim for the existing Claude-oriented call sites.
    var pendingPermissionConnections: [(sessionId: String, connection: NWConnection)] {
        pendingDeferredConnections.map { (sessionId: $0.id, connection: $0.connection) }
    }

    /// Compatibility shim for the existing permission controller flow.
    @discardableResult
    func sendPermissionResponse(_ payload: [String: Any], for provider: ProviderKind, sessionId: String) -> Bool {
        sendDeferredResponse(payload, for: provider, id: sessionId)
    }

    /// Compatibility shim for the existing orphan-cleanup flow.
    func cancelOrphanedPermission(for sessionId: String, provider: ProviderKind = .claude) {
        let denyPayload: [String: Any] = [
            "hookSpecificOutput": [
                "hookEventName": "PermissionRequest",
                "decision": ["behavior": "deny", "message": "Session moved on"]
            ]
        ]
        cancelDeferredResponses(for: provider, id: sessionId, fallbackPayload: denyPayload)
    }
}
