import XCTest

/// Tests for PermissionController auto-approve logic — all 4 presets (TEST-04).
/// Uses replicated preset logic (no @testable import).

private enum TestPreset: String, CaseIterable {
    case cautious
    case relaxed
    case trusted
    case yolo

    var isBypass: Bool { self == .yolo }

    var allowedTools: [String]? {
        switch self {
        case .cautious: return nil
        case .relaxed: return ["Read", "Glob", "Grep"]
        case .trusted: return ["Read", "Glob", "Grep", "Write", "Edit", "NotebookEdit"]
        case .yolo: return nil  // bypasses via defaultMode
        }
    }
}

/// Replicates the auto-approve decision from HookDispatcher/PermissionController.
private func shouldAutoApprove(preset: TestPreset, tool: String) -> Bool {
    if preset.isBypass { return true }
    if let allowed = preset.allowedTools, allowed.contains(tool) { return true }
    return false
}

final class PermissionControllerXCTests: XCTestCase {

    // MARK: - Cautious preset (ask everything)

    func testCautiousNeverAutoApproves() {
        for tool in ["Read", "Write", "Bash", "Edit", "Glob", "Grep"] {
            XCTAssertFalse(shouldAutoApprove(preset: .cautious, tool: tool),
                           "Cautious must ask for \(tool)")
        }
    }

    // MARK: - Relaxed preset (auto-approve reads)

    func testRelaxedAutoApprovesReads() {
        XCTAssertTrue(shouldAutoApprove(preset: .relaxed, tool: "Read"))
        XCTAssertTrue(shouldAutoApprove(preset: .relaxed, tool: "Glob"))
        XCTAssertTrue(shouldAutoApprove(preset: .relaxed, tool: "Grep"))
    }

    func testRelaxedAsksForWrites() {
        XCTAssertFalse(shouldAutoApprove(preset: .relaxed, tool: "Write"))
        XCTAssertFalse(shouldAutoApprove(preset: .relaxed, tool: "Edit"))
        XCTAssertFalse(shouldAutoApprove(preset: .relaxed, tool: "Bash"))
    }

    // MARK: - Trusted preset (auto-approve file ops)

    func testTrustedAutoApprovesFileOps() {
        for tool in ["Read", "Glob", "Grep", "Write", "Edit", "NotebookEdit"] {
            XCTAssertTrue(shouldAutoApprove(preset: .trusted, tool: tool),
                          "Trusted must auto-approve \(tool)")
        }
    }

    func testTrustedAsksForBash() {
        XCTAssertFalse(shouldAutoApprove(preset: .trusted, tool: "Bash"))
    }

    // MARK: - YOLO preset (bypass everything)

    func testYoloAutoApprovesEverything() {
        for tool in ["Read", "Write", "Bash", "Edit", "Glob", "Grep", "AnyTool"] {
            XCTAssertTrue(shouldAutoApprove(preset: .yolo, tool: tool),
                          "YOLO must auto-approve \(tool)")
        }
    }

    // MARK: - Cross-preset

    func testAllPresetsExist() {
        XCTAssertEqual(TestPreset.allCases.count, 4, "Must have exactly 4 presets")
    }

    func testBashRequiresApprovalExceptYolo() {
        for preset in TestPreset.allCases {
            if preset == .yolo {
                XCTAssertTrue(shouldAutoApprove(preset: preset, tool: "Bash"))
            } else {
                XCTAssertFalse(shouldAutoApprove(preset: preset, tool: "Bash"),
                               "\(preset.rawValue) must ask for Bash")
            }
        }
    }
}
