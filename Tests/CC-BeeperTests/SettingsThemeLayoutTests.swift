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
}
