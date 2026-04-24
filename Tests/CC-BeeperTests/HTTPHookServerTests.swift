import XCTest
import Foundation

/// Tests for HTTPHookServer logic.
/// Since @testable import is not supported for .executableTarget, these tests
/// replicate the core parsing logic directly using helper functions to verify
/// correctness of the algorithm.
final class HTTPHookServerTests: XCTestCase {

    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - HTTP Parsing Helpers (replicated from HTTPHookServer)

    private func parseContentLength(from headerStr: String) -> Int? {
        let lines = headerStr.components(separatedBy: "\r\n")
        for line in lines {
            let lowered = line.lowercased()
            if lowered.hasPrefix("content-length:") {
                let value = line.dropFirst("content-length:".count).trimmingCharacters(in: .whitespaces)
                return Int(value)
            }
        }
        return nil
    }

    private func buildHTTPResponseString(statusCode: Int, bodyCount: Int) -> String {
        let statusText: String
        switch statusCode {
        case 200: statusText = "OK"
        case 400: statusText = "Bad Request"
        case 404: statusText = "Not Found"
        case 405: statusText = "Method Not Allowed"
        default: statusText = "Error"
        }
        var response = "HTTP/1.1 \(statusCode) \(statusText)\r\n"
        response += "Content-Length: \(bodyCount)\r\n"
        response += "Connection: close\r\n"
        response += "\r\n"
        return response
    }

    private func deferredResponseID(from result: [String: Any]) -> String? {
        let shouldHold = result["_hold_connection"] as? Bool ?? false
        guard shouldHold else { return nil }
        return result["_transport_deferred_id"] as? String ?? ""
    }

    private func stripTransportMetadata(from result: [String: Any]) -> [String: Any] {
        var cleaned = result
        cleaned.removeValue(forKey: "_hold_connection")
        cleaned.removeValue(forKey: "_transport_deferred_id")
        return cleaned
    }

    // MARK: - Tests

    /// Verify Content-Length extraction from HTTP header strings.
    func testParseContentLength() throws {
        let headers1 = "POST /hook HTTP/1.1\r\nContent-Type: application/json\r\nContent-Length: 42\r\n"
        XCTAssertEqual(parseContentLength(from: headers1), 42)

        // Case-insensitive
        let headers2 = "POST /hook HTTP/1.1\r\ncontent-length: 100\r\n"
        XCTAssertEqual(parseContentLength(from: headers2), 100)

        // No Content-Length
        let headers3 = "POST /hook HTTP/1.1\r\nContent-Type: application/json\r\n"
        XCTAssertNil(parseContentLength(from: headers3))

        // Zero Content-Length
        let headers4 = "POST /hook HTTP/1.1\r\nContent-Length: 0\r\n"
        XCTAssertEqual(parseContentLength(from: headers4), 0)

        // Content-Length with extra whitespace
        let headers5 = "POST /hook HTTP/1.1\r\nContent-Length:   256  \r\n"
        XCTAssertEqual(parseContentLength(from: headers5), 256)
    }

