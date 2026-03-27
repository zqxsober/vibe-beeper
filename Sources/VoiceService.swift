import Foundation
import AVFoundation
import Speech
import AppKit
import ApplicationServices

final class VoiceService: ObservableObject, @unchecked Sendable {

    @Published var isRecording: Bool = false
    @Published var lastTranscriptPreview: String = ""

    /// Set by ClaudeMonitor after both services are created. Used to cut TTS before recording.
    var ttsService: TTSService?

    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var lastTranscript: String = ""
    private var recordingStartTime: Date?
    private var previousAppPID: pid_t? = nil

    // MARK: - Parakeet State

    private let parakeetService = ParakeetService.shared
    private var hasSubmitted: Bool = false        // Guard against double-submit (EOU + Stop)
    private var lastInjectedText: String = ""     // Tracks what's already in the terminal for delta injection
    private var isParakeetSession: Bool = false   // Which path is currently active

    // MARK: - STT Engine Label

    /// Exposed to Settings > Voice to show which STT engine is active.
    var sttEngineLabel: String {
        ParakeetService.modelsDownloaded ? "Parakeet TDT (local)" : "SFSpeech (fallback)"
    }

    // MARK: - Logging

    private static let logPath = NSHomeDirectory() + "/.claude/cc-beeper/voice.log"

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

    func toggle() {
        if isRecording {
            stopRecording()
        } else {
            // Cut TTS immediately — recording has absolute priority
            if let tts = ttsService, tts.isSpeaking {
                tts.stopSpeaking()
            }
            startRecording()
        }
    }

    func stopIfRecording() {
        if isRecording { stopRecording() }
    }

    // MARK: - Recording Router

    private func startRecording() {
        log("=== START ===")

        // Check Accessibility — log but don't prompt every time
        let axTrusted = AXIsProcessTrusted()
        log("AX trusted: \(axTrusted)")

        // Recording has absolute priority — kill TTS first
        if let tts = ttsService, tts.isSpeaking {
            tts.stopSpeaking()
            usleep(200_000) // additional wait for full audio session release
            log("killed TTS before recording")
        }

        if isRecording { stopRecording() }

        // Capture previous app BEFORE focusing terminal
        previousAppPID = NSWorkspace.shared.frontmostApplication?.processIdentifier

        // Recreate AVAudioEngine each session — do not reuse (prevents headphone corruption)
        audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode
        let nativeFormat = inputNode.outputFormat(forBus: 0)
        log("format: \(nativeFormat.sampleRate)Hz, \(nativeFormat.channelCount)ch")

        guard nativeFormat.sampleRate > 0, nativeFormat.channelCount > 0 else {
            log("bad format")
            return
        }

        log("STT engine: \(sttEngineLabel)")

        if ParakeetService.modelsDownloaded {
            startRecordingParakeet(inputNode: inputNode)
        } else {
            startRecordingSFSpeech(inputNode: inputNode)
        }
    }

    // MARK: - Parakeet Recording Path

