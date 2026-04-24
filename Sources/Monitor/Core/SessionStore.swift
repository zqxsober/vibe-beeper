import Foundation

@MainActor
final class SessionStore {
    private struct SessionKey: Hashable {
        let provider: ProviderKind
        let sessionId: String
    }

    private struct SessionRecord {
        var state: AgentState
        var lastSeen: Date
        var provider: ProviderKind
    }

    private var sessions: [SessionKey: SessionRecord] = [:]

    func setState(sessionId: String, provider: ProviderKind, state: AgentState, at date: Date = Date()) {
        guard !sessionId.isEmpty else { return }
        sessions[SessionKey(provider: provider, sessionId: sessionId)] = SessionRecord(
            state: state,
            lastSeen: date,
            provider: provider
        )
    }

    func touch(sessionId: String, provider: ProviderKind, at date: Date = Date()) {
        let key = SessionKey(provider: provider, sessionId: sessionId)
        guard !sessionId.isEmpty, var record = sessions[key] else { return }
        record.lastSeen = date
        record.provider = provider
        sessions[key] = record
    }

    func state(for sessionId: String, provider: ProviderKind) -> AgentState? {
        sessions[SessionKey(provider: provider, sessionId: sessionId)]?.state
    }

    func removeSession(_ sessionId: String, provider: ProviderKind) {
        sessions.removeValue(forKey: SessionKey(provider: provider, sessionId: sessionId))
    }

    func removeAll(provider: ProviderKind? = nil) {
        guard let provider else {
            sessions.removeAll()
            return
        }
        sessions = sessions.filter { $0.value.provider != provider }
    }

    func aggregateState(provider: ProviderKind? = nil) -> AgentState {
        let values = sessions.values
            .filter { provider == nil || $0.provider == provider }
            .map(\.state)
        return values.max(by: { $0.priority < $1.priority }) ?? .idle
    }

    func sessionCount(provider: ProviderKind? = nil) -> Int {
        guard let provider else { return sessions.count }
        return sessions.values.filter { $0.provider == provider }.count
    }

    func lastSeen(for sessionId: String) -> Date? {
        sessions.first(where: { $0.key.sessionId == sessionId })?.value.lastSeen
    }

    func lastSeen(for sessionId: String, provider: ProviderKind) -> Date? {
        sessions[SessionKey(provider: provider, sessionId: sessionId)]?.lastSeen
    }

    func pruneSessions(olderThan cutoff: Date, provider: ProviderKind? = nil) -> [String] {
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
