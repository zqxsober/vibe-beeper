import XCTest
import Foundation

final class InAppUpdateIntegrationTests: XCTestCase {
    func testUpdateCheckerUsesGitHubLatestReleaseEndpoint() throws {
        let source = try String(contentsOfFile: updateCheckerPath(), encoding: .utf8)

        XCTAssertTrue(source.contains("https://api.github.com/repos/zqxsober/vibe-beeper/releases/latest"))
        XCTAssertTrue(source.contains("GitHubRelease.self"))
        XCTAssertTrue(source.contains("AppVersion.isRemoteVersion"))
    }

    func testAboutSectionExposesManualUpdateCheck() throws {
        let source = try String(contentsOfFile: aboutSectionPath(), encoding: .utf8)

        XCTAssertTrue(source.contains("@StateObject private var updateChecker = InAppUpdateChecker()"))
        XCTAssertTrue(source.contains("Check for Updates"))
        XCTAssertTrue(source.contains("Download Update"))
        XCTAssertTrue(source.contains("NSWorkspace.shared.open"))
    }

    private func projectRoot() -> String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .path
    }

    private func updateCheckerPath() -> String {
        projectRoot() + "/Sources/Updates/InAppUpdateChecker.swift"
    }

    private func aboutSectionPath() -> String {
        projectRoot() + "/Sources/Settings/SettingsAboutSection.swift"
    }
}

