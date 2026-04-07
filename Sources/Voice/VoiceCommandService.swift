import Foundation
import AVFoundation
import os.log

/// Double-clap detector for hands-free recording toggle.
/// Clap twice to start recording, clap twice again to stop and send.
@MainActor
final class VoiceCommandService: ObservableObject {

    // MARK: - Published State

    @Published var isListening: Bool = false

    @Published var enabled: Bool = false {
        didSet {
            UserDefaults.standard.set(enabled, forKey: "voiceCommandsEnabled")
            if enabled { startListening() } else { stopListening() }
        }
    }

    var onDoubleClap: (() -> Void)?

    // MARK: - Private State

    private var audioEngine: AVAudioEngine?

    // Clap detection
    private var lastClapTime: Date = .distantPast
    private static let clapThreshold: Float = 0.2
    private static let clapInterval: TimeInterval = 0.5
    private static let clapCooldown: TimeInterval = 1.0
    private var lastDoubleClapTime: Date = .distantPast

    private static let logger = Logger(subsystem: "com.vecartier.cc-beeper", category: "clap")

    private func log(_ msg: String) {
        Self.logger.info("\(msg, privacy: .public)")
    }

    // MARK: - Lifecycle

    init() {
        enabled = UserDefaults.standard.bool(forKey: "voiceCommandsEnabled")
    }

    func startListening() {
        guard enabled, !isListening else { return }

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let nativeFormat = inputNode.outputFormat(forBus: 0)

        guard nativeFormat.sampleRate > 0, nativeFormat.channelCount > 0 else {
            log("Microphone unavailable for clap detection")
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: nil) { [weak self] buffer, _ in
            self?.detectClap(buffer: buffer)
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            log("Failed to start clap detection: \(error)")
            inputNode.removeTap(onBus: 0)
            return
        }

        audioEngine = engine
        isListening = true
        log("Clap detection started")
    }

    func stopListening() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isListening = false
        log("Clap detection stopped")
    }

    // MARK: - Clap Detection

    nonisolated func detectClap(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)

        var sum: Float = 0
        for i in 0..<frameCount {
            let sample = channelData[i]
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(frameCount))

        guard rms > Self.clapThreshold else { return }

        let now = Date()
        Task { @MainActor [weak self] in
            guard let self else { return }
            let timeSinceLastClap = now.timeIntervalSince(self.lastClapTime)
            let timeSinceLastDouble = now.timeIntervalSince(self.lastDoubleClapTime)

            if timeSinceLastClap < Self.clapInterval && timeSinceLastDouble > Self.clapCooldown {
                self.lastDoubleClapTime = now
                self.log("Double clap detected")
                self.onDoubleClap?()
            }
            self.lastClapTime = now
        }
    }
}
