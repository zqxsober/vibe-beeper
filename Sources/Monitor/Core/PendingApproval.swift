import Foundation

struct PendingApproval: Equatable {
    let sessionId: String
    let provider: ProviderKind
    let tool: String
    let summary: String

    var id: String { "\(provider.rawValue):\(sessionId)" }
}

typealias PendingPermission = PendingApproval