    private func startRecordingParakeet(inputNode: AVAudioInputNode) {
        log("Parakeet mode: streaming with live terminal injection (D-02)")
        isParakeetSession = true
        hasSubmitted = false
        lastInjectedText = ""

        Task {
            do {
                if await !parakeetService.isReady {
                    try await parakeetService.initialize()
                }
                await parakeetService.reset()
                await parakeetService.configureCallbacks(
                    onPartial: { [weak self] partial in
                        Task { @MainActor in
                            guard let self, !self.hasSubmitted else { return }
                            // PRIMARY: Live inject delta into terminal (per D-02)
                            self.injectPartialDelta(partial)
                            // SECONDARY: LCD preview as visual feedback
                            self.lastTranscriptPreview = partial
                        }
                    },
                    onEou: { [weak self] transcript in
                        // EOU auto-submit after 1280ms silence
                        Task { @MainActor in
                            guard let self, !self.hasSubmitted, !transcript.isEmpty else { return }
                            self.hasSubmitted = true
                            self.lastTranscriptPreview = transcript
                            self.log("EOU auto-submit: '\(transcript)'")
                            self.stopRecordingEngine()
                            // Text is already in terminal from partial injection.
                            // Inject any remaining characters not yet injected and press Enter.
                            let remaining = String(transcript.dropFirst(self.lastInjectedText.count))
                            if !remaining.isEmpty {
                                self.injectTextOnly(remaining)
                            }
                            self.lastInjectedText = ""
                            self.submitTerminal()
                        }
                    }
                )
            } catch {
                log("Parakeet init failed, falling back to SFSpeech: \(error)")
                isParakeetSession = false
                await MainActor.run {
                    self.startRecordingSFSpeech(inputNode: inputNode)
                }
                return
            }
        }

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: nil) { [weak self] buffer, _ in
            guard let self else { return }
            Task {
                try? await self.parakeetService.process(buffer)
            }
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            recordingStartTime = Date()
            log("Parakeet mode: recording with live injection...")
        } catch {
            log("Parakeet mode: engine failed: \(error)")
            inputNode.removeTap(onBus: 0)
            isRecording = false
        }
    }

    // MARK: - SFSpeech Recording Path

    private func startRecordingSFSpeech(inputNode: AVAudioInputNode) {
        isParakeetSession = false
        guard let recognizer else { log("no recognizer"); return }

        let authStatus = SFSpeechRecognizer.authorizationStatus()
        if authStatus == .notDetermined {
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                Task { @MainActor in if status == .authorized { self?.startRecording() } }
            }
            return
        }
        guard authStatus == .authorized else { log("speech not authorized"); return }

        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if micStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                Task { @MainActor in if granted { self?.startRecording() } }
            }
            return
        }
        guard micStatus == .authorized else { log("mic not authorized"); return }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = true
        recognitionRequest = request
        lastTranscript = ""

        // format: nil lets the system pick optimal format (works with headphones)
        let capturedRequest = request
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: nil) { buffer, _ in
            capturedRequest.append(buffer)
        }
        log("SFSpeech mode: tap installed")

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                let text = result.bestTranscription.formattedString
                self.lastTranscript = text

                // When we get the final result (after endAudio), inject it
                if result.isFinal {
                    self.recognitionTask = nil
                    self.log("final transcript: '\(text)'")
                    self.lastTranscriptPreview = text
                    if !text.isEmpty {
                        self.injectAndSubmit(text)
                    }
                }
            }
            if let error {
                let code = (error as NSError).code
                if code != 216 { // 216 = cancelled, expected
                    self.log("recognition error: \(code)")
                }
            }
        }
        log("recognition task created")

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            recordingStartTime = Date()
            log("SFSpeech mode: recording...")
        } catch {
            log("engine failed: \(error)")
        }
    }

    // MARK: - Stop Recording

    private func stopRecording() {
        log("=== STOP ===")
        guard isRecording else { return }

        if isParakeetSession {
            // Parakeet path — stop engine, finalize transcript
            stopRecordingEngine()

            if hasSubmitted {
                // EOU already fired and submitted — nothing more to do
                log("Parakeet mode: EOU already submitted, stop is no-op")
            } else {
                // Manual stop — call finish() and inject remaining delta + Enter
                Task {
                    do {
                        let final = try await parakeetService.finish()
                        await MainActor.run {
                            if !final.isEmpty && !self.hasSubmitted {
                                self.hasSubmitted = true
                                self.lastTranscriptPreview = final
                                // Inject any remaining characters not yet in terminal
                                let remaining = String(final.dropFirst(self.lastInjectedText.count))
                                if !remaining.isEmpty {
                                    self.injectTextOnly(remaining)
                                }
                                self.lastInjectedText = ""
                                self.submitTerminal()
                            }
                        }
                    } catch {
                        self.log("Parakeet finish() failed: \(error)")
                    }
                }
            }
        } else {
            // SFSpeech path — endAudio and wait for final result
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
            isRecording = false
            recognitionRequest?.endAudio()
            recognitionRequest = nil
            // Don't cancel the recognition task — let it deliver the final result
            // Recreate engine per session — prevents corruption on subsequent recordings
            audioEngine = AVAudioEngine()
            log("SFSpeech mode: stopped — waiting for final result")

            // Wait up to 2 seconds for the final transcript to arrive via the callback
            // The recognition callback will set lastTranscript and call injectAndSubmit
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self else { return }
                // If the callback already handled it, recognitionTask will be nil
                if self.recognitionTask != nil {
                    // Timed out — use whatever partial we have
                    let text = self.lastTranscript
                    self.lastTranscript = ""
                    self.recognitionTask?.cancel()
                    self.recognitionTask = nil
                    self.log("timeout, using partial: '\(text)'")
                    if !text.isEmpty {
                        self.lastTranscriptPreview = text
                        self.injectAndSubmit(text)
                    }
                }
            }
        }
    }

    // MARK: - Stop Recording Engine (shared helper)

    /// Stops the AVAudioEngine and resets for next session.
    /// Called by both the EOU callback and the manual stop handler.
    private func stopRecordingEngine() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRecording = false
        // Recreate engine per session — prevents corruption on subsequent recordings
        audioEngine = AVAudioEngine()
    }

    // MARK: - Live Terminal Injection (D-02)

    /// Injects only the delta (new characters) since the last injected partial.
    /// PartialCallback fires with the FULL accumulated transcript — we track what's already in the terminal.
    /// If the partial doesn't extend previous text (model revised earlier words), clears and re-injects.
    private func injectPartialDelta(_ fullPartial: String) {
        let alreadyInjected = lastInjectedText

        guard fullPartial.hasPrefix(alreadyInjected) else {
            // Partial does NOT extend previous — text was revised/corrected by model.
            // Clear terminal input and re-inject the full partial.
            clearTerminalInput()
            injectTextOnly(fullPartial)
            lastInjectedText = fullPartial
            return
        }

        let delta = String(fullPartial.dropFirst(alreadyInjected.count))
        guard !delta.isEmpty else { return }

        injectTextOnly(delta)
        lastInjectedText = fullPartial
    }

    /// Injects text into the terminal WITHOUT pressing Enter.
    /// Used for live streaming partial results and final delta injection before submitTerminal().
    private func injectTextOnly(_ text: String) {
        guard !text.isEmpty else { return }

        focusTerminal()
        usleep(500_000) // wait for terminal to come forward

        let utf16 = Array(text.utf16)
        if utf16.count <= 200 {
            guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else { return }
            keyDown.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
            keyUp.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
        } else {
            // Clipboard paste fallback for long text
            let pb = NSPasteboard.general
            let old = pb.string(forType: .string)
            pb.clearContents()
            pb.setString(text, forType: .string)
            guard let down = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: true),
                  let up = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: false) else { return }
            down.flags = .maskCommand
            up.flags = .maskCommand
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
            usleep(100_000)
            if let old { pb.clearContents(); pb.setString(old, forType: .string) }
        }

        log("injected (no submit): '\(text)'")
        refocusPreviousApp()
    }

    /// Clears the current terminal input line by selecting all and pressing Delete.
    /// Used when Parakeet revises earlier words (partial doesn't extend previous injected text).
    private func clearTerminalInput() {
        focusTerminal()
        usleep(300_000) // wait for terminal to come forward

        // Cmd+A to select all text in the current input
        guard let selectDown = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
              let selectUp = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else { return }
        selectDown.flags = .maskCommand
        selectUp.flags = .maskCommand
        // keycode 0 = 'a', but we need Cmd+A = Select All
        // Use virtualKey 0x00 ('a')
        selectDown.post(tap: .cghidEventTap)
        selectUp.post(tap: .cghidEventTap)

        usleep(50_000)

        // Delete/Backspace to clear selected text
        guard let delDown = CGEvent(keyboardEventSource: nil, virtualKey: 0x33, keyDown: true),
              let delUp = CGEvent(keyboardEventSource: nil, virtualKey: 0x33, keyDown: false) else { return }
        delDown.post(tap: .cghidEventTap)
        delUp.post(tap: .cghidEventTap)

        log("cleared terminal input (model revision)")
    }

    /// Presses Enter only — text is already in the terminal from partial injection.
    /// Use after all delta text has been injected via `injectTextOnly`.
    private func submitTerminal() {
        focusTerminal()
        usleep(100_000)
        guard let enterDown = CGEvent(keyboardEventSource: nil, virtualKey: 0x24, keyDown: true),
              let enterUp = CGEvent(keyboardEventSource: nil, virtualKey: 0x24, keyDown: false) else { return }
        enterDown.post(tap: .cghidEventTap)
        enterUp.post(tap: .cghidEventTap)
        log("submitted (Enter only)")
        refocusPreviousApp()
    }

    // MARK: - Inject text + Enter (SFSpeech path, unchanged)

    private func injectAndSubmit(_ text: String) {
        guard !text.isEmpty else { return }

        focusTerminal()
        usleep(500_000) // wait for terminal to come forward

        let utf16 = Array(text.utf16)
        if utf16.count <= 200 {
            guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else { return }
            keyDown.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
            keyUp.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
        } else {
            // Clipboard paste fallback for long text
            let pb = NSPasteboard.general
            let old = pb.string(forType: .string)
            pb.clearContents()
            pb.setString(text, forType: .string)
            guard let down = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: true),
                  let up = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: false) else { return }
            down.flags = .maskCommand
            up.flags = .maskCommand
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
            usleep(100_000)
            if let old { pb.clearContents(); pb.setString(old, forType: .string) }
        }

        // Press Enter
        usleep(100_000)
        guard let enterDown = CGEvent(keyboardEventSource: nil, virtualKey: 0x24, keyDown: true),
              let enterUp = CGEvent(keyboardEventSource: nil, virtualKey: 0x24, keyDown: false) else { return }
        enterDown.post(tap: .cghidEventTap)
        enterUp.post(tap: .cghidEventTap)

        log("injected + submitted: '\(text)'")

        refocusPreviousApp()
    }

    // MARK: - Terminal Focus

    private func focusTerminal() {
        let terminalApps: [(bundleID: String, name: String)] = [
            ("com.apple.Terminal", "Terminal"),
            ("com.googlecode.iterm2", "iTerm"),
            ("dev.warp.Warp-Stable", "Warp"),
            ("io.alacritty", "Alacritty"),
            ("net.kovidgoyal.kitty", "kitty"),
            ("com.github.wez.wezterm", "WezTerm"),
        ]
        for app in NSWorkspace.shared.runningApplications {
            guard let bid = app.bundleIdentifier else { continue }
            if let match = terminalApps.first(where: { $0.bundleID == bid }) {
                let task = Process()
                task.launchPath = "/usr/bin/open"
                task.arguments = ["-a", match.name]
                try? task.run()
                log("focused terminal via open -a \(match.name)")
                return
            }
        }
        log("no terminal found to focus")
    }

    // MARK: - Refocus Previous App

    private func refocusPreviousApp() {
        guard let pid = previousAppPID else { return }
        usleep(200_000) // brief pause after Enter
        if let app = NSRunningApplication(processIdentifier: pid) {
            app.activate()
            log("refocused previous app (pid \(pid))")
        }
        previousAppPID = nil
    }
}
