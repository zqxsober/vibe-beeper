import Foundation

enum AgentState: Equatable {
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

    var chineseLabel: String {
        switch self {
        case .idle: "摸鱼中"
        case .working: "开干中"
        case .done: "搞定啦"
        case .error: "翻车了"
        case .approveQuestion: "等放行"
        case .needsInput: "喊你呢"
        case .listening: "听着呢"
        case .speaking: "开讲啦"
        }
    }

    func displayLabel(useChinese: Bool) -> String {
        useChinese ? chineseLabel : label
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

typealias ClaudeState = AgentState
