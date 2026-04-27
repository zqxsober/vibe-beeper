import XCTest
import Foundation

final class PermissionWindowShakeXCTests: XCTestCase {
    func testPermissionWindowShakeServiceContinuouslyRunsUntilStopped() throws {
        let source = try String(contentsOfFile: permissionShakeServicePath(), encoding: .utf8)
        XCTAssertTrue(source.contains("final class PermissionWindowShakeService"))
        XCTAssertTrue(source.contains("Timer.scheduledTimer"))
        XCTAssertTrue(source.contains("withTimeInterval: 0.06"))
        XCTAssertTrue(source.contains("func update(isPermissionPending: Bool)"))
        XCTAssertTrue(source.contains("func stop()"))
    }

    func testMainAppStartsAndStopsPermissionShakeFromPermissionState() throws {
        let source = try String(contentsOfFile: appPath(), encoding: .utf8)
        XCTAssertTrue(source.contains("@StateObject private var permissionWindowShakeService = PermissionWindowShakeService()"))
        XCTAssertTrue(source.contains(".onChange(of: monitor.state)"))
        XCTAssertTrue(source.contains(".onChange(of: monitor.pendingPermission)"))
        XCTAssertTrue(source.contains("permissionWindowShakeService.update(isPermissionPending: monitor.state == .approveQuestion && monitor.pendingPermission != nil)"))
    }

    private func projectRoot() -> String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .path
    }

    private func permissionShakeServicePath() -> String {
        projectRoot() + "/Sources/App/PermissionWindowShakeService.swift"
    }

    private func appPath() -> String {
        projectRoot() + "/Sources/App/CCBeeperApp.swift"
    }
}
