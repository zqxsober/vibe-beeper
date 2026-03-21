import Speech
import AVFoundation
import AppKit
import ApplicationServices

// MARK: - VoiceService

final class VoiceService: ObservableObject {

    // MARK: Published State

    @Published var isRecording = false

    // MARK: Private Properties

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // MARK: Callback

    var onTranscript: ((String) -> Void)?

    // MARK: Authorization

    static func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async { completion(status == .authorized) }
        }
    }

    // MARK: Recording

    func startRecording() {
        print("[VoiceService] startRecording called")
        guard let recognizer else {
            print("[VoiceService] recognizer is nil — SFSpeechRecognizer not available for locale")
            return
        }
        guard recognizer.isAvailable else {
            print("[VoiceService] recognizer not available (offline or restricted)")
            return
        }

        let authStatus = SFSpeechRecognizer.authorizationStatus()
        print("[VoiceService] auth status: \(authStatus.rawValue)")
        guard authStatus == .authorized else {
            print("[VoiceService] requesting authorization...")
            Self.requestAuthorization { [weak self] granted in
                print("[VoiceService] authorization result: \(granted)")
                if granted { self?.startRecording() }
            }
            return
        }

        // Cancel any in-flight task before starting a new one
        stopRecording()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = false
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        // Use outputFormat of inputNode — avoids zero-channel crash on macOS
        // (inputFormat can return 0 channels on some hardware)
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            if let result, result.isFinal {
                let text = result.bestTranscription.formattedString
                self?.recognitionTask = nil
                DispatchQueue.main.async { self?.handleTranscript(text) }
            }
            if let error, (error as NSError).code != 216 { // 216 = "request was cancelled" — ignore
                self?.recognitionTask?.cancel()
                self?.recognitionTask = nil
                DispatchQueue.main.async { self?.isRecording = false }
            }
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            print("[VoiceService] audio engine started, recording...")
        } catch {
            print("[VoiceService] audio engine failed to start: \(error)")
            return
        }
        DispatchQueue.main.async { self.isRecording = true }
    }

    func stopRecording() {
        guard isRecording else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        // Signal end of audio — this triggers the final recognition result
        // Do NOT cancel the task here — let the callback fire with isFinal first
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        // Recreate engine — reset() is unreliable; AVAudioEngine is lightweight to instantiate
        audioEngine = AVAudioEngine()
        DispatchQueue.main.async { self.isRecording = false }
    }

    // MARK: Transcript Handling

    private func handleTranscript(_ text: String) {
        // Notify any external consumers first
        onTranscript?(text)

        let knownTerminals: Set<String> = [
            "com.apple.Terminal",
            "com.googlecode.iterm2",
            "dev.warp.Warp-Stable",
            "io.alacritty",
            "net.kovidgoyal.kitty",
            "com.github.wez.wezterm",
        ]

        let frontmostBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""

        if knownTerminals.contains(frontmostBundleID) {
            typeText(text)
        } else {
            activateTerminal()
            // Delay injection to let the terminal activation settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.typeText(text)
            }
        }
    }

    // MARK: Terminal Activation

    private func activateTerminal() {
        let knownTerminals = [
            "com.apple.Terminal",
            "com.googlecode.iterm2",
            "dev.warp.Warp-Stable",
            "io.alacritty",
            "net.kovidgoyal.kitty",
            "com.github.wez.wezterm",
        ]
        for app in NSWorkspace.shared.runningApplications {
            if let bid = app.bundleIdentifier, knownTerminals.contains(bid) {
                app.activate()
                return
            }
        }
    }

    // MARK: Keystroke Injection

    func typeText(_ text: String) {
        guard AXIsProcessTrusted() else { return }
        guard !text.isEmpty else { return }

        let utf16 = Array(text.utf16)

        // Chunk into batches of 20 UTF-16 units to avoid dropped characters in slow terminals
        let chunkSize = 20
        var offset = 0

        while offset < utf16.count {
            let end = min(offset + chunkSize, utf16.count)
            let chunk = Array(utf16[offset..<end])

            let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 0x31, keyDown: true)
            keyDown?.flags = .maskNonCoalesced
            keyDown?.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: chunk)
            keyDown?.post(tap: .cghidEventTap)

            let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 0x31, keyDown: false)
            keyUp?.post(tap: .cghidEventTap)

            offset += chunkSize

            // Small delay between chunks to avoid dropped characters in slow terminals
            if offset < utf16.count {
                usleep(10_000) // 10ms
            }
        }
    }
}
