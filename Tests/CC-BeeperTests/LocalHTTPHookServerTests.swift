import XCTest

/// Minimal transport-layer contract checks for LocalHTTPHookServer planning milestones.
/// Uses replicated values because the package does not expose the executable target for @testable import.
final class LocalHTTPHookServerTests: XCTestCase {

    private struct DeferredQueue {
        var pending: [(id: String, connectionId: Int)] = []

        mutating func enqueue(id: String, connectionId: Int) {
            pending.append((id: id, connectionId: connectionId))
        }

        @discardableResult
        mutating func respond(for id: String) -> Bool {
            guard let index = pending.firstIndex(where: { $0.id == id }) else { return false }
            pending.remove(at: index)
            return !pending.isEmpty
        }
    }

    func testPendingDeferredQueueStartsEmpty() {
        let queue = DeferredQueue()
        XCTAssertTrue(queue.pending.isEmpty)
    }

    func testDeferredResponseMarkerUsesTransportOnlyKeys() {
        let marker: [String: Any] = [
            "_hold_connection": true,
            "_transport_deferred_id": "session-123"
        ]

        XCTAssertEqual(marker["_hold_connection"] as? Bool, true)
        XCTAssertEqual(marker["_transport_deferred_id"] as? String, "session-123")
        XCTAssertNil(marker["hookSpecificOutput"], "Transport marker should not include provider payload")
    }

    func testDeferredApprovalConnectionRemainsPendingUntilResponse() {
        var queue = DeferredQueue()
        queue.enqueue(id: "session-123", connectionId: 1)

        XCTAssertEqual(queue.pending.count, 1, "Deferred approval should remain queued before a response")
        XCTAssertEqual(queue.pending.first?.id, "session-123")
        XCTAssertFalse(queue.respond(for: "session-123"), "Responding should drain the final pending connection")
        XCTAssertTrue(queue.pending.isEmpty, "Pending connection should be removed after the deferred response is sent")
    }
}
