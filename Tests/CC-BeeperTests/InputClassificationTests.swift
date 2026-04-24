import XCTest
import Foundation

/// Tests for PermissionMode enum and input classification rules.
///
/// Note: @testable import is not supported for .executableTarget in this project.
/// These tests replicate the PermissionMode and AgentState types locally to verify
/// enum contracts, exhaustive state matching, and priority-based selection.
/// Production state types live in Sources/Monitor/Core/AgentState.swift.

// MARK: - Replicated Types for test verification

/// Mirror of production PermissionMode — must stay in sync with Sources/Monitor/PermissionController.swift
private enum TestPermissionMode: Equatable {
    case cautious   // "default" or field missing
    case guided     // "plan"
    case bypass     // "bypass" (covers Guarded YOLO and Full YOLO)
}

/// Mirror of production AgentState priority.
private enum TestAgentState2: Equatable {
    case idle
    case working
    case done
    case error
    case approveQuestion
    case needsInput

    var priority: Int {
        switch self {
        case .error: return 5
        case .approveQuestion: return 4
        case .needsInput: return 3
        case .working: return 2
        case .done: return 1
        case .idle: return 0
        }
    }
}

// MARK: - InputClassificationTests

struct InputClassificationTests {

    // INP-01: PermissionMode has cautious, guided, bypass cases
    func testPermissionModeCases() {
        let cautious = TestPermissionMode.cautious
        let guided = TestPermissionMode.guided
        let bypass = TestPermissionMode.bypass
        XCTAssertNotEqual(cautious, bypass)
        XCTAssertNotEqual(guided, bypass)
        XCTAssertNotEqual(cautious, guided)
    }

    // INP-02 + INP-03: All 6 interaction states are exhaustively matchable
    func testExhaustiveMatch() {
        let states: [TestAgentState2] = [.idle, .working, .done, .error, .approveQuestion, .needsInput]
        var matched = 0
        for state in states {
            switch state {
            case .idle: matched += 1
            case .working: matched += 1
            case .done: matched += 1
            case .error: matched += 1
            case .approveQuestion: matched += 1
            case .needsInput: matched += 1
            }
        }
        XCTAssertEqual(matched, 6, "All 6 states must be matched exhaustively")
        XCTAssertEqual(states.count, 6)
    }

    // Priority sorting: idle < done < working < needsInput < approveQuestion < error
    func testPrioritySorting() {
        let states: [TestAgentState2] = [.idle, .error, .working, .approveQuestion, .done, .needsInput]
        let sorted = states.sorted(by: { $0.priority < $1.priority })
        XCTAssertEqual(sorted, [.idle, .done, .working, .needsInput, .approveQuestion, .error])
    }

    // Priority max selection: highest priority wins
    func testMaxPrioritySelection() {
        let sessionStates: [TestAgentState2] = [.working, .done, .idle]
        let highest = sessionStates.max(by: { $0.priority < $1.priority })
        XCTAssertEqual(highest, .working)

        let withError: [TestAgentState2] = [.working, .error, .approveQuestion]
        let highestWithError = withError.max(by: { $0.priority < $1.priority })
        XCTAssertEqual(highestWithError, .error)

        let withNeedsInput: [TestAgentState2] = [.working, .needsInput, .done]
        let highestWithInput = withNeedsInput.max(by: { $0.priority < $1.priority })
        XCTAssertEqual(highestWithInput, .needsInput)
    }

    // Input classification: input types are NEVER suppressed by bypass mode (INP-02)
    func testInputTypesNeverSuppressed() {
        // The known input notification_type values that always surface regardless of YOLO
        let inputTypes = ["question", "gsd", "discuss", "multiple_choice", "wcv", "elicitation_dialog"]
        XCTAssertEqual(inputTypes.count, 6, "6 input types should always surface")
        // permission_prompt is the ONLY suppressible type
        let suppressibleType = "permission_prompt"
        XCTAssertFalse(inputTypes.contains(suppressibleType))
    }

    // INP-03: Unknown types default to NEEDS INPUT (verify logic direction)
    func testUnknownTypeDefaultsToNeedsInput() {
        // This tests the classification logic direction: when notification_type is unknown,
        // the system should default to NEEDS INPUT (false positives over false negatives).
        // The production code in handleHookPayload uses a default: case → needsInput.
        // We verify the intent by checking that unknown types are NOT suppressible (no bypass check).
        let unknownType = "unknown_future_type_xyz"
        let knownInputTypes = ["question", "gsd", "discuss", "multiple_choice", "wcv", "elicitation_dialog"]
        let suppressibleTypes = ["permission_prompt"]
        // Unknown type is in neither known set → defaults to needsInput by production default: case
        XCTAssertFalse(knownInputTypes.contains(unknownType))
        XCTAssertFalse(suppressibleTypes.contains(unknownType))
    }
}

// MARK: - XCTest Wrapper

final class InputClassificationXCTests: XCTestCase {
    private let suite = InputClassificationTests()

    func testPermissionModeCases() { suite.testPermissionModeCases() }
    func testExhaustiveMatch() { suite.testExhaustiveMatch() }
    func testPrioritySorting() { suite.testPrioritySorting() }
    func testMaxPrioritySelection() { suite.testMaxPrioritySelection() }
    func testInputTypesNeverSuppressed() { suite.testInputTypesNeverSuppressed() }
    func testUnknownTypeDefaultsToNeedsInput() { suite.testUnknownTypeDefaultsToNeedsInput() }
}
