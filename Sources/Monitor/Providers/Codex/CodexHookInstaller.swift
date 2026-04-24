import Foundation

struct CodexHookInstaller {
    static let codexDir = NSHomeDirectory() + "/.codex"
    static let configPath = codexDir + "/config.toml"
    static let hooksPath = codexDir + "/hooks.json"
    static let hookMarker = "vibe-beeper/provider=codex"

    private static let asyncTimeout = 5
    private static let blockingTimeout = 60
    private static let payloadProviderValue = ProviderKind.codex.rawValue
    private static let staleCommandFragments = [
        hookMarker,
        "OpenIslandHooks",
        "vibe-island-bridge"
    ]

    private static let requiredHooks: [(event: String, timeout: Int, blocking: Bool)] = [
        ("UserPromptSubmit", asyncTimeout, false),
        ("PreToolUse", asyncTimeout, false),
        ("PostToolUse", asyncTimeout, false),
        ("Stop", asyncTimeout, false),
        ("PermissionRequest", blockingTimeout, true),
    ]

    private static let asyncCommand = """
/usr/bin/python3 -c 'import json,sys; payload=json.load(sys.stdin); payload["\(ProviderKind.payloadProviderKey)"]="\(payloadProviderValue)"; json.dump(payload, sys.stdout)' | (PORT=$(cat ~/.claude/cc-beeper/port 2>/dev/null || echo 19222); TOKEN=$(cat ~/.claude/cc-beeper/token 2>/dev/null); curl -s -o /dev/null -X POST http://127.0.0.1:${PORT}/hook -H 'Content-Type: application/json' -H "Authorization: Bearer ${TOKEN}" -d @- --max-time 3 || true) # \(hookMarker)
"""

    private static let blockingCommand = """
/usr/bin/python3 -c 'import json,sys; payload=json.load(sys.stdin); payload["\(ProviderKind.payloadProviderKey)"]="\(payloadProviderValue)"; json.dump(payload, sys.stdout)' | (PORT=$(cat ~/.claude/cc-beeper/port 2>/dev/null || echo 19222); TOKEN=$(cat ~/.claude/cc-beeper/token 2>/dev/null); curl -s -X POST http://127.0.0.1:${PORT}/hook -H 'Content-Type: application/json' -H "Authorization: Bearer ${TOKEN}" -d @- --max-time 55 || true) # \(hookMarker)
"""

    static func isInstalled(configContents: String, hooksContents: String) -> Bool {
        isFeatureEnabled(in: configContents) && hasRequiredHooks(in: hooksContents)
    }

    static func install() throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(atPath: codexDir, withIntermediateDirectories: true)

