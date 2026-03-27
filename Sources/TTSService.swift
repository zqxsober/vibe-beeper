import Foundation
import AVFoundation
import FoundationModels

final class TTSService: ObservableObject, @unchecked Sendable {

    @Published var isSpeaking: Bool = false

    private let synthesizer = AVSpeechSynthesizer()
    private var speechDelegate: TTSSpeechDelegate?

    // OpenAI TTS playback (must be instance property — prevents ARC deallocation during playback)
    private var audioPlayer: AVAudioPlayer?
    private var playerDelegate: OpenAITTSDelegate?

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
        let toSpeak = text
        await MainActor.run { speak(toSpeak, provider: provider) }
        return toSpeak
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        audioPlayer?.stop()
        audioPlayer = nil
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
        case "kokoro":
            if KokoroService.modelsDownloaded {
                speakWithKokoro(text)
            } else {
                log("Kokoro TTS: model not downloaded — falling back to Apple voice")
                speakWithAva(text)
            }
        default: // "apple" or any unknown/legacy value (groq, openai, etc.)
            speakWithAva(text)
        }
    }

    // MARK: - Kokoro TTS Path

    private func speakWithKokoro(_ text: String) {
        log("Kokoro TTS: speaking: \(text.prefix(200))")
        isSpeaking = true

        Task {
            do {
                // Lazy init on first use — initialize manager from already-downloaded models
                if await !KokoroService.shared.isReady {
                    let voice = UserDefaults.standard.string(forKey: "kokoroVoice") ?? "af_heart"
                    try await KokoroService.shared.initialize(defaultVoice: voice)
                }

                let data = try await KokoroService.shared.synthesize(text: text)

                await MainActor.run {
                    do {
                        let player = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.wav.rawValue)
                        self.playerDelegate = OpenAITTSDelegate { [weak self] in
                            Task { @MainActor in
                                self?.isSpeaking = false
                                self?.audioPlayer = nil
                            }
                        }
                        player.delegate = self.playerDelegate
                        self.audioPlayer = player
                        player.play()
                        self.log("Kokoro TTS: playback started")
                    } catch {
                        self.log("Kokoro TTS: AVAudioPlayer failed: \(error) — falling back to Apple voice")
                        self.speakWithAva(text)
                    }
                }
            } catch {
                log("Kokoro TTS: synthesis error: \(error) — falling back to Apple voice")
                await MainActor.run { self.speakWithAva(text) }
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

final class OpenAITTSDelegate: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { onFinish() }
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) { onFinish() }
}
