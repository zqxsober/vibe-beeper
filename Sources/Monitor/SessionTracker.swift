import Foundation

// MARK: - Session Tracker (ARCH-02)
// Manages per-session state, event processing, and priority-based aggregate state resolution.

extension ClaudeMonitor {

    func applyAgentEvent(_ event: AgentEvent) {
        switch event {
        case let .toolStarted(sessionId, provider, tool),
             let .toolFinished(sessionId, provider, tool):
            idleWork?.cancel()
            doneDebounceWork?.cancel()
            if let tool { currentTool = tool }
            if sessionStore.state(for: sessionId, provider: provider) != .working {
                thinkingStartTime = Date()
            }
            if !sessionId.isEmpty {
                sessionStore.setState(sessionId: sessionId, provider: provider, state: .working)
            }
            if ttsService.isSpeaking {
                ttsService.stopSpeaking()
            }
            updateAggregateState()
            startIdleTimer(interval: 120)

        case let .runCompleted(sessionId, provider, summary):
            if !sessionId.isEmpty {
                sessionStore.setState(sessionId: sessionId, provider: provider, state: .done)
            }
            if let summary, !summary.isEmpty {
                lastSummary = summary
            }
            thinkingStartTime = nil
            currentTool = nil
            updateAggregateState()
            if state == .done {
                startIdleTimer(interval: 180)
            }

        case let .runFailed(sessionId, provider, message):
            if !sessionId.isEmpty {
                sessionStore.setState(sessionId: sessionId, provider: provider, state: .error)
            }
            if let message, !message.isEmpty {
                errorDetail = String(message.prefix(30))
            }
            thinkingStartTime = nil
            currentTool = nil
            updateAggregateState()
            if state == .error {
                startIdleTimer(interval: 30)
            }

        case let .approvalRequested(sessionId, provider, tool, summary):
            idleWork?.cancel()
            setupGlobalHotkeys()
            if !sessionId.isEmpty {
                sessionStore.setState(sessionId: sessionId, provider: provider, state: .approveQuestion)
            }
            pendingPermission = PendingPermission(
                sessionId: sessionId,
                provider: provider,
                tool: tool,
                summary: summary.isEmpty ? tool.lowercased() : summary
            )
            awaitingUserAction = true
            thinkingStartTime = Date()
            state = .approveQuestion
            sessionCount = sessionStore.sessionCount()
            playAlert()
            startIdleTimer(interval: 300)

        case let .inputRequested(sessionId, provider, message):
            idleWork?.cancel()
            inputMessage = String(message.prefix(30))
            if !sessionId.isEmpty {
                sessionStore.setState(sessionId: sessionId, provider: provider, state: .needsInput)
            }
            awaitingUserAction = true
            updateAggregateState()
            playAlert()
            startIdleTimer(interval: 300)

        case let .authStatus(_, success):
            authFlashMessage = success ? "AUTH OK" : "AUTH FAIL"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                self?.authFlashMessage = nil
            }
        }
    }

    func processEvent(_ json: String) {
        guard let data = json.data(using: .utf8),
              let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = event["event"] as? String,
              event["sid"] is String,
              event["ts"] is Int else { return }

        let sid = event["sid"] as? String ?? ""

        if !sid.isEmpty {
            sessionStore.touch(sessionId: sid, provider: .claude)
        }

        // Permission — trigger approveQuestion
        if type == "notification" && event["type"] as? String == "permission_prompt" {
            idleWork?.cancel()
            let tool = event["tool"] as? String ?? ""
            let summary = event["summary"] as? String ?? tool.lowercased()
            setupGlobalHotkeys()

            if currentPreset == .yolo {
                pendingPermission = PendingPermission(
                    sessionId: sid,
                    provider: .claude,
                    tool: tool,
                    summary: summary
                )
                Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    self?.respondToPermission(allow: true)
                }
            } else {
                if !sid.isEmpty { sessionStore.setState(sessionId: sid, provider: .claude, state: .approveQuestion) }
                sessionCount = sessionStore.sessionCount()
                if pendingPermission == nil {
                    pendingPermission = PendingPermission(
                        sessionId: sid,
                        provider: .claude,
                        tool: tool,
                        summary: summary
                    )
                    awaitingUserAction = true
                    thinkingStartTime = Date()
                    state = .approveQuestion
                    playAlert()
                }
                // Watchdog: if Claude Code dies without sending Stop, reset after 5 min
                startIdleTimer(interval: 300)
            }
            return
        }
        if type == "permission_timeout" { return }

        // Needs input
        if type == "notification" && event["type"] as? String == "needs_input" {
            idleWork?.cancel()
            if !sid.isEmpty { sessionStore.setState(sessionId: sid, provider: .claude, state: .needsInput) }
            awaitingUserAction = true
            updateAggregateState()
            playAlert()
            // Watchdog: if Claude Code dies without sending Stop, reset after 5 min
            startIdleTimer(interval: 300)
            return
        }

        // Orphan cleanup — session moved on
        if awaitingUserAction && (type == "pre_tool" || type == "post_tool" || type == "stop" || type == "stop_failure") {
            httpServer.cancelOrphanedPermission(for: sid, provider: .claude)
            promoteNextPendingPermissionOrResolveState()
        }

        idleWork?.cancel()

        switch type {
        case "pre_tool", "post_tool":
            doneDebounceWork?.cancel()  // Cancel pending DONE transition (DONE-DEBOUNCE)
            let tool = event["tool"] as? String
            if let tool { currentTool = tool }
            if sessionStore.state(for: sid, provider: .claude) != .working {
                thinkingStartTime = Date()
            }
            if !sid.isEmpty { sessionStore.setState(sessionId: sid, provider: .claude, state: .working) }
            if ttsService.isSpeaking {
                ttsService.stopSpeaking()
            }
            updateAggregateState()
            // Watchdog: if Claude Code dies mid-work without Stop, reset after 2 min.
            // Each new tool event resets this (idleWork is cancelled at line 74).
            startIdleTimer(interval: 120)
        case "stop":
            if !sid.isEmpty { sessionStore.setState(sessionId: sid, provider: .claude, state: .done) }
            thinkingStartTime = nil
            currentTool = nil
            // Debounce DONE: wait before showing DONE to avoid false flashes from
            // subagent stops or brief gaps between turns (DONE-DEBOUNCE).
            doneDebounceWork?.cancel()
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.updateAggregateState()
                    if self.state == .done {
                        if self.currentPreset != .yolo { self.playDoneChime() }
                        self.startIdleTimer(interval: 180)
                    }
                }
            }
            doneDebounceWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: work)
        case "stop_failure":
            if !sid.isEmpty { sessionStore.setState(sessionId: sid, provider: .claude, state: .error) }
            thinkingStartTime = nil
            currentTool = nil
            updateAggregateState()
            // Auto-recover from error after 30s so the widget doesn't stay stuck (AUDIT-FIX).
            if state == .error { startIdleTimer(interval: 30) }
        case "session_start":
            if !sid.isEmpty { sessionStore.setState(sessionId: sid, provider: .claude, state: .working) }
            updateAggregateState()
        case "session_end":
            if !sid.isEmpty { sessionStore.removeSession(sid, provider: .claude) }
            lastPruneTime = .distantPast
            updateAggregateState()
        default:
            break
        }
    }

    /// Derive the overall state from all active sessions using priority-based resolution.
    func updateAggregateState() {
        // Prune sessions not seen for 2 hours
        if Date().timeIntervalSince(lastPruneTime) > 30 {
            let cutoff = Date().addingTimeInterval(-7200)
            let staleSessionIds = sessionStore.pruneSessions(olderThan: cutoff)
            for sid in staleSessionIds {
                httpServer.cancelOrphanedPermission(for: sid, provider: .claude)
                httpServer.cancelOrphanedPermission(for: sid, provider: .codex)
            }
            lastPruneTime = Date()
        }

        if awaitingUserAction && pendingPermission != nil {
            // If the underlying connection is gone, clear the stale permission state
            if httpServer.pendingDeferredConnections.isEmpty {
                awaitingUserAction = false
                pendingPermission = nil
            } else {
                state = .approveQuestion
                return
            }
        }

        let values = sessionStore.aggregateState()
        let count = sessionStore.sessionCount()
        if count == 0 {
            sessionCount = 0
            if state != .listening && state != .speaking {
                let oldState = state
                state = .idle
                if oldState != .idle {
                    idleStartTime = Date()
                }
            }
            return
        }

        // Always update aggregate state unless voice is active (local, not session-driven)
        if state != .listening && state != .speaking {
            let oldState = state
            state = values
            if state == .idle && oldState != .idle {
                idleStartTime = Date()
            }
            if state != .idle {
                idleStartTime = nil
            }
        }
        sessionCount = count
    }
}
