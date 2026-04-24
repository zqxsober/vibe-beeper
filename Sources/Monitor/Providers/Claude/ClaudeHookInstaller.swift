import Foundation

struct ClaudeHookInstaller {
    static let hooksDir = NSHomeDirectory() + "/.claude/hooks"
    static let ipcDir = NSHomeDirectory() + "/.claude/cc-beeper"
    static let settingsPath = NSHomeDirectory() + "/.claude/settings.json"

    /// Marker string for identifying vibe-beeper hooks in settings.json.
    /// Matching `cc-beeper/port` distinguishes HTTP hooks from old Python hooks.
    static let hookMarker = "cc-beeper/port"

    /// Base curl command for async monitoring hooks (PreToolUse, PostToolUse, Stop, StopFailure).
    /// Reads port file, pipes stdin JSON to vibe-beeper's HTTP endpoint.
    private static let asyncCommand = "PORT=$(cat ~/.claude/cc-beeper/port 2>/dev/null || echo 19222) && TOKEN=$(cat ~/.claude/cc-beeper/token 2>/dev/null) && curl -s -o /dev/null -X POST http://localhost:${PORT}/hook -H 'Content-Type: application/json' -H \"Authorization: Bearer ${TOKEN}\" -d @- --max-time 3 || true"

    /// Blocking curl command for Notification and PermissionRequest hooks.
    private static let blockingCommand = "PORT=$(cat ~/.claude/cc-beeper/port 2>/dev/null || echo 19222) && TOKEN=$(cat ~/.claude/cc-beeper/token 2>/dev/null) && curl -s -X POST http://localhost:${PORT}/hook -H 'Content-Type: application/json' -H \"Authorization: Bearer ${TOKEN}\" -d @- --max-time 55"

    static var isInstalled: Bool {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: settingsPath),
              let data = fileManager.contents(atPath: settingsPath),
              let settings = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hooks = settings["hooks"] as? [String: Any] else { return false }

        for (_, value) in hooks {
            guard let rules = value as? [[String: Any]] else { continue }
            for rule in rules {
                guard let hookSpecs = rule["hooks"] as? [[String: Any]] else { continue }
                for hook in hookSpecs where (hook["command"] as? String)?.contains(hookMarker) == true {
                    return true
                }
            }
        }
        return false
    }

    static func install() throws {
        let fileManager = FileManager.default

        try fileManager.createDirectory(atPath: ipcDir, withIntermediateDirectories: true)
        try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: ipcDir)

        var settings = try loadSettingsIfParsable(fileManager: fileManager)

        var hooks = settings["hooks"] as? [String: Any] ?? [:]

        let asyncConfigs: [(String, Int, String?)] = [
            ("UserPromptSubmit", 5, nil),
            ("PreToolUse", 5, "vibe-beeper monitoring\u{2026}"),
            ("PostToolUse", 5, nil),
            ("Stop", 5, nil),
            ("StopFailure", 5, nil),
        ]
        let blockingConfigs: [(String, Int, String?)] = [
            ("Notification", 60, nil),
            ("PermissionRequest", 60, nil),
        ]
        let removedEvents = ["SessionStart", "SessionEnd", "PostToolUseFailure"]

        for event in removedEvents {
            guard var existing = hooks[event] as? [[String: Any]] else { continue }
            existing = filterNonClaudeRules(existing)
            if existing.isEmpty {
                hooks.removeValue(forKey: event)
            } else {
                hooks[event] = existing
            }
        }

        for (event, timeout, statusMessage) in asyncConfigs {
            var existing = hooks[event] as? [[String: Any]] ?? []
            existing = filterNonClaudeRules(existing)

            var hookEntry: [String: Any] = [
                "type": "command",
                "command": asyncCommand,
                "async": true,
                "timeout": timeout,
            ]
            if let message = statusMessage {
                hookEntry["statusMessage"] = message
            }

            existing.append(["matcher": "", "hooks": [hookEntry]])
            hooks[event] = existing
        }

        for (event, timeout, statusMessage) in blockingConfigs {
            var existing = hooks[event] as? [[String: Any]] ?? []
            existing = filterNonClaudeRules(existing)

            var hookEntry: [String: Any] = [
                "type": "command",
                "command": blockingCommand,
                "timeout": timeout,
            ]
            if let message = statusMessage {
                hookEntry["statusMessage"] = message
            }

            existing.append(["matcher": "", "hooks": [hookEntry]])
            hooks[event] = existing
        }

        settings["hooks"] = hooks
        try writeSettings(settings, to: settingsPath, fileManager: fileManager)

        try? fileManager.removeItem(atPath: hooksDir + "/cc-beeper-hook.py")
        try? fileManager.removeItem(atPath: hooksDir + "/cc-beeper-app-path")
        try? fileManager.removeItem(atPath: ipcDir + "/events.jsonl")
        try? fileManager.removeItem(atPath: ipcDir + "/pending.json")
        try? fileManager.removeItem(atPath: ipcDir + "/response.json")
        try? fileManager.removeItem(atPath: ipcDir + "/last_summary.txt")
        try? fileManager.removeItem(atPath: ipcDir + "/sessions.json")
        try? fileManager.removeItem(atPath: ipcDir + "/cc-beeper.pid")
    }

    static func uninstall() throws {
        let fileManager = FileManager.default
        guard let data = fileManager.contents(atPath: settingsPath),
              var settings = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              var hooks = settings["hooks"] as? [String: Any] else { return }

        for (event, value) in hooks {
            guard var rules = value as? [[String: Any]] else { continue }
            rules = filterNonClaudeRules(rules)
            if rules.isEmpty {
                hooks.removeValue(forKey: event)
            } else {
                hooks[event] = rules
            }
        }

        settings["hooks"] = hooks
        try writeSettings(settings, to: settingsPath, fileManager: fileManager)
    }

    private static func filterNonClaudeRules(_ rules: [[String: Any]]) -> [[String: Any]] {
        rules.filter { rule in
            guard let hookSpecs = rule["hooks"] as? [[String: Any]] else { return true }
            return !hookSpecs.contains { hook in
                let command = hook["command"] as? String ?? ""
                return command.contains("cc-beeper-hook.py") || command.contains(hookMarker)
            }
        }
    }

    private static func writeSettings(_ settings: [String: Any], to path: String, fileManager: FileManager) throws {
        let data = try JSONSerialization.data(withJSONObject: settings, options: [.prettyPrinted])
        let tmpPath = path + ".tmp"
        try data.write(to: URL(fileURLWithPath: tmpPath))
        if fileManager.fileExists(atPath: path) {
            _ = try fileManager.replaceItemAt(
                URL(fileURLWithPath: path),
                withItemAt: URL(fileURLWithPath: tmpPath)
            )
        } else {
            try fileManager.moveItem(atPath: tmpPath, toPath: path)
        }
    }

    enum InstallError: LocalizedError {
        case settingsWriteFailed
        case malformedSettings

        var errorDescription: String? {
            switch self {
            case .settingsWriteFailed:
                return "Failed to write settings.json."
            case .malformedSettings:
                return "Claude settings.json exists but is not valid JSON. Fix it before reinstalling hooks."
            }
        }
    }

    private static func loadSettingsIfParsable(fileManager: FileManager) throws -> [String: Any] {
        guard fileManager.fileExists(atPath: settingsPath) else { return [:] }
        guard let data = fileManager.contents(atPath: settingsPath),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw InstallError.malformedSettings
        }
        return parsed
    }
}
