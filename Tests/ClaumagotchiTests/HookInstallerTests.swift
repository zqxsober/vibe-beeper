import XCTest

/// Tests for HookInstaller — stub only.
/// Real tests are added in Plan 01 after HookInstaller.swift is created.
/// Tests will use a temp directory to verify hook script copying and
/// settings.json mutation without touching the real ~/.claude/ directory.
final class HookInstallerTests: XCTestCase {

    func testHookInstallerIsInstalledStub() throws {
        // Placeholder — replaced in Plan 01
        // Expected behavior: HookInstaller.isInstalled returns false when
        // settings.json contains no claumagotchi-hook.py entry.
        XCTAssertTrue(true, "Stub: replaced in Plan 01")
    }

    func testHookInstallerInstallStub() throws {
        // Placeholder — replaced in Plan 01
        // Expected behavior: HookInstaller.install() creates hook files
        // and writes all 8 event entries into settings.json.
        XCTAssertTrue(true, "Stub: replaced in Plan 01")
    }
}
