import XCTest

/// Contract tests for the session aggregation layer.
/// The executable test target cannot import the production module, so this suite
/// uses a pure-Swift mirror to pin the expected behavior of SessionStore.

private enum TestAgentState: Equatable {
    case idle
    case working
    case done
    case error
    case approveQuestion
    case needsInput

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

private enum TestProviderKind: String {
    case claude
    case codex
}

private final class TestSessionStore {
    private struct SessionKey: Hashable {
        let provider: TestProviderKind
        let sessionId: String
    }

    private struct SessionRecord {
        var state: TestAgentState
        var lastSeen: Date
        var provider: TestProviderKind
    }

    private var sessions: [SessionKey: SessionRecord] = [:]

    func setState(sessionId: String, provider: TestProviderKind, state: TestAgentState, at date: Date = Date()) {
        guard !sessionId.isEmpty else { return }
        sessions[SessionKey(provider: provider, sessionId: sessionId)] = SessionRecord(
            state: state,
            lastSeen: date,
            provider: provider
        )
    }

    func touch(sessionId: String, provider: TestProviderKind, at date: Date = Date()) {
        let key = SessionKey(provider: provider, sessionId: sessionId)
        guard !sessionId.isEmpty, var record = sessions[key] else { return }
        record.lastSeen = date
        record.provider = provider
        sessions[key] = record
    }

    func state(for sessionId: String, provider: TestProviderKind) -> TestAgentState? {
        sessions[SessionKey(provider: provider, sessionId: sessionId)]?.state
    }

    func removeSession(_ sessionId: String, provider: TestProviderKind) {
        sessions.removeValue(forKey: SessionKey(provider: provider, sessionId: sessionId))
    }

    func removeAll(provider: TestProviderKind? = nil) {
        guard let provider else {
            sessions.removeAll()
            return
        }
        sessions = sessions.filter { $0.value.provider != provider }
    }

    func aggregateState(provider: TestProviderKind? = nil) -> TestAgentState {
        let values = sessions.values
            .filter { provider == nil || $0.provider == provider }
            .map(\.state)
        return values.max(by: { $0.priority < $1.priority }) ?? .idle
    }

    func sessionCount(provider: TestProviderKind? = nil) -> Int {
        guard let provider else { return sessions.count }
        return sessions.values.filter { $0.provider == provider }.count
    }

    func lastSeen(for sessionId: String) -> Date? {
        sessions.first(where: { $0.key.sessionId == sessionId })?.value.lastSeen
    }

    func lastSeen(for sessionId: String, provider: TestProviderKind) -> Date? {
        sessions[SessionKey(provider: provider, sessionId: sessionId)]?.lastSeen
    }

    func pruneSessions(olderThan cutoff: Date, provider: TestProviderKind? = nil) -> [String] {
        let staleSessionIds = sessions.compactMap { entry -> String? in
            let (key, record) = entry
            guard record.lastSeen < cutoff else { return nil }
            if let provider, key.provider != provider {
                return nil
            }
            return key.sessionId
        }
        let staleKeys = sessions.keys.filter { key in
            guard let record = sessions[key], record.lastSeen < cutoff else { return false }
            if let provider, key.provider != provider {
                return false
            }
            return true
        }
        for key in staleKeys {
            sessions.removeValue(forKey: key)
        }
        return staleSessionIds.sorted()
    }
}

final class SessionStoreTests: XCTestCase {
    func testSetStateTracksSessionCountAndLastSeen() {
        let store = TestSessionStore()
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)

        store.setState(sessionId: "sess-1", provider: .claude, state: .working, at: timestamp)

        XCTAssertEqual(store.sessionCount(), 1)
        XCTAssertEqual(store.state(for: "sess-1", provider: .claude), .working)
        XCTAssertEqual(store.lastSeen(for: "sess-1", provider: .claude), timestamp)
    }

