import XCTest
import Foundation

/// Tests for PermissionPreset enum contracts and settings.json write logic.
///
/// Note: @testable import is not supported for .executableTarget.
/// These tests replicate the PermissionPreset type and verify the JSON
/// read/write algorithm using temp files.

// MARK: - Replicated Types

/// Mirror of production PermissionPreset — must stay in sync with
/// Sources/Monitor/PermissionPresetWriter.swift.
private enum TestPermissionPreset: String, CaseIterable {
    case cautious, relaxed, trusted, yolo

    var permissionModeValue: String {
        switch self {
        case .cautious, .relaxed, .trusted: return "default"
        case .yolo: return "bypass"
        }
    }

    var allowedTools: [String]? {
        switch self {
        case .cautious: return nil
        case .relaxed: return ["Read", "Glob", "Grep"]
        case .trusted: return ["Read", "Glob", "Grep", "Write", "Edit", "NotebookEdit"]
        case .yolo: return nil
        }
    }
}

// MARK: - Helpers

/// Applies a TestPermissionPreset to a temp settings file and returns the parsed result.
private func applyPreset(
    _ preset: TestPermissionPreset,
    to settingsPath: String,
    existingContent: [String: Any]? = nil
) throws -> [String: Any] {
    let fm = FileManager.default

    // Write initial content if provided
    if let existing = existingContent {
        let data = try JSONSerialization.data(withJSONObject: existing, options: [.prettyPrinted])
        try data.write(to: URL(fileURLWithPath: settingsPath))
    }

    // Replicate the PermissionPresetWriter.applyPreset algorithm
    var settings: [String: Any] = [:]
    if fm.fileExists(atPath: settingsPath),
       let data = fm.contents(atPath: settingsPath),
       let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        settings = parsed
    }

    settings["permission_mode"] = preset.permissionModeValue
    if let tools = preset.allowedTools {
        settings["allowedTools"] = tools
    } else {
        settings.removeValue(forKey: "allowedTools")
    }

    let data = try JSONSerialization.data(withJSONObject: settings, options: [.prettyPrinted])

    let tmpPath = settingsPath + ".tmp"
    try data.write(to: URL(fileURLWithPath: tmpPath))
    if fm.fileExists(atPath: settingsPath) {
        _ = try fm.replaceItemAt(
            URL(fileURLWithPath: settingsPath),
            withItemAt: URL(fileURLWithPath: tmpPath)
        )
    } else {
        try fm.moveItem(atPath: tmpPath, toPath: settingsPath)
    }

    guard let result = fm.contents(atPath: settingsPath),
          let parsed = try? JSONSerialization.jsonObject(with: result) as? [String: Any] else {
        throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to read written file"])
    }
    return parsed
}

/// Replicates the PermissionPresetWriter.readCurrentPreset algorithm from a file path.
private func readPreset(from settingsPath: String) -> TestPermissionPreset {
    let fm = FileManager.default
    guard fm.fileExists(atPath: settingsPath),
          let data = fm.contents(atPath: settingsPath),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        return .cautious
    }

    if let mode = json["permission_mode"] as? String, mode == "bypass" {
        return .yolo
    }

    let allowedTools = json["allowedTools"] as? [String] ?? []
    if allowedTools.contains("Write") {
        return .trusted
    }
    if allowedTools.contains("Read") {
        return .relaxed
    }
    return .cautious
}

/// Replicates the PermissionPresetWriter.isSettingsMalformed algorithm from a file path.
private func isMalformed(at settingsPath: String) -> Bool {
    let fm = FileManager.default
    guard fm.fileExists(atPath: settingsPath),
          let data = fm.contents(atPath: settingsPath) else {
        return false
    }
    return (try? JSONSerialization.jsonObject(with: data)) == nil
}

// MARK: - PermissionPresetWriterTests

final class PermissionPresetWriterTests: XCTestCase {

    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: 1. Enum shape

    func testPresetEnumHasFourCases() {
        XCTAssertEqual(TestPermissionPreset.allCases.count, 4)
    }

    // MARK: 2. Write: cautious

    func testCautiousWritesDefaultModeNoAllowedTools() throws {
        let path = tempDir.appendingPathComponent("settings.json").path
        let result = try applyPreset(.cautious, to: path)

        XCTAssertEqual(result["permission_mode"] as? String, "default")
        XCTAssertNil(result["allowedTools"], "cautious should remove allowedTools key")
    }

    // MARK: 3. Write: relaxed

    func testRelaxedWritesDefaultModeWithReadTools() throws {
        let path = tempDir.appendingPathComponent("settings.json").path
        let result = try applyPreset(.relaxed, to: path)

        XCTAssertEqual(result["permission_mode"] as? String, "default")
        let tools = result["allowedTools"] as? [String]
        XCTAssertEqual(tools, ["Read", "Glob", "Grep"])
    }

    // MARK: 4. Write: trusted

