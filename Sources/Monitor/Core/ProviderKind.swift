import Foundation

enum ProviderKind: String, Equatable, CaseIterable {
    case claude
    case codex

    static let payloadProviderKey = "_vibe_beeper_provider"

    var displayName: String {
        switch self {
        case .claude: "Claude Code"
        case .codex: "Codex"
        }
    }

    static func from(payload: [String: Any]) -> ProviderKind {
        guard let raw = payload[payloadProviderKey] as? String,
              let provider = ProviderKind(rawValue: raw) else {
            return .claude
        }
        return provider
    }
}