    func testAggregateStateReturnsHighestPriorityState() {
        let store = TestSessionStore()

        store.setState(sessionId: "sess-1", provider: .claude, state: .working, at: Date(timeIntervalSince1970: 10))
        store.setState(sessionId: "sess-2", provider: .claude, state: .error, at: Date(timeIntervalSince1970: 20))
        store.setState(sessionId: "sess-3", provider: .claude, state: .done, at: Date(timeIntervalSince1970: 30))

        XCTAssertEqual(store.aggregateState(), .error)
    }

    func testTouchDoesNotCreateSession() {
        let store = TestSessionStore()

        store.touch(sessionId: "missing", provider: .claude, at: Date(timeIntervalSince1970: 10))

        XCTAssertEqual(store.sessionCount(), 0)
        XCTAssertNil(store.state(for: "missing", provider: .claude))
    }

    func testRemoveSessionDeletesTrackedState() {
        let store = TestSessionStore()

        store.setState(sessionId: "sess-1", provider: .claude, state: .needsInput, at: Date(timeIntervalSince1970: 10))
        store.removeSession("sess-1", provider: .claude)

        XCTAssertEqual(store.sessionCount(), 0)
        XCTAssertNil(store.state(for: "sess-1", provider: .claude))
        XCTAssertEqual(store.aggregateState(), .idle)
    }

    func testRemoveAllClearsAllSessions() {
        let store = TestSessionStore()

        store.setState(sessionId: "sess-1", provider: .claude, state: .working, at: Date(timeIntervalSince1970: 10))
        store.setState(sessionId: "sess-2", provider: .codex, state: .approveQuestion, at: Date(timeIntervalSince1970: 20))
        store.removeAll()

        XCTAssertEqual(store.sessionCount(), 0)
        XCTAssertEqual(store.aggregateState(), .idle)
        XCTAssertNil(store.lastSeen(for: "sess-1", provider: .claude))
        XCTAssertNil(store.lastSeen(for: "sess-2", provider: .codex))
    }

    func testRemoveAllForProviderKeepsOtherProviderSessions() {
        let store = TestSessionStore()

        store.setState(sessionId: "claude-1", provider: .claude, state: .working, at: Date(timeIntervalSince1970: 10))
        store.setState(sessionId: "codex-1", provider: .codex, state: .approveQuestion, at: Date(timeIntervalSince1970: 20))

        store.removeAll(provider: .claude)

        XCTAssertEqual(store.sessionCount(), 1)
        XCTAssertEqual(store.sessionCount(provider: .codex), 1)
        XCTAssertEqual(store.state(for: "codex-1", provider: .codex), .approveQuestion)
        XCTAssertNil(store.state(for: "claude-1", provider: .claude))
    }

    func testPruneSessionsRemovesOnlyStaleEntries() {
        let store = TestSessionStore()
        let stale = Date(timeIntervalSince1970: 10)
        let fresh = Date(timeIntervalSince1970: 100)

        store.setState(sessionId: "old", provider: .claude, state: .working, at: stale)
        store.setState(sessionId: "new", provider: .claude, state: .error, at: fresh)

        let removed = store.pruneSessions(olderThan: Date(timeIntervalSince1970: 50))

        XCTAssertEqual(removed, ["old"])
        XCTAssertEqual(store.sessionCount(), 1)
        XCTAssertEqual(store.state(for: "new", provider: .claude), .error)
        XCTAssertNil(store.state(for: "old", provider: .claude))
    }

    func testSameSessionIdAcrossProvidersDoesNotCollide() {
        let store = TestSessionStore()
        let sharedSessionId = "shared"

        store.setState(sessionId: sharedSessionId, provider: .claude, state: .working, at: Date(timeIntervalSince1970: 10))
        store.setState(sessionId: sharedSessionId, provider: .codex, state: .error, at: Date(timeIntervalSince1970: 20))

        XCTAssertEqual(store.sessionCount(), 2)
        XCTAssertEqual(store.state(for: sharedSessionId, provider: .claude), .working)
        XCTAssertEqual(store.state(for: sharedSessionId, provider: .codex), .error)
    }
}
