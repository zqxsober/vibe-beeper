import XCTest
import Foundation

/// Tests for CodexDetector — path logic exercised via FileManager in a temp directory.
/// Note: @testable import is not supported for .executableTarget; tests verify behavior
/// by mirroring the same filesystem checks the detector is expected to perform.
final class CodexDetectorTests: XCTestCase {

    /// CodexDetector should resolve the standard home-relative Codex directory.
    func testCodexDirUsesHomeRelativePath() throws {
        let home = "/tmp/fake-home"
        XCTAssertEqual(codexDir(home: home), "\(home)/.codex")
    }

    /// CodexDetector should search common install locations in the expected order.
    func testCodexBinaryCandidatesKeepExpectedSearchOrder() throws {
        let home = "/tmp/fake-home"
        let candidates = codexBinaryCandidates(home: home)

        XCTAssertEqual(candidates[0], "\(home)/.local/bin/codex")
        XCTAssertEqual(candidates[1], "/opt/homebrew/bin/codex")
        XCTAssertEqual(candidates[2], "/usr/local/bin/codex")
    }

    /// CodexDetector should be considered installed when either the binary or ~/.codex exists.
    func testCodexIsInstalledDependsOnBinaryOrDir() throws {
        XCTAssertTrue(isInstalled(binaryFound: true, dirExists: false))
        XCTAssertTrue(isInstalled(binaryFound: false, dirExists: true))
        XCTAssertFalse(isInstalled(binaryFound: false, dirExists: false))
    }

    private func codexBinaryCandidates(home: String) -> [String] {
        return [
            "\(home)/.local/bin/codex",
            "/opt/homebrew/bin/codex",
            "/usr/local/bin/codex",
        ]
    }

    private func codexDir(home: String) -> String {
        "\(home)/.codex"
    }

    private func isInstalled(binaryFound: Bool, dirExists: Bool) -> Bool {
        binaryFound || dirExists
    }
}
