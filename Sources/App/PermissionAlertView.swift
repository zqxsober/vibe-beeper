import SwiftUI
import AVFoundation
import Speech
import ApplicationServices

/// Shown on launch when required permissions are missing.
/// Native macOS settings-style layout.
struct PermissionAlertView: View {
    @EnvironmentObject var monitor: ClaudeMonitor

    @State private var axGranted = AXIsProcessTrusted()
    @State private var micGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    @State private var speechGranted = SFSpeechRecognizer.authorizationStatus() == .authorized

    private var allGranted: Bool { axGranted && micGranted && speechGranted }
    private let pollTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private func closeWindow() {
        monitor.missingPermissions = []
        NSApp.windows.first(where: { $0.identifier?.rawValue == "permissions-alert" })?.orderOut(nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("CC-Beeper Permissions")
                    .font(.system(size: 22, weight: .bold))
                Text("These permissions were granted during setup but may have been revoked — for example after an app update or system change. Some features won't work without them.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider().padding(.horizontal, 20)

            // Permission rows
            VStack(spacing: 0) {
                permissionRow(
                    isGranted: axGranted,
                    name: "Accessibility",
                    description: "Required for global hotkeys (accept, deny, record) from any app.",
                    onGrant: {
                        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                        _ = AXIsProcessTrustedWithOptions(options)
                        openURL("x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility")
                    }
                )
                Divider().padding(.leading, 56)
                permissionRow(
                    isGranted: micGranted,
                    name: "Microphone",
                    description: "Required for voice dictation into Claude Code.",
                    onGrant: {
                        AVCaptureDevice.requestAccess(for: .audio) { _ in
                            Task { @MainActor in micGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized }
                        }
                        openURL("x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Microphone")
                    }
                )
                Divider().padding(.leading, 56)
                permissionRow(
                    isGranted: speechGranted,
                    name: "Speech Recognition",
                    description: "Used as fallback when WhisperKit is unavailable.",
                    onGrant: {
                        SFSpeechRecognizer.requestAuthorization { _ in
                            Task { @MainActor in speechGranted = SFSpeechRecognizer.authorizationStatus() == .authorized }
                        }
                        openURL("x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_SpeechRecognition")
                    }
                )
            }
            .padding(.vertical, 8)

            Divider().padding(.horizontal, 20)

            // Footer
            HStack {
                Spacer()
                Button("Skip for Now") { closeWindow() }
                    .controlSize(.large)
                if allGranted {
                    Button("Done") { closeWindow() }
                        .controlSize(.large)
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
        }
        .frame(width: 480)
        .onReceive(pollTimer) { _ in
            axGranted = AXIsProcessTrusted()
            micGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
            speechGranted = SFSpeechRecognizer.authorizationStatus() == .authorized
            if allGranted {
                monitor.missingPermissions = []
            }
        }
    }

    private func permissionRow(isGranted: Bool, name: String, description: String, onGrant: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "xmark.circle")
                .font(.system(size: 20))
                .foregroundStyle(isGranted ? .green : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 13, weight: .medium))
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !isGranted {
                Button("Grant") { onGrant() }
                    .controlSize(.small)
            } else {
                Text("Granted")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 10)
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        NSWorkspace.shared.open(url)
    }
}
