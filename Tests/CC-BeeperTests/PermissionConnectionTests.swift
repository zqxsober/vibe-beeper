import XCTest

/// Tests for the deferred connection FIFO queue — ordering, concurrency, and orphan cleanup (AUDIT-04).
/// Uses replicated logic (no @testable import).

// MARK: - Replicated Deferred Queue

private struct TestDeferredQueue {
    var connections: [(provider: String, sessionId: String, connectionId: Int)] = []

    mutating func append(provider: String, sessionId: String, connectionId: Int) {
        connections.append((provider: provider, sessionId: sessionId, connectionId: connectionId))
    }

    @discardableResult
    mutating func respond(for provider: String, sessionId: String) -> Bool {
        guard let index = connections.firstIndex(where: { $0.provider == provider && $0.sessionId == sessionId }) else { return false }
        connections.remove(at: index)
        return !connections.isEmpty
    }

    mutating func cancelOrphaned(for provider: String, sessionId: String) -> [Int] {
        var cancelled: [Int] = []
        connections.removeAll { entry in
            if entry.provider == provider && entry.sessionId == sessionId {
                cancelled.append(entry.connectionId)
                return true
            }
            return false
        }
        return cancelled
    }
}

// MARK: - Tests

final class PermissionConnectionXCTests: XCTestCase {

    func testFIFOOrdering() {
        var q = TestDeferredQueue()
        q.append(provider: "claude", sessionId: "session-A", connectionId: 1)
        q.append(provider: "claude", sessionId: "session-B", connectionId: 2)
        XCTAssertEqual(q.connections.first?.sessionId, "session-A", "FIFO: oldest request first")
    }

    func testConcurrentConnectionsNotOverwritten() {
        var q = TestDeferredQueue()
        q.append(provider: "claude", sessionId: "session-A", connectionId: 1)
        q.append(provider: "claude", sessionId: "session-B", connectionId: 2)
        XCTAssertEqual(q.connections.count, 2, "Both connections must be tracked (AUDIT-04)")
        let ids = q.connections.map(\.sessionId)
        XCTAssertTrue(ids.contains("session-A"))
        XCTAssertTrue(ids.contains("session-B"))
    }

    func testRespondRemovesCorrectSession() {
        var q = TestDeferredQueue()
        q.append(provider: "claude", sessionId: "session-A", connectionId: 1)
        q.append(provider: "claude", sessionId: "session-B", connectionId: 2)
        q.respond(for: "claude", sessionId: "session-A")
        XCTAssertEqual(q.connections.count, 1)
        XCTAssertEqual(q.connections.first?.sessionId, "session-B")
    }

    func testRespondReturnsTrueWhenMorePending() {
        var q = TestDeferredQueue()
        q.append(provider: "claude", sessionId: "session-A", connectionId: 1)
        q.append(provider: "claude", sessionId: "session-B", connectionId: 2)
        XCTAssertTrue(q.respond(for: "claude", sessionId: "session-A"), "Should return true when more pending")
        XCTAssertFalse(q.respond(for: "claude", sessionId: "session-B"), "Should return false when queue empty")
    }

    func testOrphanCleanupRemovesSessionConnections() {
        var q = TestDeferredQueue()
        q.append(provider: "claude", sessionId: "session-A", connectionId: 1)
        q.append(provider: "claude", sessionId: "session-A", connectionId: 2)
        q.append(provider: "claude", sessionId: "session-B", connectionId: 3)
        let cancelled = q.cancelOrphaned(for: "claude", sessionId: "session-A")
        XCTAssertEqual(q.connections.count, 1, "Only session-B should remain")
        XCTAssertEqual(q.connections.first?.sessionId, "session-B")
        XCTAssertEqual(cancelled.count, 2, "Both session-A connections should be cancelled")
    }

    func testOrphanCleanupForNonexistentSessionIsNoOp() {
        var q = TestDeferredQueue()
        let cancelled = q.cancelOrphaned(for: "claude", sessionId: "nonexistent")
        XCTAssertTrue(q.connections.isEmpty)
        XCTAssertTrue(cancelled.isEmpty)
    }

    func testMultiplePermissionsFromSameSession() {
        var q = TestDeferredQueue()
        q.append(provider: "claude", sessionId: "session-A", connectionId: 1)
        q.append(provider: "claude", sessionId: "session-A", connectionId: 2)
        XCTAssertEqual(q.connections.count, 2)
        q.respond(for: "claude", sessionId: "session-A")
        XCTAssertEqual(q.connections.count, 1)
        XCTAssertEqual(q.connections.first?.connectionId, 2, "First-in removed, second remains")
    }

    func testSameSessionIdAcrossProvidersDoesNotCollide() {
        var q = TestDeferredQueue()
        q.append(provider: "claude", sessionId: "shared-session", connectionId: 1)
        q.append(provider: "codex", sessionId: "shared-session", connectionId: 2)

        XCTAssertTrue(q.respond(for: "codex", sessionId: "shared-session"))
        XCTAssertEqual(q.connections.count, 1)
        XCTAssertEqual(q.connections.first?.provider, "claude")
        XCTAssertEqual(q.connections.first?.connectionId, 1)
    }
}
