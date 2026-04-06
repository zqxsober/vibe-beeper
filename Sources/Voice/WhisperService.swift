import Foundation
import WhisperKit

/// Actor wrapping WhisperKit for on-device batch speech-to-text transcription.
///
/// Usage:
///   - Check `WhisperService.modelsDownloaded` before routing to Whisper path (cheap disk stat, no load).
///   - Use `WhisperService.shared` singleton — load once at app launch, call `transcribe()` repeatedly.
///   - Whisper is stateless between calls — `reset()` is a no-op, unlike Parakeet's streaming state.
///   - Language auto-detected via `DecodingOptions(detectLanguage: true)` — no configuration needed (D-12).
actor WhisperService {

    // MARK: - Singleton

    static let shared = WhisperService()

    // MARK: - Internal State

    private var pipe: WhisperKit?

    private init() {}

    // MARK: - Model Presence Check (cheap disk stat, no load)

    /// Returns true if the currently selected Whisper model is downloaded and ready.
    /// This is a cheap file-existence check — does NOT load the model.
    /// Use this from VoiceService to decide which recording path to take.
    static var modelsDownloaded: Bool {
        return isModelDownloaded(size: .selected)
    }

    /// Returns true if the specified Whisper model is downloaded and ready.
    /// Checks for AudioEncoder.mlmodelc — the heaviest file, only present after full successful download.
    static func isModelDownloaded(size: WhisperModelSize) -> Bool {
        let folder = modelFolder(for: size)
        let encoderPath = folder.appendingPathComponent("AudioEncoder.mlmodelc").path
        return FileManager.default.fileExists(atPath: encoderPath)
    }

    // MARK: - Model Folder (per D-10)

    /// Returns the Application Support path for the given Whisper model size.
    /// Models are stored in ~/Library/Application Support/CC-Beeper/whisper/{modelName}/
    /// Base directory for all Whisper models. WhisperKit creates a subfolder per model name inside.
    static var modelBaseFolder: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CC-Beeper/whisper")
    }

    static func modelFolder(for size: WhisperModelSize) -> URL {
        modelBaseFolder.appendingPathComponent(size.modelName)
    }

    // MARK: - Model Download with Progress (called from onboarding or Settings)

    /// Download and initialize the specified Whisper model from HuggingFace with progress reporting.
    /// After completion, the pipe is ready for transcription — no separate `initialize()` call needed.
    ///
    /// - Parameters:
    ///   - size: The model size to download.
    ///   - onProgress: Called on arbitrary thread with (fraction 0..1, label string).
    func downloadModel(
        size: WhisperModelSize,
        onProgress: @escaping @Sendable (Double, String) -> Void
    ) async throws {
        onProgress(0.0, "Downloading \(size.modelName)...")
        // Don't pass modelFolder — WhisperKit skips download when a local folder is set.
        // Let it download to its default location, then copy to our folder.
        let config = WhisperKitConfig(
            model: size.modelName,
            download: true
        )
        let w = try await WhisperKit(config)
        // Copy downloaded model to our Application Support folder for future loads
        if let downloadedFolder = w.modelFolder {
            let destFolder = Self.modelFolder(for: size)
            try? FileManager.default.createDirectory(
                at: destFolder.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if !FileManager.default.fileExists(atPath: destFolder.path) {
                try? FileManager.default.copyItem(at: downloadedFolder, to: destFolder)
            }
        }
        self.pipe = w
        onProgress(1.0, "Ready")
    }

    // MARK: - Initialize from Cache (no download)

    /// Load the Whisper model from local cache. Call at app launch to pre-warm the model.
    /// Do NOT call on every recording session — keep `pipe` alive between sessions.
    ///
    /// - Parameter size: The model size to load.
    func initialize(size: WhisperModelSize) async throws {
        let config = WhisperKitConfig(
            model: size.modelName,
            modelFolder: Self.modelFolder(for: size).path,
            download: false
        )
        self.pipe = try await WhisperKit(config)
    }

    // MARK: - Batch Transcription (called AFTER recording stops)

    /// Transcribe accumulated audio frames. Whisper always auto-detects the spoken language
    /// so the user can speak in any language freely. The detected language is returned for
    /// downstream use (e.g. TTS voice recommendation).
    func transcribe(_ audioFrames: [Float]) async throws -> (text: String, language: String) {
        guard let pipe else { throw WhisperError.notLoaded }
        let options = DecodingOptions(detectLanguage: true)
        let results: [TranscriptionResult] = try await pipe.transcribe(
            audioArray: audioFrames,
            decodeOptions: options
        )
        guard let result = results.first else { return ("", "en") }
        let text = result.text.trimmingCharacters(in: .whitespaces)
        let lang = result.language.isEmpty ? "en" : result.language
        return (text, lang)
    }

    // MARK: - Readiness Check

    /// Returns true if the model is loaded and ready to transcribe audio.
    var isReady: Bool { pipe != nil }

    // MARK: - Reset

    /// No-op for Whisper — the model is stateless between calls.
    /// Unlike Parakeet's streaming state, no session state needs to be cleared.
    func reset() {
        // Whisper is stateless between calls — no session state to clear.
    }
}

// MARK: - Errors

enum WhisperError: Error, LocalizedError {
    case notLoaded

    var errorDescription: String? {
        switch self {
        case .notLoaded:
            return "Whisper model is not loaded. Download the model in Settings > Dictation."
        }
    }
}
