import Foundation
import AVFoundation
import FoundationModels

final class TTSService: ObservableObject, @unchecked Sendable {

    @Published var isSpeaking: Bool = false

    private let synthesizer = AVSpeechSynthesizer()
    private var speechDelegate: TTSSpeechDelegate?

    // TTS playback (must be instance property — prevents ARC deallocation during playback)
    private var audioPlayer: AVAudioPlayer?
    private var playerDelegate: TTSPlaybackDelegate?

    // Streaming PocketTTS playback
    private var streamingEngine: AVAudioEngine?
    private var streamingPlayerNode: AVAudioPlayerNode?

    // MARK: - Logging

    private static let logPath = NSHomeDirectory() + "/.claude/cc-beeper/tts.log"

    private func log(_ msg: String) {
        let line = "[\(Date())] \(msg)\n"
        if let fh = FileHandle(forWritingAtPath: Self.logPath) {
            fh.seekToEndOfFile()
            fh.write(line.data(using: .utf8)!)
            fh.closeFile()
        } else {
            FileManager.default.createFile(
                atPath: Self.logPath, contents: line.data(using: .utf8),
                attributes: [.posixPermissions: 0o600]
            )
        }
    }

    // MARK: - Public API

    /// Speak the given text directly. For long text, uses last paragraph. Returns what was spoken.
    func speakSummary(_ text: String, provider: String = "apple") async -> String {
        await MainActor.run { speak(text, provider: provider) }
        return text
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        audioPlayer?.stop()
        audioPlayer = nil
        streamingPlayerNode?.stop()
        streamingEngine?.stop()
        streamingPlayerNode = nil
        streamingEngine = nil
        isSpeaking = false
        // Give audio session time to fully release
        usleep(100_000)
    }

    // MARK: - Summarization

    private func summarize(_ text: String) async -> String {
        if text.count < 200 { return text }

        let availability = SystemLanguageModel.default.availability
        guard case .available = availability else {
            log("Apple Intelligence unavailable — using lastParagraph fallback")
            return lastParagraph(of: text)
        }

        let session = LanguageModelSession {
            """
            You are reading an AI coding assistant's response. \
            Extract ONLY the final conclusion — what was done and what the user should do next. \
            Say it in first person as the assistant. Keep it to 1-3 short sentences. \
            Skip all code, file paths, commands, and technical details.
            """
        }
        do {
            let response = try await session.respond(to: String(text.suffix(2000)))
            let summary = response.content
            log("AI summary: \(summary)")
            return summary.isEmpty ? lastParagraph(of: text) : summary
        } catch {
            log("AI summarization error: \(error)")
            return lastParagraph(of: text)
        }
    }

    private func lastParagraph(of text: String) -> String {
        text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 10 }
            .last ?? text
    }

    // MARK: - TTS Dispatcher

    private func speak(_ text: String, provider: String = "apple") {
        guard !text.isEmpty else { return }
        switch provider {
        case "pockettts":
            speakWithPocketTTS(text)
        default: // "apple" or any unknown value
            speakWithAva(text)
        }
    }

    // MARK: - PocketTTS Path

    /// Pre-buffer frame count before starting playback (~500ms = 6 frames at 80ms each).
    private static let preBufferFrames = 6

    private func speakWithPocketTTS(_ text: String) {
        log("PocketTTS: speaking: \(text.prefix(200))")
        isSpeaking = true

        Task {
            do {
                // Lazy init on first use
                if await !PocketTTSService.shared.isReady {
                    let voice = UserDefaults.standard.string(forKey: "pocketttsVoice") ?? "alba"
                    try await PocketTTSService.shared.initialize(defaultVoice: voice)
                }

                let stream = try await PocketTTSService.shared.synthesizeStreaming(text: text)
                let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 24000, channels: 1, interleaved: false)!

                // Set up audio engine
                let engine = AVAudioEngine()
                let playerNode = AVAudioPlayerNode()
                engine.attach(playerNode)
                engine.connect(playerNode, to: engine.mainMixerNode, format: format)
                try engine.start()

                await MainActor.run {
                    self.streamingEngine = engine
                    self.streamingPlayerNode = playerNode
                }

                // Collect frames into chunks — schedule larger buffers to avoid gaps
                var pendingSamples: [Float] = []
                let chunkSize = 1920 * Self.preBufferFrames  // ~500ms per chunk
                var playbackStarted = false

                for try await frame in stream {
                    pendingSamples.append(contentsOf: frame.samples)

                    // Once we have enough samples, schedule a chunk
                    if pendingSamples.count >= chunkSize {
                        let chunk = Array(pendingSamples.prefix(chunkSize))
                        pendingSamples = Array(pendingSamples.dropFirst(chunkSize))

                        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(chunk.count)) else { continue }
                        buffer.frameLength = AVAudioFrameCount(chunk.count)
                        memcpy(buffer.floatChannelData![0], chunk, chunk.count * MemoryLayout<Float>.size)
                        playerNode.scheduleBuffer(buffer, completionHandler: nil)

                        if !playbackStarted {
                            playerNode.play()
                            playbackStarted = true
                            self.log("PocketTTS: streaming playback started")
                        }
                    }
                }

                // Flush remaining samples
                if !pendingSamples.isEmpty {
                    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(pendingSamples.count)) else { return }
                    buffer.frameLength = AVAudioFrameCount(pendingSamples.count)
                    memcpy(buffer.floatChannelData![0], pendingSamples, pendingSamples.count * MemoryLayout<Float>.size)
                    playerNode.scheduleBuffer(buffer, completionHandler: nil)

                    if !playbackStarted {
                        playerNode.play()
                        playbackStarted = true
                        self.log("PocketTTS: streaming playback started (final flush)")
                    }
                }

                // Completion sentinel — empty buffer with callback fires when all audio is done
                let sentinel = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1)!
                sentinel.frameLength = 0
                playerNode.scheduleBuffer(sentinel) { [weak self] in
                    Task { @MainActor in
                        self?.isSpeaking = false
                        self?.streamingPlayerNode = nil
                        self?.streamingEngine?.stop()
                        self?.streamingEngine = nil
                        self?.log("PocketTTS: playback finished")
                    }
                }
            } catch {
                log("PocketTTS: synthesis error: \(error) — falling back to Apple voice")
                await MainActor.run {
                    self.streamingEngine?.stop()
                    self.streamingEngine = nil
                    self.streamingPlayerNode = nil
                    self.speakWithAva(text)
                }
            }
        }
    }

    // MARK: - Ava TTS Path

    private func speakWithAva(_ text: String) {
        guard !text.isEmpty else { return }
        log("speaking: \(text.prefix(200))")
        if isSpeaking { synthesizer.stopSpeaking(at: .immediate) }

        let utterance = AVSpeechUtterance(string: text)
        if let premium = AVSpeechSynthesisVoice(identifier: "com.apple.voice.premium.en-US.Ava") {
            utterance.voice = premium
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.05

        speechDelegate = TTSSpeechDelegate { [weak self] in
            guard let self else { return }
            Task { @MainActor in self.isSpeaking = false }
        }
        synthesizer.delegate = speechDelegate
        isSpeaking = true
        synthesizer.speak(utterance)
    }
}

// MARK: - Speech Delegates

final class TTSSpeechDelegate: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) { onFinish() }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) { onFinish() }
}

final class TTSPlaybackDelegate: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { onFinish() }
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) { onFinish() }
}
