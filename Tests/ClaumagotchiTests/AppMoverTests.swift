import XCTest

/// Tests for AppMover — stub only.
/// Real tests are added in Plan 01 after AppMover.swift is created.
/// AppMover is primarily UI (NSAlert) — tests will verify the path-check
/// logic (skip if already in /Applications, skip if in .build/, detect
/// AppTranslocation) without showing UI dialogs.
final class AppMoverTests: XCTestCase {

    func testAppMoverSkipsApplicationsPathStub() throws {
        // Placeholder — replaced in Plan 01
        // Expected behavior: moveToApplicationsIfNeeded() is a no-op when
        // Bundle.main.bundlePath starts with "/Applications/".
        XCTAssertTrue(true, "Stub: replaced in Plan 01")
    }

    func testAppMoverSkipsBuildPathStub() throws {
        // Placeholder — replaced in Plan 01
        // Expected behavior: moveToApplicationsIfNeeded() is a no-op when
        // Bundle.main.bundlePath contains ".build/".
        XCTAssertTrue(true, "Stub: replaced in Plan 01")
    }
}
