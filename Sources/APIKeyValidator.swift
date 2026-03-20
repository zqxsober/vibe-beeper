import Foundation

enum APIProvider: String, CaseIterable, Identifiable {
    case anthropic = "Anthropic"
    case openAI = "OpenAI"

    var id: String { rawValue }

    var keychainKey: String {
        switch self {
        case .anthropic: return "anthropicAPIKey"
        case .openAI: return "openAIAPIKey"
        }
    }
}

enum ValidationResult {
    case valid
    case invalid(String)
    case networkError(String)
}

struct APIKeyValidator {
    static func validate(key: String, provider: APIProvider) async -> ValidationResult {
        switch provider {
        case .anthropic:
            return await validateAnthropic(key: key)
        case .openAI:
            return await validateOpenAI(key: key)
        }
    }

    private static func validateAnthropic(key: String) async -> ValidationResult {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            return .networkError("Invalid URL")
        }
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": "claude-haiku-4-5",
            "max_tokens": 1,
            "messages": [["role": "user", "content": "hi"]]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            switch status {
            case 200, 201: return .valid
            case 401: return .invalid("Invalid API key")
            case 429: return .invalid("Rate limited — key exists but quota exceeded")
            case 529: return .networkError("Anthropic API temporarily overloaded — try again")
            default: return .networkError("HTTP \(status)")
            }
        } catch {
            return .networkError(error.localizedDescription)
        }
    }

    private static func validateOpenAI(key: String) async -> ValidationResult {
        guard let url = URL(string: "https://api.openai.com/v1/models") else {
            return .networkError("Invalid URL")
        }
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "GET"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            switch status {
            case 200: return .valid
            case 401: return .invalid("Invalid API key")
            case 429: return .invalid("Rate limited — key exists but quota exceeded")
            default: return .networkError("HTTP \(status)")
            }
        } catch {
            return .networkError(error.localizedDescription)
        }
    }
}