        let currentConfig = (try? String(contentsOfFile: configPath, encoding: .utf8)) ?? ""
        let updatedConfig = enablingCodexHooks(in: currentConfig)
        try updatedConfig.write(toFile: configPath, atomically: true, encoding: .utf8)
        try? fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: configPath)

        var hooks = try loadHooksJSON(fileManager: fileManager)
        var hookRules = hooks["hooks"] as? [String: Any] ?? [:]

        for (event, value) in hookRules {
            guard let rules = value as? [[String: Any]] else { continue }
            let filtered = filterManagedRules(rules)
            if filtered.isEmpty {
                hookRules.removeValue(forKey: event)
            } else {
                hookRules[event] = filtered
            }
        }

        for hook in requiredHooks {
            var rules = hookRules[hook.event] as? [[String: Any]] ?? []
            rules = filterManagedRules(rules)
            rules.append([
                "hooks": [[
                    "type": "command",
                    "command": hook.blocking ? blockingCommand : asyncCommand,
                    "timeout": hook.timeout,
                ]]
            ])
            hookRules[hook.event] = rules
        }

        hooks["hooks"] = hookRules
        try writeHooksJSON(hooks, fileManager: fileManager)
    }

    static func uninstall() throws {
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: configPath) {
            let currentConfig = (try? String(contentsOfFile: configPath, encoding: .utf8)) ?? ""
            let updatedConfig = disablingCodexHooks(in: currentConfig)
            try updatedConfig.write(toFile: configPath, atomically: true, encoding: .utf8)
            try? fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: configPath)
        }

        guard fileManager.fileExists(atPath: hooksPath) else { return }
        var hooks = try loadHooksJSON(fileManager: fileManager)
        var hookRules = hooks["hooks"] as? [String: Any] ?? [:]

        for (event, value) in hookRules {
            guard let rules = value as? [[String: Any]] else { continue }
            let filtered = rules.filter { rule in
                guard let specs = rule["hooks"] as? [[String: Any]] else { return true }
                return !specs.contains { spec in
                    let command = spec["command"] as? String ?? ""
                    return command.contains(hookMarker)
                }
            }
            if filtered.isEmpty {
                hookRules.removeValue(forKey: event)
            } else {
                hookRules[event] = filtered
            }
        }

        hooks["hooks"] = hookRules
        try writeHooksJSON(hooks, fileManager: fileManager)
    }

    private static func isFeatureEnabled(in configContents: String) -> Bool {
        var inFeatures = false

        for rawLine in configContents.components(separatedBy: .newlines) {
            let line = stripComment(from: rawLine).trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("[") && line.hasSuffix("]") {
                inFeatures = line == "[features]"
                continue
            }
            guard inFeatures, line.hasPrefix("codex_hooks") else { continue }
            guard let value = line.split(separator: "=", maxSplits: 1).last else { return false }
            return value.trimmingCharacters(in: .whitespacesAndNewlines) == "true"
        }

        return false
    }

    private static func hasRequiredHooks(in hooksContents: String) -> Bool {
        guard let data = hooksContents.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hookRules = json["hooks"] as? [String: Any] else {
            return false
        }

        for hook in requiredHooks {
            guard let rules = hookRules[hook.event] as? [[String: Any]],
                  rules.contains(where: ruleContainsManagedCommand) else {
                return false
            }
        }

        return true
    }

    private static func ruleContainsManagedCommand(_ rule: [String: Any]) -> Bool {
        guard let specs = rule["hooks"] as? [[String: Any]] else { return false }
        return specs.contains { spec in
            let command = spec["command"] as? String ?? ""
            return command.contains(hookMarker)
        }
    }

    private static func enablingCodexHooks(in configContents: String) -> String {
        var lines = configContents.components(separatedBy: .newlines)
        var inFeatures = false
        var featureHeaderIndex: Int?
        var featureInsertIndex: Int?

        for index in lines.indices {
            let line = stripComment(from: lines[index]).trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("[") && line.hasSuffix("]") {
                if inFeatures && featureInsertIndex == nil {
                    featureInsertIndex = index
                }
                inFeatures = line == "[features]"
                if inFeatures {
                    featureHeaderIndex = index
                    featureInsertIndex = nil
                }
                continue
            }

            guard inFeatures else { continue }
            if line.hasPrefix("codex_hooks"),
               let prefix = lines[index].split(separator: "=", maxSplits: 1).first {
                lines[index] = "\(prefix)= true"
                return lines.joined(separator: "\n")
            }
        }

        if let headerIndex = featureHeaderIndex {
            let insertIndex = featureInsertIndex ?? lines.count
            lines.insert("codex_hooks = true", at: insertIndex)
            if insertIndex == headerIndex + 1 || lines[headerIndex + 1].isEmpty {
                return lines.joined(separator: "\n")
            }
            return lines.joined(separator: "\n")
        }

        var result = configContents
        if !result.isEmpty && !result.hasSuffix("\n") {
            result += "\n"
        }
        result += "[features]\n"
        result += "codex_hooks = true\n"
        return result
    }

    private static func disablingCodexHooks(in configContents: String) -> String {
        var lines = configContents.components(separatedBy: .newlines)
        var inFeatures = false

        for index in lines.indices {
            let line = stripComment(from: lines[index]).trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("[") && line.hasSuffix("]") {
                inFeatures = line == "[features]"
                continue
            }

            guard inFeatures, line.hasPrefix("codex_hooks") else { continue }
            lines.remove(at: index)
            break
        }

        return lines.joined(separator: "\n")
    }

    private static func filterManagedRules(_ rules: [[String: Any]]) -> [[String: Any]] {
        rules.compactMap { rule in
            guard let specs = rule["hooks"] as? [[String: Any]] else { return rule }
            let remaining = specs.filter { spec in
                let command = spec["command"] as? String ?? ""
                return !staleCommandFragments.contains(where: { command.contains($0) })
            }
            guard !remaining.isEmpty else { return nil }
            if remaining.count == specs.count {
                return rule
            }
            var updatedRule = rule
            updatedRule["hooks"] = remaining
            return updatedRule
        }
    }

    private static func loadHooksJSON(fileManager: FileManager) throws -> [String: Any] {
        guard fileManager.fileExists(atPath: hooksPath) else { return [:] }
        guard let data = fileManager.contents(atPath: hooksPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw InstallError.malformedHooks
        }
        return json
    }

    private static func writeHooksJSON(_ hooks: [String: Any], fileManager: FileManager) throws {
        let data = try JSONSerialization.data(withJSONObject: hooks, options: [.prettyPrinted, .sortedKeys])
        let tmpPath = hooksPath + ".tmp"
        try data.write(to: URL(fileURLWithPath: tmpPath))
        if fileManager.fileExists(atPath: hooksPath) {
            _ = try fileManager.replaceItemAt(
                URL(fileURLWithPath: hooksPath),
                withItemAt: URL(fileURLWithPath: tmpPath)
            )
        } else {
            try fileManager.moveItem(atPath: tmpPath, toPath: hooksPath)
        }
        try? fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: hooksPath)
    }

    private static func stripComment(from line: String) -> String {
        guard let hashIndex = line.firstIndex(of: "#") else { return line }
        return String(line[..<hashIndex])
    }

    enum InstallError: LocalizedError {
        case malformedHooks

        var errorDescription: String? {
            switch self {
            case .malformedHooks:
                return "Codex hooks.json exists but is not valid JSON. Fix it before reinstalling hooks."
            }
        }
    }
}
