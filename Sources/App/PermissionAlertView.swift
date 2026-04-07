import SwiftUI
import AVFoundation
import Speech
import ApplicationServices

/// Shown on launch when required permissions are missing.
/// Same layout as the onboarding permissions step.
struct PermissionAlertView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    private func closeWindow() {
        NSApp.windows.first(where: { $0.identifier?.rawValue == "permissions-alert" })?.orderOut(nil)
    }

    @State private var axGranted = AXIsProcessTrusted()
    @State private var micGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    @State private var speechGranted = SFSpeechRecognizer.authorizationStatus() == .authorized

    private var allGranted: Bool { axGranted && micGranted && speechGranted }

    private let pollTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            Text("Some permissions are missing")
                .font(ClaudeTheme.sans(18, weight: .semibold))
                .foregroundStyle(ClaudeTheme.nearBlack)

            Text("Some features like hotkeys, dictation, and voice won't work without these. You can grant them now or later in Settings.")
                .font(ClaudeTheme.sans(12))
                .foregroundStyle(ClaudeTheme.stone)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            VStack(spacing: 8) {
                permissionRow(
                    isGranted: axGranted,
                    name: "Accessibility",
                    description: "For global hotkeys from any app.",
                    onGrant: {
                        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                        _ = AXIsProcessTrustedWithOptions(options)
                        openURL("x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility")
                    }
                )
                permissionRow(
                    isGranted: micGranted,
                    name: "Microphone",
                    description: "To dictate prompts into Claude.",
                    onGrant: {
                        AVCaptureDevice.requestAccess(for: .audio) { _ in
                            Task { @MainActor in micGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized }
                        }
                        openURL("x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Microphone")
                    }
                )
                permissionRow(
                    isGranted: speechGranted,
                    name: "Speech Recognition",
                    description: "Fallback when Whisper can't be used.",
                    onGrant: {
                        SFSpeechRecognizer.requestAuthorization { _ in
                            Task { @MainActor in speechGranted = SFSpeechRecognizer.authorizationStatus() == .authorized }
                        }
                        openURL("x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_SpeechRecognition")
                    }
                )
            }
            .frame(maxWidth: 420)

            HStack(spacing: 12) {
                Button("Later") { closeWindow() }
                    .buttonStyle(.plain)
                    .font(ClaudeTheme.sans(12))
                    .foregroundStyle(ClaudeTheme.stone)

                Button {
                    monitor.missingPermissions = []
                    closeWindow()
                } label: {
                    Text(allGranted ? "Done" : "Skip for Now")
                        .font(ClaudeTheme.sans(13, weight: .semibold))
                        .foregroundStyle(ClaudeTheme.ivory)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: ClaudeTheme.radiusMedium, style: .continuous)
                                .fill(allGranted ? ClaudeTheme.green : ClaudeTheme.terracotta)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(32)
        .frame(width: 500)
        .background(ClaudeTheme.parchment)
        .onReceive(pollTimer) { _ in
            axGranted = AXIsProcessTrusted()
            micGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
            speechGranted = SFSpeechRecognizer.authorizationStatus() == .authorized
            if allGranted {
                monitor.missingPermissions = []
                closeWindow()
            }
        }
    }

    private func permissionRow(isGranted: Bool, name: String, description: String, onGrant: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isGranted ? ClaudeTheme.green : ClaudeTheme.warmSilver)
                .font(.system(size: 18))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(ClaudeTheme.sans(12, weight: .medium))
                    .foregroundStyle(ClaudeTheme.nearBlack)
                Text(description)
                    .font(ClaudeTheme.sans(11))
                    .foregroundStyle(ClaudeTheme.stone)
            }

            Spacer()

            if isGranted {
                Text("GRANTED")
                    .font(ClaudeTheme.mono(9, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(ClaudeTheme.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(ClaudeTheme.green.opacity(0.12))
                    )
            } else {
                Button("Grant") { onGrant() }
                    .buttonStyle(.bordered)
                    .tint(ClaudeTheme.terracotta)
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .claudeCard(radius: ClaudeTheme.radiusMedium)
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        NSWorkspace.shared.open(url)
    }
}
