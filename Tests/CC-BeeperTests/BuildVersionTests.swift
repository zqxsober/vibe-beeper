import XCTest
import Foundation

final class BuildVersionTests: XCTestCase {
    func testBuildScriptUsesLatestGitHubReleaseVersion() throws {
        let source = try String(contentsOfFile: buildScriptPath(), encoding: .utf8)

        XCTAssertTrue(source.contains("<key>CFBundleShortVersionString</key>"))
        XCTAssertTrue(source.contains("<string>1.0.4</string>"))
    }

    private func projectRoot() -> String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .path
    }

    private func buildScriptPath() -> String {
        projectRoot() + "/build.sh"
    }
}
