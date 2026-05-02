import XCTest
import Foundation

final class BuzzServiceCancellationXCTests: XCTestCase {
    func testDelayedInitialVibrationsUseCancellablePendingWorkItems() throws {
        let source = try String(contentsOfFile: buzzServicePath(), encoding: .utf8)

        XCTAssertTrue(
            source.contains("private var pendingVibrationWorkItems: [UUID: DispatchWorkItem]"),
            "Delayed initial vibrations should be stored by UUID token so the closure does not need to capture its own DispatchWorkItem."
        )

        guard let scheduleBlock = functionBlock(named: "schedulePendingVibration(soundEnabled: Bool)", in: source) else {
            XCTFail("Expected schedulePendingVibration(soundEnabled:) to exist")
            return
        }

        XCTAssertTrue(
            scheduleBlock.contains("let token = UUID()"),
            "Each delayed vibration should get a UUID token before the work item is created."
        )
        XCTAssertTrue(
            scheduleBlock.contains("pendingVibrationWorkItems[token] = item"),
            "The cancellable DispatchWorkItem should be registered under its token before scheduling."
        )
        XCTAssertTrue(
            scheduleBlock.contains("pendingVibrationWorkItems[token] != nil"),
            "The delayed vibration block should check token presence instead of capturing the work item itself."
        )
        XCTAssertTrue(
            occurrences(of: "pendingVibrationWorkItems.removeValue(forKey: token)", in: scheduleBlock) >= 2,
            "The token should be removed around execution so fired work items do not remain pending."
        )
        XCTAssertTrue(
            scheduleBlock.contains("DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: item)"),
            "The 0.4s initial vibration delay should schedule the cancellable DispatchWorkItem, not a bare closure."
        )
        XCTAssertFalse(
            source.contains("DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {\n                self.vibrate"),
            "The previous bare asyncAfter closure could not be cancelled after OldSchoolLargeView disappears."
        )
        XCTAssertFalse(
            source.contains("var workItem: DispatchWorkItem?"),
            "The delayed vibration closure must not rely on an optional self-referential work item."
        )
        XCTAssertFalse(
            source.contains("let workItem, !workItem.isCancelled"),
            "The delayed vibration closure must not capture and inspect its own DispatchWorkItem."
        )
    }

    func testNonAttentionStatesAndCancelVibrationClearPendingWorkItems() throws {
        let source = try String(contentsOfFile: buzzServicePath(), encoding: .utf8)

        guard let handleStateChangeBlock = functionBlock(named: "handleStateChange(_ newState: ClaudeState, vibrationEnabled: Bool, soundEnabled: Bool)", in: source) else {
            XCTFail("Expected handleStateChange to exist")
            return
        }
        XCTAssertTrue(
            handleStateChangeBlock.contains("if !newState.needsAttention {\n            cancelPendingVibrations()\n        }"),
            "Leaving attention states should cancel delayed first vibrations that have not fired yet."
        )

        guard let cancelVibrationBlock = functionBlock(named: "cancelVibration()", in: source) else {
            XCTFail("Expected public cancelVibration() to exist")
            return
        }
        XCTAssertTrue(
            cancelVibrationBlock.contains("cancelPendingVibrations()"),
            "Public cancelVibration() should cancel delayed initial vibrations without changing reminderTimer semantics."
        )
        XCTAssertFalse(
            cancelVibrationBlock.contains("reminderTimer?.invalidate()"),
            "Public cancelVibration() should not directly invalidate reminderTimer; reminders keep their existing public semantics."
        )

        guard let cancelPendingBlock = functionBlock(named: "cancelPendingVibrations()", in: source) else {
            XCTFail("Expected cancelPendingVibrations() to exist")
            return
        }
        XCTAssertTrue(
            cancelPendingBlock.contains("for item in pendingVibrationWorkItems.values"),
            "Pending vibration cancellation should cancel dictionary values."
        )
        XCTAssertTrue(
            cancelPendingBlock.contains("item.cancel()"),
            "Each pending DispatchWorkItem should be cancelled before clearing the store."
        )
        XCTAssertTrue(
            cancelPendingBlock.contains("pendingVibrationWorkItems.removeAll()"),
            "Pending vibration cancellation should clear the token store."
        )
    }

    private func projectRoot() -> String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .path
    }

    private func buzzServicePath() -> String {
        projectRoot() + "/Sources/Voice/BuzzService.swift"
    }

    private func functionBlock(named name: String, in source: String) -> String? {
        guard let declarationRange = source.range(of: "func \(name)"),
              let openingBrace = source[declarationRange.upperBound...].firstIndex(of: "{") else {
            return nil
        }

        return block(startingAt: openingBrace, in: source)
    }

    private func block(startingAt openingBrace: String.Index, in source: String) -> String? {
        var depth = 0
        var index = openingBrace

        while index < source.endIndex {
            let character = source[index]

            if character == "{" {
                depth += 1
            } else if character == "}" {
                depth -= 1
                if depth == 0 {
                    return String(source[openingBrace...index])
                }
            }

            index = source.index(after: index)
        }

        return nil
    }

    private func occurrences(of needle: String, in haystack: String) -> Int {
        haystack.components(separatedBy: needle).count - 1
    }
}
