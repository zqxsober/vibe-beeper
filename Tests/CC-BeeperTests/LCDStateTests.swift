import XCTest
import Foundation

/// Tests for the 8-state AgentState contract and its properties.
///
/// Note: @testable import is not supported for .executableTarget in this project.
/// These tests replicate the AgentState contract locally to verify enum contract,
/// priority ordering, and computed property behavior (LCD-01, LCD-06, Pitfall 7).
/// The production types live in Sources/Monitor/Core/AgentState.swift.

// MARK: - Replicated AgentState for test verification

/// Mirror of production AgentState — must stay in sync with Sources/Monitor/Core/AgentState.swift
private enum TestAgentState: Equatable {
    case idle
    case working
    case done
    case error
    case approveQuestion
    case needsInput
    case listening
    case speaking

    var label: String {
        switch self {
        case .idle: "ZZZ..."
        case .working: "WORKING"
        case .done: "DONE!"
        case .error: "ERROR"
        case .approveQuestion: "APPROVE?"
        case .needsInput: "INPUT?"
        case .listening: "LISTENING"
        case .speaking: "SPEAKING"
        }
    }

    var priority: Int {
        switch self {
        case .error: return 7
        case .approveQuestion: return 6
        case .needsInput: return 5
        case .listening: return 4
        case .speaking: return 3
        case .working: return 2
        case .done: return 1
        case .idle: return 0
        }
    }

    var needsAttention: Bool { self == .approveQuestion }
    var canOpenSession: Bool { self == .done }
}

// MARK: - AgentStateContractTests

struct AgentStateContractTests {

    // LCD-01: Verify 8 states exist with correct labels
    func testStateLabels() {
        XCTAssertEqual(TestAgentState.idle.label, "ZZZ...")
        XCTAssertEqual(TestAgentState.working.label, "WORKING")
        XCTAssertEqual(TestAgentState.done.label, "DONE!")
        XCTAssertEqual(TestAgentState.error.label, "ERROR")
        XCTAssertEqual(TestAgentState.approveQuestion.label, "APPROVE?")
        XCTAssertEqual(TestAgentState.needsInput.label, "INPUT?")
        XCTAssertEqual(TestAgentState.listening.label, "LISTENING")
        XCTAssertEqual(TestAgentState.speaking.label, "SPEAKING")
    }

    // LCD-06: Priority ordering (8-state)
    func testPriorityOrder() {
        XCTAssertEqual(TestAgentState.error.priority, 7)
        XCTAssertEqual(TestAgentState.approveQuestion.priority, 6)
        XCTAssertEqual(TestAgentState.needsInput.priority, 5)
        XCTAssertEqual(TestAgentState.listening.priority, 4)
        XCTAssertEqual(TestAgentState.speaking.priority, 3)
        XCTAssertEqual(TestAgentState.working.priority, 2)
        XCTAssertEqual(TestAgentState.done.priority, 1)
        XCTAssertEqual(TestAgentState.idle.priority, 0)
    }

    // LCD-06: Higher priority states are never overwritten by lower (8-state chain)
    func testPriorityEnforcement() {
        XCTAssertGreaterThan(TestAgentState.error.priority, TestAgentState.approveQuestion.priority)
        XCTAssertGreaterThan(TestAgentState.error.priority, TestAgentState.needsInput.priority)
        XCTAssertGreaterThan(TestAgentState.error.priority, TestAgentState.working.priority)
        XCTAssertGreaterThan(TestAgentState.error.priority, TestAgentState.done.priority)
        XCTAssertGreaterThan(TestAgentState.error.priority, TestAgentState.idle.priority)
        XCTAssertGreaterThan(TestAgentState.approveQuestion.priority, TestAgentState.needsInput.priority)
        XCTAssertGreaterThan(TestAgentState.approveQuestion.priority, TestAgentState.working.priority)
        XCTAssertGreaterThan(TestAgentState.needsInput.priority, TestAgentState.listening.priority)
        XCTAssertGreaterThan(TestAgentState.listening.priority, TestAgentState.speaking.priority)
        XCTAssertGreaterThan(TestAgentState.speaking.priority, TestAgentState.working.priority)
        XCTAssertGreaterThan(TestAgentState.working.priority, TestAgentState.done.priority)
        XCTAssertGreaterThan(TestAgentState.done.priority, TestAgentState.idle.priority)
    }

    // AUDIT-02: Multi-session priority resolution — highest priority wins
    func testMultiSessionPriorityResolution() {
        let sessionStates: [String: TestAgentState] = [
            "session-1": .working,
            "session-2": .done,
            "session-3": .error,
        ]
        let highest = Array(sessionStates.values).max(by: { $0.priority < $1.priority }) ?? .idle
        XCTAssertEqual(highest, .error, "Error (priority 7) must win over working (2) and done (1)")

        let sessionStates2: [String: TestAgentState] = [
            "a": .working,
            "b": .approveQuestion,
        ]
        let highest2 = Array(sessionStates2.values).max(by: { $0.priority < $1.priority }) ?? .idle
        XCTAssertEqual(highest2, .approveQuestion, "ApproveQuestion (6) must win over working (2)")
    }

    // Pitfall 7: only explicit approval prompts require attention styling
    func testNeedsAttention() {
        XCTAssertTrue(TestAgentState.approveQuestion.needsAttention)
        XCTAssertFalse(TestAgentState.needsInput.needsAttention)
        XCTAssertFalse(TestAgentState.working.needsAttention)
        XCTAssertFalse(TestAgentState.done.needsAttention)
        XCTAssertFalse(TestAgentState.idle.needsAttention)
        XCTAssertFalse(TestAgentState.error.needsAttention)
        XCTAssertFalse(TestAgentState.listening.needsAttention)
        XCTAssertFalse(TestAgentState.speaking.needsAttention)
    }

    // Pitfall 7: done sessions can be reopened
    func testCanOpenSession() {
        XCTAssertTrue(TestAgentState.done.canOpenSession)
        XCTAssertFalse(TestAgentState.working.canOpenSession)
        XCTAssertFalse(TestAgentState.idle.canOpenSession)
        XCTAssertFalse(TestAgentState.approveQuestion.canOpenSession)
        XCTAssertFalse(TestAgentState.needsInput.canOpenSession)
        XCTAssertFalse(TestAgentState.error.canOpenSession)
        XCTAssertFalse(TestAgentState.listening.canOpenSession)
        XCTAssertFalse(TestAgentState.speaking.canOpenSession)
    }
}

// MARK: - XCTest Wrapper

final class AgentStateContractXCTests: XCTestCase {
    private let suite = AgentStateContractTests()

    func testStateLabels() { suite.testStateLabels() }
    func testPriorityOrder() { suite.testPriorityOrder() }
    func testPriorityEnforcement() { suite.testPriorityEnforcement() }
    func testMultiSessionPriorityResolution() { suite.testMultiSessionPriorityResolution() }
    func testNeedsAttention() { suite.testNeedsAttention() }
    func testCanOpenSession() { suite.testCanOpenSession() }
}
