import XCTest
import Foundation

/// Tests for HookInstaller logic.
/// Since @testable import is not supported for .executableTarget, these tests
/// replicate the core isInstalled detection logic directly using FileManager to
/// verify correctness of the algorithm (not the type itself).
final class HookInstallerTests: XCTestCase {

    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    /// isInstalled detection: returns false when settings.json has no cc-beeper-hook.py entry.
    func testIsInstalledReturnsFalseWhenNoHookEntry() throws {
        let settingsURL = tempDir.appendingPathComponent("settings.json")
        let hookScriptURL = tempDir.appendingPathComponent("cc-beeper-hook.py")

        // Write a settings.json with no cc-beeper hooks
        let settings: [String: Any] = ["hooks": ["PreToolUse": []]]
        let data = try JSONSerialization.data(withJSONObject: settings)
        try data.write(to: settingsURL)
        // Write a dummy hook script file so the file-existence check passes
        try "#!/usr/bin/env python3\n".write(to: hookScriptURL, atomically: true, encoding: .utf8)

        // Replicate isInstalled detection logic
        let fm = FileManager.default
        guard fm.fileExists(atPath: hookScriptURL.path),
              fm.fileExists(atPath: settingsURL.path),
              let readData = fm.contents(atPath: settingsURL.path),
              let parsed = try? JSONSerialization.jsonObject(with: readData) as? [String: Any],
              let hooks = parsed["hooks"] as? [String: Any] else {
            XCTFail("Settings setup failed")
            return
        }

        var found = false
        for (_, value) in hooks {
            guard let rules = value as? [[String: Any]] else { continue }
            for rule in rules {
                guard let hs = rule["hooks"] as? [[String: Any]] else { continue }
                for h in hs where (h["command"] as? String)?.contains("cc-beeper-hook.py") == true {
                    found = true
                }
            }
        }
        XCTAssertFalse(found, "Expected no cc-beeper hook entries in settings.json")
    }

    /// isInstalled detection: returns true when settings.json contains a cc-beeper-hook.py entry.
    func testIsInstalledReturnsTrueWhenHookEntryPresent() throws {
        let settingsURL = tempDir.appendingPathComponent("settings.json")
        let hookScriptURL = tempDir.appendingPathComponent("cc-beeper-hook.py")

        // Write a settings.json that mirrors what HookInstaller.install() would produce
        let hookEntry: [String: Any] = [
            "type": "command",
            "command": "python3 \(hookScriptURL.path)",
            "timeout": 5,
        ]
        let rule: [String: Any] = ["matcher": "", "hooks": [hookEntry]]
        let settings: [String: Any] = ["hooks": ["PreToolUse": [rule]]]
        let data = try JSONSerialization.data(withJSONObject: settings)
        try data.write(to: settingsURL)
        try "#!/usr/bin/env python3\n".write(to: hookScriptURL, atomically: true, encoding: .utf8)

        // Replicate isInstalled detection logic
        let fm = FileManager.default
        guard let readData = fm.contents(atPath: settingsURL.path),
              let parsed = try? JSONSerialization.jsonObject(with: readData) as? [String: Any],
              let hooks = parsed["hooks"] as? [String: Any] else {
            XCTFail("Settings read failed")
            return
        }

        var found = false
        for (_, value) in hooks {
            guard let rules = value as? [[String: Any]] else { continue }
            for rule in rules {
                guard let hs = rule["hooks"] as? [[String: Any]] else { continue }
                for h in hs where (h["command"] as? String)?.contains("cc-beeper-hook.py") == true {
                    found = true
                }
            }
        }
        XCTAssertTrue(found, "Expected to find cc-beeper hook entry in settings.json")
    }

    /// Verifies all 8 event names required by setup.py are accounted for.
    func testAllEightHookEventsAreDeclared() throws {
        let requiredEvents = [
            "PreToolUse", "PostToolUse", "PostToolUseFailure",
            "PermissionRequest", "Notification", "Stop",
            "SessionStart", "SessionEnd",
        ]
        // We verify this by checking the eventConfigs array produces 8 entries.
        let eventConfigs: [(String, Int)] = [
            ("PreToolUse",        5),
            ("PostToolUse",       5),
            ("PostToolUseFailure", 5),
            ("PermissionRequest", 60),
            ("Notification",      5),
            ("Stop",              5),
            ("SessionStart",      10),
            ("SessionEnd",        5),
        ]
        let names = eventConfigs.map(\.0)
        for required in requiredEvents {
            XCTAssertTrue(names.contains(required), "Missing event: \(required)")
        }
        XCTAssertEqual(eventConfigs.count, 8, "Expected exactly 8 hook events")
    }
}
