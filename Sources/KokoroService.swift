import Foundation
import AVFoundation
@preconcurrency import FluidAudio

/// Actor wrapping FluidAudio's KokoroTtsManager lifecycle for on-device Kokoro-82M TTS synthesis.
///
/// Usage:
///   - Check `KokoroService.modelsDownloaded` before routing to Kokoro path (cheap disk stat, no load).
///   - Use `KokoroService.shared` singleton — initialize once, then call `synthesize()` repeatedly.
///   - Do NOT call `initialize()` or `downloadModels()` on every synthesis request.
actor KokoroService {

    // MARK: - Singleton

    static let shared = KokoroService()

    // MARK: - Internal State

    private var manager: KokoroTtsManager?

    private init() {}

    // MARK: - Model Presence Check (cheap disk stat, no load)

    /// Returns true if the Kokoro CoreML model bundle exists on disk.
    /// This is a cheap `checkResourceIsReachable()` call — does NOT load the model.
    /// Use this from TTSService to decide which TTS path to take.
    static var modelsDownloaded: Bool {
        let modelPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cache/fluidaudio/Models/kokoro")
            .appendingPathComponent(ModelNames.TTS.defaultVariant.fileName)
        return (try? modelPath.checkResourceIsReachable()) ?? false
    }

    // MARK: - Model Download with Progress (called from onboarding)

    /// Download Kokoro CoreML models from HuggingFace with progress reporting.
    /// After completion, the manager is ready for use — no separate `initialize()` call needed.
    ///
    /// - Parameter onProgress: Called on arbitrary thread with (fraction 0..1, label string).
    func downloadModels(onProgress: @escaping @Sendable (Double, String) -> Void) async throws {
        let m = KokoroTtsManager(defaultVoice: "af_heart")
        try await m.initialize(preloadVoices: ["af_heart"])
        self.manager = m
    }

    // MARK: - Initialize from Disk (load already-downloaded models, no network)

    /// Load the Kokoro model from disk into memory.
    /// Call once before first synthesis (or lazily on first use from TTSService).
    /// Do NOT call on every synthesis request — keep the manager alive.
    func initialize(defaultVoice: String = "af_heart") async throws {
        let m = KokoroTtsManager(defaultVoice: defaultVoice)
        try await m.initialize(preloadVoices: [defaultVoice])
        self.manager = m
    }

    // MARK: - Synthesize

    /// Synthesize text to WAV audio data using the Kokoro model.
    /// Returns 16-bit PCM WAV at 24 000 Hz — playable with AVAudioPlayer(data:fileTypeHint:.wav).
    ///
    /// - Parameters:
    ///   - text: Text to synthesize.
    ///   - voice: Optional voice override. Defaults to the manager's configured default voice.
    /// - Returns: WAV Data ready for AVAudioPlayer playback.
    func synthesize(text: String, voice: String? = nil) async throws -> Data {
        guard let manager else {
            throw KokoroServiceError.notInitialized
        }
        return try await manager.synthesize(text: text, voice: voice)
    }

    // MARK: - Voice Selection

    /// Update the default voice used for synthesis.
    func setDefaultVoice(_ voice: String) async throws {
        try await manager?.setDefaultVoice(voice)
    }

    // MARK: - Readiness Check

    /// Returns true if the model is loaded and ready to synthesize.
    var isReady: Bool {
        manager != nil
    }
}

// MARK: - Errors

enum KokoroServiceError: Error, LocalizedError {
    case notInitialized

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "KokoroService: model not initialized — call initialize() before synthesizing"
        }
    }
}
