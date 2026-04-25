import XCTest
import Foundation

/// Regression tests for the widget shell branding baked into the shell PNGs.
/// Once the resource images carry the VIBE-BEEPER logo directly, the widget
/// must stop painting the old cleanup-mask overlay on top of the bezel.
final class WidgetBrandingXCTests: XCTestCase {
    func testLargeWidgetUsesShellImageWithoutBrandOverlay() throws {
        let source = try String(contentsOfFile: contentViewPath(), encoding: .utf8)
        XCTAssertFalse(source.contains("BrandBadgeView(compact: false)"), "Large widget should not paint the legacy logo cleanup overlay once branding is baked into the shell asset")
    }

    func testCompactWidgetUsesShellImageWithoutBrandOverlay() throws {
        let source = try String(contentsOfFile: compactViewPath(), encoding: .utf8)
        XCTAssertFalse(source.contains("BrandBadgeView(compact: true)"), "Compact widget should not paint the legacy logo cleanup overlay once branding is baked into the shell asset")
    }

    func testLargeWidgetDoesNotKeepLegacyBadgeOffsets() throws {
        let source = try String(contentsOfFile: contentViewPath(), encoding: .utf8)
        XCTAssertFalse(source.contains(".offset(x: 27, y: 17)"), "Large widget should remove the old badge offset together with the overlay")
    }

    func testCompactWidgetDoesNotKeepLegacyBadgeOffsets() throws {
        let source = try String(contentsOfFile: compactViewPath(), encoding: .utf8)
        XCTAssertFalse(source.contains(".offset(x: 18, y: 15)"), "Compact widget should remove the old badge offset together with the overlay")
    }

    func testBrandBadgeViewFileIsRemoved() {
        XCTAssertFalse(FileManager.default.fileExists(atPath: badgeViewPath()), "BrandBadgeView should be removed once the shell PNGs include the final branding")
    }

    func testShellAssetsProvideBakedInVibeBranding() throws {
        let themeSource = try String(contentsOfFile: themeManagerPath(), encoding: .utf8)
        XCTAssertTrue(themeSource.contains("vibe-beeper-black.png"), "Theme manager should point at the baked-in VIBE shell assets")
        XCTAssertTrue(themeSource.contains("vibe-beeper-small-\\(currentThemeId).png"), "Compact theme assets should also use the baked-in VIBE shell assets")
    }

    private func projectRoot() -> String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .path
    }

    private func contentViewPath() -> String {
        projectRoot() + "/Sources/Widget/ContentView.swift"
    }

    private func compactViewPath() -> String {
        projectRoot() + "/Sources/Widget/CompactView.swift"
    }

    private func badgeViewPath() -> String {
        projectRoot() + "/Sources/Widget/BrandBadgeView.swift"
    }

    private func themeManagerPath() -> String {
        projectRoot() + "/Sources/Theme/ThemeManager.swift"
    }
}
