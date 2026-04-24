import Foundation

struct ClaudeProvider {
    static let kind: ProviderKind = .claude
}

extension ClaudeMonitor {

    /// Translates Claude hook payloads into the existing JSONL event format
    /// and routes them to processEvent(). Returns nil for async hooks.
    /// For permission_prompt notifications, returns a sentinel that keeps
    /// the HTTP connection open until the user responds.
    func handleClaudeHookPayload(_ payload: [String: Any]) -> [String: Any]? {
        guard let hookEventName = payload["hook_event_name"] as? String else { return nil }
        let sessionId = payload["session_id"] as? String ?? ""

        logClaudeHookEvent(payload, hookEventName: hookEventName, sessionId: sessionId)

        let toolName = payload["tool_name"] as? String
        let ts = Int(Date().timeIntervalSince1970)

        let eventType: String
        switch hookEventName {
        case "UserPromptSubmit":
            eventType = "pre_tool"
        case "PreToolUse":
            eventType = "pre_tool"
        case "PostToolUse":
            eventType = "post_tool"
        case "Notification":
            return handleClaudeNotification(payload, sessionId: sessionId, toolName: toolName, ts: ts)
        case "Stop":
            eventType = "stop"
            handleClaudeStopPayload(payload, sessionId: sessionId)
        case "StopFailure":
            eventType = "stop_failure"
            if let msg = payload["message"] as? String, !msg.isEmpty {
                errorDetail = String(msg.prefix(30))
            } else {
                errorDetail = "Unknown error"
            }
        case "PermissionRequest":
            return handleClaudePermissionRequest(payload, sessionId: sessionId, toolName: toolName, ts: ts)
        default:
            return nil
        }

        var syntheticEvent: [String: Any] = [
            "event": eventType,
            "sid": sessionId,
            "ts": ts,
        ]
        if let tool = toolName {
            syntheticEvent["tool"] = tool
        }

        processClaudeSyntheticEvent(syntheticEvent)
        return nil
    }

    private func logClaudeHookEvent(_ payload: [String: Any], hookEventName: String, sessionId: String) {
        let hookLogPath = Self.ipcDir + "/hooks.log"
        let hasMsg = payload["last_assistant_message"] != nil
        let logLine = "[\(ISO8601DateFormatter().string(from: Date()))] \(hookEventName) sid=\(sessionId.prefix(8)) hasMsg=\(hasMsg)\n"
        if let data = logLine.data(using: .utf8), let fileHandle = FileHandle(forWritingAtPath: hookLogPath) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            try? fileHandle.close()
        } else if let data = logLine.data(using: .utf8) {
            try? data.write(to: URL(fileURLWithPath: hookLogPath))
        }
    }

    private func handleClaudeNotification(
        _ payload: [String: Any],
        sessionId: String,
        toolName: String?,
        ts: Int
    ) -> [String: Any]? {
        let notificationType = payload["notification_type"] as? String ?? ""
        let message = payload["message"] as? String ?? ""

        switch notificationType {
        case "permission_prompt":
            let mode = readPermissionMode()
            let promptTool = toolName ?? payload["title"] as? String ?? ""
            let isAutoApproved = mode == .bypass ||
                (currentPreset.allowedTools?.contains(promptTool) == true)
            if isAutoApproved {
                return Self.autoApproveResponse
            }

            var syntheticEvent: [String: Any] = [
                "event": "notification",
                "type": "permission_prompt",
                "sid": sessionId,
                "ts": ts,
            ]
            if let msg = payload["message"] as? String {
                syntheticEvent["summary"] = msg
                if let tool = toolName {
                    syntheticEvent["tool"] = tool
                } else if let title = payload["title"] as? String {
                    syntheticEvent["tool"] = title
                }
            }
            processClaudeSyntheticEvent(syntheticEvent)
            return LocalHTTPHookServer.deferredResponseMarker(id: sessionId)

        case "question", "gsd", "discuss", "multiple_choice", "wcv", "elicitation_dialog":
            inputMessage = String(message.prefix(30))
            processClaudeSyntheticEvent([
                "event": "notification",
                "type": "needs_input",
                "sid": sessionId,
                "ts": ts,
                "message": message,
            ])
            return nil

        case "auth_success", "auth_error":
            authFlashMessage = notificationType == "auth_success" ? "AUTH OK" : "AUTH FAIL"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                self?.authFlashMessage = nil
            }
            return nil

        case "idle_prompt":
            processClaudeSyntheticEvent([
                "event": "stop",
                "sid": sessionId,
                "ts": ts,
            ])
            return nil

        default:
            inputMessage = String(message.prefix(30))
            processClaudeSyntheticEvent([
                "event": "notification",
                "type": "needs_input",
                "sid": sessionId,
                "ts": ts,
                "message": message,
            ])
            return nil
        }
    }

    private func handleClaudeStopPayload(_ payload: [String: Any], sessionId: String) {
        if let summary = payload["last_assistant_message"] as? String, !summary.isEmpty {
            lastSummary = summary
            if voiceOver && !isMuted && !isRecording {
                Task { [weak self] in
                    guard let self else { return }
                    _ = await self.ttsService.speakSummary(summary, provider: self.ttsProvider)
                }
            }
            return
        }

        let logPath = Self.ipcDir + "/voice.log"
        let logEntry = "[\(ISO8601DateFormatter().string(from: Date()))] Stop event missing last_assistant_message for session \(sessionId)\n"
        guard let logData = logEntry.data(using: .utf8) else { return }

        if FileManager.default.fileExists(atPath: logPath), let fileHandle = FileHandle(forWritingAtPath: logPath) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(logData)
            try? fileHandle.close()
        } else {
            try? logData.write(to: URL(fileURLWithPath: logPath))
        }
    }

    private func handleClaudePermissionRequest(
        _ payload: [String: Any],
        sessionId: String,
        toolName: String?,
        ts: Int
    ) -> [String: Any]? {
        let tool = toolName ?? ""
        if tool == "AskUserQuestion" {
            let message = payload["message"] as? String ?? payload["description"] as? String ?? ""
            inputMessage = String(message.prefix(30))
            processClaudeSyntheticEvent([
                "event": "notification",
                "type": "needs_input",
                "sid": sessionId,
                "ts": ts,
                "message": message,
            ])
            return LocalHTTPHookServer.deferredResponseMarker(id: sessionId)
        }

        let mode = readPermissionMode()
        let isAutoApproved = mode == .bypass ||
            (currentPreset.allowedTools?.contains(tool) == true)
        if isAutoApproved {
            return Self.autoApproveResponse
        }

        var syntheticEvent: [String: Any] = [
            "event": "notification",
            "type": "permission_prompt",
            "sid": sessionId,
            "ts": ts,
        ]
        if !tool.isEmpty {
            syntheticEvent["tool"] = tool
        }
        if let msg = payload["message"] as? String ?? payload["description"] as? String {
            syntheticEvent["summary"] = msg
        }

        processClaudeSyntheticEvent(syntheticEvent)
        return LocalHTTPHookServer.deferredResponseMarker(id: sessionId)
    }

    private func processClaudeSyntheticEvent(_ event: [String: Any]) {
        guard let json = try? JSONSerialization.data(withJSONObject: event),
              let jsonString = String(data: json, encoding: .utf8) else { return }
        processEvent(jsonString)
    }
}
