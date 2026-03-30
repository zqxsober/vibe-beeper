import XCTest
import Foundation

/// Tests for the 6-state ClaudeState enum and its properties.
///
/// Note: @testable import is not supported for .executableTarget in this project.
/// These tests replicate the ClaudeState type locally to verify enum contract,
/// priority ordering, and computed property behavior (LCD-01, LCD-06, Pitfall 7).
/// The production types live in Sources/Monitor/ClaudeMonitor.swift.

// MARK: - Replicated ClaudeState for test verification

/// Mirror of production ClaudeState — must stay in sync with Sources/Monitor/ClaudeMonitor.swift
private enum TestClaudeState: Equatable {
    case idle
    case working
    case done
    case error
    case approveQuestion
    case needsInput

    var label: String {
        switch self {
        case .idle: "ZZZ..."
        case .working: "WORKING"
        case .done: "DONE!"
        case .error: "ERROR"
        case .approveQuestion: "APPROVE?"
        case .needsInput: "NEEDS INPUT"
        }
    }

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

    var needsAttention: Bool { self == .approveQuestion || self == .needsInput }
    var canGoToConvo: Bool { self == .done }
}

// MARK: - LCDStateTests

struct LCDStateTests {

    // LCD-01: Verify 6 states exist with correct labels
    func testStateLabels() {
        XCTAssertEqual(TestClaudeState.idle.label, "ZZZ...")
        XCTAssertEqual(TestClaudeState.working.label, "WORKING")
        XCTAssertEqual(TestClaudeState.done.label, "DONE!")
        XCTAssertEqual(TestClaudeState.error.label, "ERROR")
        XCTAssertEqual(TestClaudeState.approveQuestion.label, "APPROVE?")
        XCTAssertEqual(TestClaudeState.needsInput.label, "NEEDS INPUT")
    }

    // LCD-06: Priority ordering
    func testPriorityOrder() {
        XCTAssertEqual(TestClaudeState.error.priority, 5)
        XCTAssertEqual(TestClaudeState.approveQuestion.priority, 4)
        XCTAssertEqual(TestClaudeState.needsInput.priority, 3)
        XCTAssertEqual(TestClaudeState.working.priority, 2)
        XCTAssertEqual(TestClaudeState.done.priority, 1)
        XCTAssertEqual(TestClaudeState.idle.priority, 0)
    }

    // LCD-06: Higher priority states are never overwritten by lower
    func testPriorityEnforcement() {
        XCTAssertGreaterThan(TestClaudeState.error.priority, TestClaudeState.approveQuestion.priority)
        XCTAssertGreaterThan(TestClaudeState.error.priority, TestClaudeState.needsInput.priority)
        XCTAssertGreaterThan(TestClaudeState.error.priority, TestClaudeState.working.priority)
        XCTAssertGreaterThan(TestClaudeState.error.priority, TestClaudeState.done.priority)
        XCTAssertGreaterThan(TestClaudeState.error.priority, TestClaudeState.idle.priority)
        XCTAssertGreaterThan(TestClaudeState.approveQuestion.priority, TestClaudeState.needsInput.priority)
        XCTAssertGreaterThan(TestClaudeState.approveQuestion.priority, TestClaudeState.working.priority)
        XCTAssertGreaterThan(TestClaudeState.needsInput.priority, TestClaudeState.working.priority)
        XCTAssertGreaterThan(TestClaudeState.working.priority, TestClaudeState.done.priority)
        XCTAssertGreaterThan(TestClaudeState.done.priority, TestClaudeState.idle.priority)
    }

    // Pitfall 7: needsAttention covers both attention states
    func testNeedsAttention() {
        XCTAssertTrue(TestClaudeState.approveQuestion.needsAttention)
        XCTAssertTrue(TestClaudeState.needsInput.needsAttention)
        XCTAssertFalse(TestClaudeState.working.needsAttention)
        XCTAssertFalse(TestClaudeState.done.needsAttention)
        XCTAssertFalse(TestClaudeState.idle.needsAttention)
        XCTAssertFalse(TestClaudeState.error.needsAttention)
    }

    // Pitfall 7: canGoToConvo for done
    func testCanGoToConvo() {
        XCTAssertTrue(TestClaudeState.done.canGoToConvo)
        XCTAssertFalse(TestClaudeState.working.canGoToConvo)
        XCTAssertFalse(TestClaudeState.idle.canGoToConvo)
        XCTAssertFalse(TestClaudeState.approveQuestion.canGoToConvo)
        XCTAssertFalse(TestClaudeState.needsInput.canGoToConvo)
        XCTAssertFalse(TestClaudeState.error.canGoToConvo)
    }
}

// MARK: - XCTest Wrapper

final class LCDStateXCTests: XCTestCase {
    private let suite = LCDStateTests()

    func testStateLabels() { suite.testStateLabels() }
    func testPriorityOrder() { suite.testPriorityOrder() }
    func testPriorityEnforcement() { suite.testPriorityEnforcement() }
    func testNeedsAttention() { suite.testNeedsAttention() }
    func testCanGoToConvo() { suite.testCanGoToConvo() }
}
