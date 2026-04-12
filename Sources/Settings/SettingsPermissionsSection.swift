import SwiftUI

struct SettingsPermissionsSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        PermissionRow(
            icon: "accessibility",
            label: "Accessibility",
            isGranted: viewModel.isAccessibilityGranted,
            openSettings: { viewModel.openAccessibilitySettings() }
        )

        PermissionRow(
            icon: "mic.fill",
            label: "Microphone",
            isGranted: viewModel.isMicGranted,
            openSettings: { viewModel.openMicrophoneSettings() }
        )

        PermissionRow(
            icon: "waveform.circle.fill",
            label: "Speech Recognition",
            isGranted: viewModel.isSpeechGranted,
            openSettings: { viewModel.openSpeechSettings() }
        )
    }
}

private struct PermissionRow: View {
    let icon: String
    let label: String
    let isGranted: Bool
    let openSettings: () -> Void

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
            Spacer()
            PermissionBadge(
                text: isGranted ? "Granted" : "Grant",
                color: isGranted ? Color(hex: "5C8A4D") : Color(hex: "C96442"),
                action: openSettings
            )
        }
    }
}

private struct PermissionBadge: View {
    let text: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text.uppercased())
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(0.5)
                .foregroundStyle(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(color.opacity(0.2))
                )
        }
        .buttonStyle(.plain)
    }
}
