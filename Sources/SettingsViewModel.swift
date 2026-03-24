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

    private var pollTimer: Timer?

    func startPolling() {
        refreshPermissionStatus()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshPermissionStatus()
            }
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

    // MARK: - Deep Links

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    func openMicrophoneSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Microphone") else { return }
        NSWorkspace.shared.open(url)
    }

    func openSpeechSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_SpeechRecognition") else { return }
        NSWorkspace.shared.open(url)
    }

    func openSpokenContent() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Accessibility-Settings.extension?SpokenContent") else { return }
        NSWorkspace.shared.open(url)
    }
}
