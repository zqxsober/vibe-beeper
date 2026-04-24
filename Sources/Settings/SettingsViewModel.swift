import Foundation
import AppKit
import ApplicationServices
import AVFoundation
import Speech

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var isAccessibilityGranted: Bool = false
    @Published var isMicGranted: Bool = false
    @Published var isSpeechGranted: Bool = false
    @Published var isClaudeDetected: Bool = false
    @Published var isCodexDetected: Bool = false
    @Published var isClaudeHooksInstalled: Bool = false
    @Published var isCodexHooksInstalled: Bool = false
    @Published var setupErrorMessage: String? = nil

    private var pollTimer: Timer?

    func startPolling() {
        refreshPermissionStatus()
        detectProviders()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshPermissionStatus()
            }
        }
    }

    func detectProviders() {
        isClaudeDetected = ClaudeDetector.isInstalled
        isCodexDetected = CodexDetector.isInstalled
        isClaudeHooksInstalled = HookInstaller.isInstalled
        isCodexHooksInstalled = CodexHookInstaller.isInstalled(
            configContents: readCodexConfigContents() ?? "",
            hooksContents: readCodexHooksContents() ?? ""
        )
    }

    func installMissingIntegrations() {
        setupErrorMessage = nil

        do {
            if isClaudeDetected && !isClaudeHooksInstalled {
                try HookInstaller.install()
            }
            if isCodexDetected && !isCodexHooksInstalled {
                try CodexHookInstaller.install()
            }
            detectProviders()
        } catch {
            setupErrorMessage = error.localizedDescription
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func refreshPermissionStatus() {
        isAccessibilityGranted = AXIsProcessTrusted()
        isMicGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        isSpeechGranted = SFSpeechRecognizer.authorizationStatus() == .authorized
    }

    private func readCodexConfigContents() -> String? {
        guard let data = FileManager.default.contents(atPath: CodexHookInstaller.configPath) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func readCodexHooksContents() -> String? {
        guard let data = FileManager.default.contents(atPath: CodexHookInstaller.hooksPath) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Permission Requests + Deep Links

    func openAccessibilitySettings() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        if let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func openMicrophoneSettings() {
        AVCaptureDevice.requestAccess(for: .audio) { _ in
            Task { @MainActor [weak self] in
                self?.isMicGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
            }
        }
        if let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }

    func openSpeechSettings() {
        SFSpeechRecognizer.requestAuthorization { _ in
            Task { @MainActor [weak self] in
                self?.isSpeechGranted = SFSpeechRecognizer.authorizationStatus() == .authorized
            }
        }
        if let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_SpeechRecognition") {
            NSWorkspace.shared.open(url)
        }
    }
}