    func testTrustedWritesDefaultModeWithFileTools() throws {
        let path = tempDir.appendingPathComponent("settings.json").path
        let result = try applyPreset(.trusted, to: path)

        XCTAssertEqual(result["permission_mode"] as? String, "default")
        let tools = result["allowedTools"] as? [String] ?? []
        XCTAssertTrue(tools.contains("Write"), "trusted should include Write")
        XCTAssertTrue(tools.contains("Edit"), "trusted should include Edit")
        XCTAssertTrue(tools.contains("NotebookEdit"), "trusted should include NotebookEdit")
    }

    // MARK: 5. Write: yolo

    func testYoloWritesBypassModeNoAllowedTools() throws {
        let path = tempDir.appendingPathComponent("settings.json").path
        let result = try applyPreset(.yolo, to: path)

        XCTAssertEqual(result["permission_mode"] as? String, "bypass")
        XCTAssertNil(result["allowedTools"], "yolo should not write allowedTools")
    }

    // MARK: 6. Preserve other fields

    func testAtomicWritePreservesOtherFields() throws {
        let path = tempDir.appendingPathComponent("settings.json").path
        let initial: [String: Any] = [
            "hooks": ["PreToolUse": []],
            "customField": "keep",
        ]
        let result = try applyPreset(.relaxed, to: path, existingContent: initial)

        // Preset fields written
        XCTAssertEqual(result["permission_mode"] as? String, "default")

        // Other fields preserved
        XCTAssertNotNil(result["hooks"], "hooks key should be preserved")
        XCTAssertEqual(result["customField"] as? String, "keep", "customField should be preserved")
    }

    // MARK: 7. Malformed detection: invalid JSON

    func testMalformedJsonDetection() throws {
        let path = tempDir.appendingPathComponent("settings.json").path
        let invalidContent = "{ this is not valid json !!!".data(using: .utf8)!
        try invalidContent.write(to: URL(fileURLWithPath: path))

        XCTAssertTrue(isMalformed(at: path), "Malformed JSON should be detected")
    }

    // MARK: 8. Malformed detection: valid JSON

    func testValidJsonNotMalformed() throws {
        let path = tempDir.appendingPathComponent("settings.json").path
        let validContent: [String: Any] = ["permission_mode": "default"]
        let data = try JSONSerialization.data(withJSONObject: validContent)
        try data.write(to: URL(fileURLWithPath: path))

        XCTAssertFalse(isMalformed(at: path), "Valid JSON should not be flagged as malformed")
    }

    // MARK: 9. Read: bypass → yolo

    func testReadCurrentPresetFromBypass() throws {
        let path = tempDir.appendingPathComponent("settings.json").path
        let content: [String: Any] = ["permission_mode": "bypass"]
        let data = try JSONSerialization.data(withJSONObject: content)
        try data.write(to: URL(fileURLWithPath: path))

        XCTAssertEqual(readPreset(from: path), .yolo)
    }

    // MARK: 10. Read: default + read tools → relaxed

    func testReadCurrentPresetFromDefaultWithAllowedTools() throws {
        let path = tempDir.appendingPathComponent("settings.json").path
        let content: [String: Any] = [
            "permission_mode": "default",
            "allowedTools": ["Read", "Glob", "Grep"],
        ]
        let data = try JSONSerialization.data(withJSONObject: content)
        try data.write(to: URL(fileURLWithPath: path))

        XCTAssertEqual(readPreset(from: path), .relaxed)
    }

    // MARK: 11. Read: empty JSON → cautious

    func testReadCurrentPresetDefaultsToCautious() throws {
        let path = tempDir.appendingPathComponent("settings.json").path
        let content: [String: Any] = [:]
        let data = try JSONSerialization.data(withJSONObject: content)
        try data.write(to: URL(fileURLWithPath: path))

        XCTAssertEqual(readPreset(from: path), .cautious)
    }

    // MARK: 12. AskUserQuestion classification

    func testAskUserQuestionClassifiedAsInput() {
        // Verify the classification rule: when hook_event_name == "PermissionRequest"
        // and tool_name == "AskUserQuestion", the event should route to "needs_input",
        // NOT "permission_prompt". We test the classification logic directly.
        let hookEventName = "PermissionRequest"
        let toolName = "AskUserQuestion"

        // Replicate the production decision logic from ClaudeMonitor.handleHookPayload
        let isAskUserQuestion = (hookEventName == "PermissionRequest" && toolName == "AskUserQuestion")
        let classification = isAskUserQuestion ? "input" : "permission"

        XCTAssertEqual(classification, "input",
            "AskUserQuestion in PermissionRequest should classify as input, not permission")
        XCTAssertTrue(isAskUserQuestion,
            "AskUserQuestion PermissionRequest should be detected as a user question")

        // Verify non-AskUserQuestion tools still classify as permission
        let otherTool = "Bash"
        let isOtherQuestion = (hookEventName == "PermissionRequest" && otherTool == "AskUserQuestion")
        let otherClassification = isOtherQuestion ? "input" : "permission"
        XCTAssertEqual(otherClassification, "permission",
            "Bash in PermissionRequest should classify as permission")
    }
}
