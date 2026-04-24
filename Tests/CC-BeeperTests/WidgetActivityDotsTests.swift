import XCTest
import Foundation

/// Regression tests for the LCD activity dots shown in working/waiting states.
/// These tests read the source directly because the widget target is executable-only.
final class WidgetActivityDotsXCTests: XCTestCase {
    func testScreenContentPlacesActivityDotsInlineWithTitle() throws {
        let source = try String(contentsOfFile: screenContentPath(), encoding: .utf8)
        XCTAssertTrue(source.contains("Text(titleText)"), "Screen content should render the status title as inline text so the activity dots can follow it directly")
        XCTAssertTrue(source.contains("ActivityDotsView(frame: animFrame)"), "Screen content should render activity dots using the shared animation frame")
        XCTAssertFalse(source.contains("MarqueeText(text: titleText"), "Status title should not use marquee once activity dots need to sit directly after the word")
    }

    func testOnlyWorkingAndWaitingStatesShowActivityDots() throws {
        let source = try String(contentsOfFile: screenContentPath(), encoding: .utf8)
        XCTAssertTrue(source.contains("case .working, .approveQuestion, .needsInput:"), "Activity dots should be limited to working and waiting states")
        XCTAssertTrue(source.contains("private var shouldShowActivityDots: Bool"), "Screen content should centralize the activity dots visibility rule")
    }

    func testActivityDotsAnimateThreeSteps() throws {
        let source = try String(contentsOfFile: screenContentPath(), encoding: .utf8)
        XCTAssertTrue(source.contains("ForEach(0..<3"), "Activity dots should render exactly three animated dots")
        XCTAssertTrue(source.contains("frame % 3"), "Activity dots should pulse from the existing shared animation frame")
        XCTAssertFalse(source.contains(".offset(y: frame % 3"), "Activity dots should blink in place instead of jumping vertically")
    }

    private func projectRoot() -> String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .path
    }

    private func screenContentPath() -> String {
        projectRoot() + "/Sources/Widget/ScreenContentView.swift"
    }
}
