import Foundation

/// Protocol for voice recording service (TEST-01).
protocol VoiceServiceProtocol: AnyObject {
    var isRecording: Bool { get }
    func toggle()
    func stopIfRecording()
}

/// Protocol for text-to-speech service (TEST-01).
protocol TTSServiceProtocol: AnyObject {
    var isSpeaking: Bool { get }
    func speakSummary(_ text: String, provider: String) async -> String
    func stopSpeaking()
}

/// Protocol for HTTP hook server (TEST-01).
protocol HookServerProtocol: AnyObject {
    var activePort: UInt16 { get }
    var pendingPermissionConnections: [(sessionId: String, connection: Any)] { get }
    func start(handler: @escaping @MainActor (_ payload: [String: Any]) -> [String: Any]?)
    func stop()
    @discardableResult
    func sendPermissionResponse(_ payload: [String: Any], for sessionId: String) -> Bool
    func cancelOrphanedPermission(for sessionId: String)
    func cancelAllPermissions()
}
