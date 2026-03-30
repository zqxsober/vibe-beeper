import Foundation

// MARK: - PermissionPreset

/// The 4 permission presets available in CC-Beeper.
/// Each preset maps to a combination of `permission_mode` and `allowedTools`
/// in ~/.claude/settings.json (per D-01).
enum PermissionPreset: String, CaseIterable, Equatable {
    case cautious   // permission_mode: "default", no allowedTools
    case relaxed    // permission_mode: "default", allowedTools: ["Read", "Glob", "Grep"]
    case trusted    // permission_mode: "default", allowedTools: ["Read", "Glob", "Grep", "Write", "Edit", "NotebookEdit"]
    case yolo       // permission_mode: "bypass"

    /// The value to write to the `permission_mode` field in settings.json.
    var permissionModeValue: String {
        switch self {
        case .cautious, .relaxed, .trusted: return "default"
        case .yolo: return "bypass"
        }
    }

    /// The tools to write to `allowedTools`, or nil to remove the key.
    var allowedTools: [String]? {
        switch self {
        case .cautious: return nil  // remove allowedTools key
        case .relaxed: return ["Read", "Glob", "Grep"]
        case .trusted: return ["Read", "Glob", "Grep", "Write", "Edit", "NotebookEdit"]
        case .yolo: return nil  // YOLO bypasses everything, no allowedTools needed
        }
    }

    /// Human-readable label for the menu and UI.
    var label: String {
        switch self {
        case .cautious: return "Cautious"
        case .relaxed: return "Relaxed"
        case .trusted: return "Trusted"
        case .yolo: return "YOLO"
        }
    }

    /// Short description shown alongside the label in the menu.
    var menuDescription: String {
        switch self {
        case .cautious: return "ask before every action"
        case .relaxed: return "auto reads, ask for writes"
        case .trusted: return "auto file ops, ask for bash"
        case .yolo: return "auto-approve everything"
        }
    }
}

// MARK: - PermissionPresetWriter

/// Reads and writes permission presets to ~/.claude/settings.json atomically.
///
/// Write strategy: read existing JSON, modify only `permission_mode` and `allowedTools`,
/// write to a .tmp file, then atomically rename — preserving all other fields intact.
struct PermissionPresetWriter {

    static let settingsPath = NSHomeDirectory() + "/.claude/settings.json"

    // MARK: Read

    /// Reads settings.json and infers the current preset.
    ///
    /// Matching rules (checked in order):
    /// - `permission_mode == "bypass"` → `.yolo`
    /// - `allowedTools` contains "Write" → `.trusted`
    /// - `allowedTools` contains "Read" but NOT "Write" → `.relaxed`
    /// - Otherwise → `.cautious`
    static func readCurrentPreset() -> PermissionPreset {
        let fm = FileManager.default
        guard fm.fileExists(atPath: settingsPath),
              let data = fm.contents(atPath: settingsPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .cautious
        }

        if let mode = json["permission_mode"] as? String, mode == "bypass" {
            return .yolo
        }

        let allowedTools = json["allowedTools"] as? [String] ?? []
        if allowedTools.contains("Write") {
            return .trusted
        }
        if allowedTools.contains("Read") {
            return .relaxed
        }
        return .cautious
    }

    // MARK: Malformed Detection

    /// Returns true if settings.json exists but cannot be parsed as valid JSON.
    static func isSettingsMalformed() -> Bool {
        let fm = FileManager.default
        guard fm.fileExists(atPath: settingsPath),
              let data = fm.contents(atPath: settingsPath) else {
            return false  // Missing file is not malformed — it will be created on write
        }
        return (try? JSONSerialization.jsonObject(with: data)) == nil
    }

    // MARK: Write

    /// Applies a preset to settings.json.
    ///
    /// Reads the current settings, modifies only `permission_mode` and `allowedTools`,
    /// and writes back atomically via tmp + rename. All other fields are preserved.
    ///
    /// If settings.json does not exist, creates it with only the preset fields.
    ///
    /// - Parameter preset: The preset to apply.
    /// - Throws: If the file cannot be written.
    static func applyPreset(_ preset: PermissionPreset) throws {
        let fm = FileManager.default

        // Read existing settings or start fresh
        var settings: [String: Any] = [:]
        if fm.fileExists(atPath: settingsPath),
           let data = fm.contents(atPath: settingsPath),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            settings = parsed
        }

        // Modify only permission_mode and allowedTools
        settings["permission_mode"] = preset.permissionModeValue
        if let tools = preset.allowedTools {
            settings["allowedTools"] = tools
        } else {
            settings.removeValue(forKey: "allowedTools")
        }

        // Serialize — note: .sortedKeys is INTENTIONALLY OMITTED to minimize reformatting
        let data = try JSONSerialization.data(
            withJSONObject: settings,
            options: [.prettyPrinted]
        )

        // Atomic write via tmp + rename
        let tmpPath = settingsPath + ".tmp"
        try data.write(to: URL(fileURLWithPath: tmpPath))
        if fm.fileExists(atPath: settingsPath) {
            _ = try fm.replaceItemAt(
                URL(fileURLWithPath: settingsPath),
                withItemAt: URL(fileURLWithPath: tmpPath)
            )
        } else {
            try fm.moveItem(atPath: tmpPath, toPath: settingsPath)
        }
    }
}
