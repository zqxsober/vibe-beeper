import Foundation

// MARK: - WidgetSize

/// Controls widget visibility: full beeper, screen only, or menu bar only.
enum WidgetSize: String, CaseIterable, Equatable {
    case large       // Full beeper with buttons
    case compact     // Screen only, no buttons
    case menuOnly    // No widget, menu bar only

    var label: String {
        switch self {
        case .large: return "Large"
        case .compact: return "Compact"
        case .menuOnly: return "Menu only"
        }
    }

    var menuDescription: String {
        switch self {
        case .large: return "full beeper with buttons"
        case .compact: return "screen only, hotkeys to interact"
        case .menuOnly: return "menu bar icon only"
        }
    }
}

// MARK: - PermissionPreset

/// The 4 permission presets available in vibe-beeper.
/// YOLO sets `permissions.defaultMode: "bypassPermissions"` in settings.json.
/// Other presets auto-approve tools via PermissionRequest hook responses.
enum PermissionPreset: String, CaseIterable, Equatable {
    case cautious   // ask before every action
    case trusted    // auto file ops (Read/Glob/Grep/Write/Edit/NotebookEdit), ask for bash
    case relaxed    // auto reads (Read/Glob/Grep), ask for writes
    case yolo       // permissions.defaultMode: "bypassPermissions"

    /// The value to write to `permissions.defaultMode` in settings.json.
    /// Claude Code recognises: "default", "plan", "acceptEdits", "bypassPermissions".
    var defaultModeValue: String? {
        switch self {
        case .cautious, .relaxed, .trusted: return nil   // remove → Claude Code uses "default"
        case .yolo: return "bypassPermissions"
        }
    }

    /// Tools that vibe-beeper auto-approves via its PermissionRequest hook response.
    /// These are NOT written to settings.json — they're checked at hook time only.
    var allowedTools: [String]? {
        switch self {
        case .cautious: return nil
        case .relaxed: return ["Read", "Glob", "Grep"]
        case .trusted: return ["Read", "Glob", "Grep", "Write", "Edit", "NotebookEdit"]
        case .yolo: return nil  // YOLO bypasses everything via defaultMode
        }
    }

    /// Human-readable label for the menu and UI.
    var label: String {
        switch self {
        case .cautious: return "Strict"
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

    /// SF Symbol for the LCD badge.
    var badgeIcon: String {
        switch self {
        case .cautious: return "shield.fill"
        case .trusted: return "eye.fill"
        case .relaxed: return "hand.thumbsup.fill"
        case .yolo: return "flame.fill"
        }
    }

    /// Short text for the LCD badge.
    var badgeLabel: String {
        label.uppercased()
    }
}

typealias PermissionPresetWriter = ClaudePermissionPresetWriter
