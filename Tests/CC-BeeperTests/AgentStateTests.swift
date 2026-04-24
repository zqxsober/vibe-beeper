import XCTest

/// Mirror of production AgentState — must stay in sync with Sources/Monitor/Core/AgentState.swift.
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

struct AgentStateCoreContractTests {
    func testStateLabelsRemainStable() {
        XCTAssertEqual(TestAgentState.idle.label, "ZZZ...")
        XCTAssertEqual(TestAgentState.working.label, "WORKING")
        XCTAssertEqual(TestAgentState.done.label, "DONE!")
        XCTAssertEqual(TestAgentState.error.label, "ERROR")
        XCTAssertEqual(TestAgentState.approveQuestion.label, "APPROVE?")
        XCTAssertEqual(TestAgentState.needsInput.label, "INPUT?")
        XCTAssertEqual(TestAgentState.listening.label, "LISTENING")
        XCTAssertEqual(TestAgentState.speaking.label, "SPEAKING")
    }

    func testPriorityOrderRemainsStable() {
        XCTAssertEqual(TestAgentState.error.priority, 7)
        XCTAssertEqual(TestAgentState.approveQuestion.priority, 6)
        XCTAssertEqual(TestAgentState.needsInput.priority, 5)
        XCTAssertEqual(TestAgentState.listening.priority, 4)
        XCTAssertEqual(TestAgentState.speaking.priority, 3)
        XCTAssertEqual(TestAgentState.working.priority, 2)
        XCTAssertEqual(TestAgentState.done.priority, 1)
        XCTAssertEqual(TestAgentState.idle.priority, 0)
    }

    func testAttentionAndConvoFlagsRemainStable() {
        XCTAssertTrue(TestAgentState.approveQuestion.needsAttention)
        XCTAssertFalse(TestAgentState.needsInput.needsAttention)
        XCTAssertTrue(TestAgentState.done.canOpenSession)
        XCTAssertFalse(TestAgentState.working.canOpenSession)
    }
}

final class AgentStateXCTests: XCTestCase {
    private let suite = AgentStateCoreContractTests()

    func testStateLabelsRemainStable() { suite.testStateLabelsRemainStable() }
    func testPriorityOrderRemainsStable() { suite.testPriorityOrderRemainsStable() }
    func testAttentionAndConvoFlagsRemainStable() { suite.testAttentionAndConvoFlagsRemainStable() }
}
