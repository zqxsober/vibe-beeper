import Foundation

struct ClaudePermissionPresetWriter {
    static let settingsPath = NSHomeDirectory() + "/.claude/settings.json"

    static func readCurrentPreset() -> PermissionPreset {
        if let raw = UserDefaults.standard.string(forKey: "ccBeeperPreset"),
           let preset = PermissionPreset(rawValue: raw) {
            return preset
        }

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: settingsPath),
              let data = fileManager.contents(atPath: settingsPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .cautious
        }

        let permissions = json["permissions"] as? [String: Any] ?? [:]
        if let mode = permissions["defaultMode"] as? String, mode == "bypassPermissions" {
            return .yolo
        }
        if let mode = json["permission_mode"] as? String, mode == "bypass" {
            return .yolo
        }
        return .cautious
    }

    static func migrateLegacyFields() {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: settingsPath),
              let data = fileManager.contents(atPath: settingsPath),
              let settings = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        let hasLegacy = settings["permission_mode"] != nil || settings["allowedTools"] != nil
        guard hasLegacy else { return }

        let preset = readCurrentPreset()
        try? applyPreset(preset)
    }

    static func isSettingsMalformed() -> Bool {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: settingsPath),
              let data = fileManager.contents(atPath: settingsPath) else {
            return false
        }
        return (try? JSONSerialization.jsonObject(with: data)) == nil
    }

    static func applyPreset(_ preset: PermissionPreset) throws {
        let fileManager = FileManager.default

        var settings = try loadSettingsIfParsable(fileManager: fileManager)

        var permissions = settings["permissions"] as? [String: Any] ?? [:]
        if let mode = preset.defaultModeValue {
            permissions["defaultMode"] = mode
        } else {
            permissions.removeValue(forKey: "defaultMode")
        }

        settings["permissions"] = permissions
        settings.removeValue(forKey: "permission_mode")
        settings.removeValue(forKey: "allowedTools")

        let data = try JSONSerialization.data(withJSONObject: settings, options: [.prettyPrinted])
        let tmpPath = settingsPath + ".tmp"
        try data.write(to: URL(fileURLWithPath: tmpPath))
        if fileManager.fileExists(atPath: settingsPath) {
            _ = try fileManager.replaceItemAt(
                URL(fileURLWithPath: settingsPath),
                withItemAt: URL(fileURLWithPath: tmpPath)
            )
        } else {
            try fileManager.moveItem(atPath: tmpPath, toPath: settingsPath)
        }

        UserDefaults.standard.set(preset.rawValue, forKey: "ccBeeperPreset")
    }

    private static func loadSettingsIfParsable(fileManager: FileManager) throws -> [String: Any] {
        guard fileManager.fileExists(atPath: settingsPath) else { return [:] }
        guard let data = fileManager.contents(atPath: settingsPath),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PresetWriteError.malformedSettings
        }
        return parsed
    }

    enum PresetWriteError: LocalizedError {
        case malformedSettings

        var errorDescription: String? {
            switch self {
            case .malformedSettings:
                return "Claude settings.json exists but is not valid JSON. Fix it before updating permission presets."
            }
        }
    }
}
