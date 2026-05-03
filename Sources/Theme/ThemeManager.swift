import SwiftUI
import AppKit

// MARK: - Theme Definition

struct ShellTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let displayName: String
    let shellImage: String
    let dotColor: String  // hex for swatch
}

enum OldSchoolDisplaySize: String, CaseIterable, Identifiable, Equatable {
    case small
    case medium
    case large
    case showcase

    var id: String { rawValue }

    var label: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .showcase: return "Showcase"
        }
    }

    var windowSize: NSSize {
        switch self {
        case .small: return NSSize(width: 360, height: 405)
        case .medium: return NSSize(width: 420, height: 472)
        case .large: return NSSize(width: 500, height: 562)
        case .showcase: return NSSize(width: 580, height: 652)
        }
    }
}

// MARK: - Theme Manager

final class ThemeManager: ObservableObject {
    static let themes: [ShellTheme] = [
        ShellTheme(id: "black",  name: "Black",  displayName: "Midnight", shellImage: "vibe-beeper-black.png",  dotColor: "212121"),
        ShellTheme(id: "blue",   name: "Blue",   displayName: "Ocean",    shellImage: "vibe-beeper-blue.png",   dotColor: "004FFA"),
        ShellTheme(id: "green",  name: "Green",  displayName: "Pine",     shellImage: "vibe-beeper-green.png",  dotColor: "209B43"),
        ShellTheme(id: "mint",   name: "Mint",   displayName: "Slate",    shellImage: "vibe-beeper-mint.png",   dotColor: "58D0C0"),
        ShellTheme(id: "orange", name: "Orange", displayName: "Ember",    shellImage: "vibe-beeper-orange.png", dotColor: "E86A1B"),
        ShellTheme(id: "pink",   name: "Pink",   displayName: "Rose",     shellImage: "vibe-beeper-pink.png",   dotColor: "FD6295"),
        ShellTheme(id: "purple", name: "Purple", displayName: "Violet",   shellImage: "vibe-beeper-purple.png", dotColor: "6C22FF"),
        ShellTheme(id: "red",    name: "Red",    displayName: "Crimson",  shellImage: "vibe-beeper-red.png",    dotColor: "FF2222"),
        ShellTheme(id: "white",  name: "White",  displayName: "Ghost",    shellImage: "vibe-beeper-white.png",  dotColor: "FFFFFF"),
        ShellTheme(id: "yellow", name: "Yellow", displayName: "Gold",     shellImage: "vibe-beeper-yellow.png", dotColor: "EDA623"),
        ShellTheme(id: "apple",  name: "Apple",  displayName: "Apple",    shellImage: "vibe-beeper-apple.png",  dotColor: "ECE7D5"),
        ShellTheme(id: "old-school", name: "Old School", displayName: "Old School", shellImage: "vibe-beeper-apple.png", dotColor: "ECE7D5"),
    ]

    @Published var currentThemeId: String {
        didSet { UserDefaults.standard.set(currentThemeId, forKey: "themeId") }
    }
    @Published var oldSchoolDisplaySize: OldSchoolDisplaySize {
        didSet { UserDefaults.standard.set(oldSchoolDisplaySize.rawValue, forKey: "oldSchoolDisplaySize") }
    }
    let darkMode: Bool = false

    var theme: ShellTheme {
        Self.themes.first { $0.id == currentThemeId } ?? Self.themes[0]
    }

    init() {
        currentThemeId = UserDefaults.standard.string(forKey: "themeId") ?? "black"
        oldSchoolDisplaySize = OldSchoolDisplaySize(rawValue: UserDefaults.standard.string(forKey: "oldSchoolDisplaySize") ?? "") ?? .medium
    }

    /// Re-read the active theme from UserDefaults and assign it so observers
    /// update. Called after onboarding finishes, since onboarding writes to
    /// UserDefaults directly instead of through this singleton.
    func reloadFromDefaults() {
        if let stored = UserDefaults.standard.string(forKey: "themeId"), stored != currentThemeId {
            currentThemeId = stored
        }

        let storedOldSchoolDisplaySize = OldSchoolDisplaySize(rawValue: UserDefaults.standard.string(forKey: "oldSchoolDisplaySize") ?? "") ?? .medium
        if storedOldSchoolDisplaySize != oldSchoolDisplaySize {
            oldSchoolDisplaySize = storedOldSchoolDisplaySize
        }
    }

    var shellImageName: String { theme.shellImage }
    var smallShellImageName: String {
        isOldSchoolTheme ? "vibe-beeper-small-apple.png" : "vibe-beeper-small-\(currentThemeId).png"
    }
    var isAppleTheme: Bool { currentThemeId == "apple" }
    var isOldSchoolTheme: Bool { currentThemeId == "old-school" }

    func mainWindowSize(for widgetSize: WidgetSize) -> NSSize {
        switch widgetSize {
        case .large:
            return isOldSchoolTheme ? oldSchoolDisplaySize.windowSize : NSSize(width: 440, height: 240)
        case .compact:
            return isOldSchoolTheme ? NSSize(width: 310, height: 349) : NSSize(width: 300, height: 193)
        case .menuOnly:
            return NSSize(width: 1, height: 1)
        }
    }

    // MARK: - LCD Colors (dark mode support)

    var lcdBg: Color { Color(hex: "98D65A") }
    var lcdOn: Color { (isAppleTheme || isOldSchoolTheme) ? Color(hex: "2F3A29") : Color(hex: "2A4A10") }
}
