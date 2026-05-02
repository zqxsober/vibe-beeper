import XCTest
import Foundation

final class SettingsThemeLayoutXCTests: XCTestCase {
    func testThemeSelectorUsesAdaptiveGridInsteadOfSingleRow() throws {
        let source = try String(contentsOfFile: themeDotsRowPath(), encoding: .utf8)
        XCTAssertTrue(source.contains("LazyVGrid"))
        XCTAssertTrue(source.contains("GridItem(.adaptive"))
        XCTAssertFalse(source.contains("HStack(spacing: 8)"))
    }

    func testSettingsThemeSectionKeepsSwatchesOutsidePreviewRow() throws {
        let source = try String(contentsOfFile: settingsGeneralSectionPath(), encoding: .utf8)
        XCTAssertTrue(source.contains("VStack(alignment: .leading, spacing: 12)"))
        XCTAssertTrue(source.contains("HStack(spacing: 14)"))
        XCTAssertTrue(source.contains("ThemeDotsRow()"))
    }

    func testSettingsThemeSectionKeepsGlobalWidgetSizePicker() throws {
        let source = try String(contentsOfFile: settingsGeneralSectionPath(), encoding: .utf8)
        XCTAssertTrue(source.contains("@EnvironmentObject var monitor: ClaudeMonitor"))
        XCTAssertTrue(source.contains("Section(\"Widget Size\")"))
        XCTAssertTrue(source.contains("Picker(\"Widget Size\", selection: $monitor.widgetSize)"))
        XCTAssertTrue(source.contains("ForEach(WidgetSize.allCases"))
    }

    func testAppReopenAndSettingsSizeChangesRespectMenuOnly() throws {
        let source = try String(contentsOfFile: appPath(), encoding: .utf8)
        XCTAssertTrue(source.contains(".onChange(of: monitor.widgetSize)"))
        XCTAssertTrue(source.contains("applyWidgetSizeVisibility()"))
        XCTAssertTrue(source.contains("WidgetSize.menuOnly.rawValue"))
        XCTAssertTrue(source.contains("UserDefaults.standard.string(forKey: \"widgetSize\")"))
    }

    func testAppSettingsCommandUsesStandardCommandCommaShortcut() throws {
        let source = try String(contentsOfFile: appPath(), encoding: .utf8)
        XCTAssertTrue(source.contains("CommandGroup(replacing: .appSettings)"))
        XCTAssertTrue(source.contains(".keyboardShortcut(\",\", modifiers: .command)"))
        XCTAssertTrue(source.contains("showSettingsWindow()"))
    }

    private func projectRoot() -> String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .path
    }

    private func themeDotsRowPath() -> String {
        projectRoot() + "/Sources/Widget/ThemeDotsRow.swift"
    }

    private func settingsGeneralSectionPath() -> String {
        projectRoot() + "/Sources/Settings/SettingsGeneralSection.swift"
    }

    private func appPath() -> String {
        projectRoot() + "/Sources/App/CCBeeperApp.swift"
    }
}
