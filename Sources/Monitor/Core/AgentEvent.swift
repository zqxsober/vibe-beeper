import Foundation

enum AgentEvent: Equatable {
    case toolStarted(sessionId: String, provider: ProviderKind, tool: String?)
    case toolFinished(sessionId: String, provider: ProviderKind, tool: String?)
    case runCompleted(sessionId: String, provider: ProviderKind, summary: String?)
    case runFailed(sessionId: String, provider: ProviderKind, message: String?)
    case approvalRequested(sessionId: String, provider: ProviderKind, tool: String, summary: String)
    case inputRequested(sessionId: String, provider: ProviderKind, message: String)
    case authStatus(provider: ProviderKind, success: Bool)
}