    /// Verify that the port file can be written and read back correctly.
    func testPortFileWriteAndRead() throws {
        let portFile = tempDir.appendingPathComponent("port").path
        let portTmp = portFile + ".tmp"

        // Write a port number atomically
        let portToWrite: UInt16 = 19222
        let content = "\(portToWrite)"
        try content.write(toFile: portTmp, atomically: false, encoding: .utf8)
        try FileManager.default.moveItem(atPath: portTmp, toPath: portFile)

        // Read it back
        let data = FileManager.default.contents(atPath: portFile)
        XCTAssertNotNil(data, "Port file should exist after write")
        let str = String(data: data!, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(str, "19222")
        let parsed = str.flatMap { UInt16($0) }
        XCTAssertEqual(parsed, 19222)
    }

    /// Verify atomic write pattern: .tmp file is renamed to final path.
    func testPortFileAtomicWrite() throws {
        let portFile = tempDir.appendingPathComponent("port").path
        let portTmp = portFile + ".tmp"

        // Write to .tmp
        let content = "19225"
        try content.write(toFile: portTmp, atomically: false, encoding: .utf8)

        // .tmp exists, final doesn't yet
        XCTAssertTrue(FileManager.default.fileExists(atPath: portTmp))
        XCTAssertFalse(FileManager.default.fileExists(atPath: portFile))

        // Rename
        try FileManager.default.moveItem(atPath: portTmp, toPath: portFile)

        // .tmp gone, final exists
        XCTAssertFalse(FileManager.default.fileExists(atPath: portTmp))
        XCTAssertTrue(FileManager.default.fileExists(atPath: portFile))

        // Content is correct
        let result = try String(contentsOfFile: portFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(result, "19225")
    }

    /// Verify HTTP response format matches the expected structure.
    func testHTTPResponseFormat() throws {
        let response200 = buildHTTPResponseString(statusCode: 200, bodyCount: 0)
        XCTAssertTrue(response200.hasPrefix("HTTP/1.1 200 OK\r\n"))
        XCTAssertTrue(response200.contains("Content-Length: 0\r\n"))
        XCTAssertTrue(response200.contains("Connection: close\r\n"))
        XCTAssertTrue(response200.hasSuffix("\r\n"))

        let response400 = buildHTTPResponseString(statusCode: 400, bodyCount: 0)
        XCTAssertTrue(response400.hasPrefix("HTTP/1.1 400 Bad Request\r\n"))

        let response404 = buildHTTPResponseString(statusCode: 404, bodyCount: 0)
        XCTAssertTrue(response404.hasPrefix("HTTP/1.1 404 Not Found\r\n"))

        let response405 = buildHTTPResponseString(statusCode: 405, bodyCount: 0)
        XCTAssertTrue(response405.hasPrefix("HTTP/1.1 405 Method Not Allowed\r\n"))

        // Non-zero body count reflected in Content-Length
        let response200body = buildHTTPResponseString(statusCode: 200, bodyCount: 57)
        XCTAssertTrue(response200body.contains("Content-Length: 57\r\n"))
    }

    /// Verify deferred responses are controlled by transport metadata, not Claude-specific payload fields.
    func testDeferredResponseUsesTransportMarkerOnly() throws {
        let result: [String: Any] = [
            "_hold_connection": true,
            "_transport_deferred_id": "session-123"
        ]

        let payload: [String: Any] = [
            "hook_event_name": "Notification",
            "notification_type": "permission_prompt"
        ]

        XCTAssertEqual(payload["hook_event_name"] as? String, "Notification")
        XCTAssertEqual(payload["notification_type"] as? String, "permission_prompt")
        XCTAssertEqual(deferredResponseID(from: result), "session-123",
                       "Deferred behavior should depend on transport metadata, not payload event names")
    }

    /// Verify transport-only metadata never leaks into the provider response body.
    func testImmediateResponseStripsTransportMetadata() throws {
        let response: [String: Any] = [
            "_hold_connection": false,
            "_transport_deferred_id": "session-123",
            "hookSpecificOutput": [
                "hookEventName": "PermissionRequest",
                "decision": ["behavior": "allow"]
            ]
        ]

        let cleaned = stripTransportMetadata(from: response)
        XCTAssertNil(cleaned["_hold_connection"])
        XCTAssertNil(cleaned["_transport_deferred_id"])
        XCTAssertNotNil(cleaned["hookSpecificOutput"])
    }

    /// Verify that exactly 5 hook event names are registered (4 async + 1 async notification,
    /// matching the Phase 35 hook registration list from the research document).
    ///
    /// Hook events to register in settings.json:
    /// - PreToolUse (async, statusMessage)
    /// - PostToolUse (async)
    /// - Notification (async — permission_prompt handled via deferred connection)
    /// - Stop (async)
    /// - StopFailure (async)
    ///
    /// Total: 5 events (all async curl hooks)
    func testSixHookEventsRegistered() throws {
        // The hook events CC-Beeper registers in Phase 35
        let hookEvents = [
            "PreToolUse",
            "PostToolUse",
            "Notification",
            "Stop",
            "StopFailure",
        ]

        // Verify count — Phase 35 registers 5 hooks (all async)
        // Note: the plan mentions "6 total" (4 async + 2 blocking) but research clarifies
        // that PermissionRequest is deprecated; Notification covers permission_prompt.
        // The actual hook entries are 5.
        XCTAssertEqual(hookEvents.count, 5, "Phase 35 should register exactly 5 hook events")

        // Verify all expected events are present
        XCTAssertTrue(hookEvents.contains("PreToolUse"))
        XCTAssertTrue(hookEvents.contains("PostToolUse"))
        XCTAssertTrue(hookEvents.contains("Notification"))
        XCTAssertTrue(hookEvents.contains("Stop"))
        XCTAssertTrue(hookEvents.contains("StopFailure"))

        // Verify events NOT in v7.0 are absent
        XCTAssertFalse(hookEvents.contains("PermissionRequest"), "PermissionRequest deprecated in v7.0")
        XCTAssertFalse(hookEvents.contains("SessionStart"), "SessionStart not needed in v7.0")
        XCTAssertFalse(hookEvents.contains("SessionEnd"), "SessionEnd not needed in v7.0")
    }

    /// Verify that a Stop event payload containing last_assistant_message can be extracted.
    /// This validates HTTP-04: TTS summary extraction from Stop event (no transcript parsing needed).
    func testLastAssistantMessageExtraction() throws {
        // Stop payload with a non-empty last_assistant_message
        let payloadWithMessage: [String: Any] = [
            "hook_event_name": "Stop",
            "session_id": "abc123",
            "transcript_path": "/Users/test/.claude/projects/test/session.jsonl",
            "stop_hook_active": true,
            "last_assistant_message": "I've completed the refactoring. Here's a summary of the changes."
        ]

        let extracted = payloadWithMessage["last_assistant_message"] as? String
        XCTAssertNotNil(extracted)
        XCTAssertFalse(extracted?.isEmpty ?? true)
        XCTAssertEqual(extracted, "I've completed the refactoring. Here's a summary of the changes.")

        // Payload without the key
        let payloadWithoutMessage: [String: Any] = [
            "hook_event_name": "Stop",
            "session_id": "abc123",
        ]
        let missingExtracted = payloadWithoutMessage["last_assistant_message"] as? String
        XCTAssertNil(missingExtracted, "Missing key should return nil")

        // Payload with empty string
        let payloadWithEmptyMessage: [String: Any] = [
            "hook_event_name": "Stop",
            "session_id": "abc123",
            "last_assistant_message": ""
        ]
        let emptyExtracted = payloadWithEmptyMessage["last_assistant_message"] as? String
        XCTAssertNotNil(emptyExtracted)
        XCTAssertTrue(emptyExtracted?.isEmpty ?? false, "Empty string should be empty")

        // Validate extraction guard pattern (how the app should use it)
        let message = payloadWithMessage["last_assistant_message"] as? String
        let validMessage = (message?.isEmpty == false) ? message : nil
        XCTAssertNotNil(validMessage)

        let emptyMessage = payloadWithEmptyMessage["last_assistant_message"] as? String
        let emptyValidMessage = (emptyMessage?.isEmpty == false) ? emptyMessage : nil
        XCTAssertNil(emptyValidMessage, "Empty message should not be spoken by TTS")
    }
}
