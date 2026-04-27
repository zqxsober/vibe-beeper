import XCTest
import Foundation
@testable import UpdateCore

final class AppVersionTests: XCTestCase {
    func testRemoteVersionWithVPrefixCanBeNewerThanCurrentVersion() {
        XCTAssertTrue(AppVersion.isRemoteVersion("v1.2.0", newerThan: "1.1.9"))
    }

    func testMultiDigitPatchVersionComparesNumerically() {
        XCTAssertTrue(AppVersion.isRemoteVersion("1.0.10", newerThan: "1.0.2"))
    }

    func testSameVersionIsNotNewer() {
        XCTAssertFalse(AppVersion.isRemoteVersion("v1.0.0", newerThan: "1.0.0"))
    }

    func testMissingPatchComponentComparesAsZero() {
        XCTAssertFalse(AppVersion.isRemoteVersion("1.0", newerThan: "1.0.0"))
    }

    func testDecodesGitHubLatestReleasePayload() throws {
        let json = Data("""
        {
          "tag_name": "v1.2.3",
          "html_url": "https://github.com/zqxsober/vibe-beeper/releases/tag/v1.2.3"
        }
        """.utf8)

        let release = try JSONDecoder().decode(GitHubRelease.self, from: json)

        XCTAssertEqual(release.tagName, "v1.2.3")
        XCTAssertEqual(release.htmlURL.absoluteString, "https://github.com/zqxsober/vibe-beeper/releases/tag/v1.2.3")
    }
}

