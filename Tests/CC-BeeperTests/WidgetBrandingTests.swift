import XCTest
import Foundation

/// Regression tests for the widget shell branding overlay.
/// The shell PNGs still contain the legacy CC-BEEPER stamp, so the live widget
/// must explicitly render the new brand badge on top in both large and compact modes.
final class WidgetBrandingXCTests: XCTestCase {
    func testLargeWidgetIncludesBrandBadgeOverlay() throws {
        let source = try String(contentsOfFile: contentViewPath(), encoding: .utf8)
        XCTAssertTrue(source.contains("BrandBadgeView(compact: false)"), "Large widget should overlay the new brand badge")
    }

    func testCompactWidgetIncludesBrandBadgeOverlay() throws {
        let source = try String(contentsOfFile: compactViewPath(), encoding: .utf8)
        XCTAssertTrue(source.contains("BrandBadgeView(compact: true)"), "Compact widget should overlay the new brand badge")
    }

    func testLargeWidgetAlignsBrandBadgeWithBlackBezel() throws {
        let source = try String(contentsOfFile: contentViewPath(), encoding: .utf8)
        XCTAssertTrue(source.contains(".offset(x: 27, y: 17)"), "Large widget should cover the baked-in logo and align the replacement mark with the LCD without touching the outer shell")
    }

    func testCompactWidgetAlignsBrandBadgeWithBlackBezel() throws {
        let source = try String(contentsOfFile: compactViewPath(), encoding: .utf8)
        XCTAssertTrue(source.contains(".offset(x: 18, y: 15)"), "Compact widget should cover the baked-in logo and align the replacement mark with the LCD without touching the outer shell")
    }

    func testBrandBadgeUsesVibeBeeperLabel() throws {
        let source = try String(contentsOfFile: badgeViewPath(), encoding: .utf8)
        XCTAssertTrue(source.contains("VIBE-BEEPER"), "Brand badge should render the renamed product label")
        XCTAssertFalse(source.contains("CC-BEEPER"), "Brand badge source must not keep the legacy product label")
    }

    func testBrandBadgeUsesTransparentOverlay() throws {
        let source = try String(contentsOfFile: badgeViewPath(), encoding: .utf8)
        XCTAssertTrue(source.contains(".fixedSize()"), "Transparent badge should size itself to the text content")
        XCTAssertTrue(source.contains("private var leadingInset"), "Brand badge should define a left inset so the new label aligns with the LCD edge")
        XCTAssertTrue(source.contains("private var iconWidth"), "Brand badge should define a fixed icon width so the new label can align precisely")
        XCTAssertTrue(source.contains("private var patchWidth"), "Brand badge should define an explicit text mask width to cover the baked-in legacy text")
        XCTAssertTrue(source.contains("private var patchHeight"), "Brand badge should define a short cleanup mask height so it does not drop into the LCD area")
        XCTAssertTrue(source.contains("Rectangle().fill(bezelColor)"), "Brand badge should only paint a bezel-colored text mask, not a free-floating dark block")
        XCTAssertTrue(source.contains("Image(systemName: \"bolt.fill\")"), "Fallback badge should draw its own bolt icon on top of the cleanup mask")
        XCTAssertTrue(source.contains(".padding(.leading, compact ? 3 : 4)"), "Brand badge should start the replacement mark from a stable left inset")
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
}
