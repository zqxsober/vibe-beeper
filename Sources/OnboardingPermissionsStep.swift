import SwiftUI

struct OnboardingPermissionsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: 6) {
                    Text("Permissions")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text("CC-Beeper works best with these permissions, but none are required.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.top, 24)

                // Accessibility row
                PermissionRow(
                    isGranted: viewModel.isAccessibilityGranted,
                    name: "Accessibility",
                    description: "Enables global hotkeys (Option+A/D) and text injection",
                    onGrant: {
                        viewModel.requestAccessibility()
                        viewModel.openAccessibilitySettings()
                    }
                )

                // Microphone row
                PermissionRow(
                    isGranted: viewModel.isMicGranted,
                    name: "Microphone",
                    description: "Enables voice input for talking to Claude",
                    onGrant: {
                        viewModel.requestMicrophone()
                        viewModel.openMicrophoneSettings()
                    }
                )

                // Speech Recognition row
                PermissionRow(
                    isGranted: viewModel.isSpeechGranted,
                    name: "Speech Recognition",
                    description: "Enables on-device speech-to-text (upgrading to Groq Whisper soon)",
                    onGrant: {
                        viewModel.requestSpeechRecognition()
                        viewModel.openSpeechSettings()
                    }
                )
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 8) {
                Button("Next") {
                    viewModel.goNext()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.allPermissionsGranted)

                Button("Skip") {
                    viewModel.goNext()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)

                Text("You can enable these later from the menu")
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.7))
            }
            .padding(.bottom, 24)
        }
        .onAppear {
            viewModel.startPolling()
        }
        .onDisappear {
            viewModel.stopPolling()
        }
    }
}

private struct PermissionRow: View {
    let isGranted: Bool
    let name: String
    let description: String
    let onGrant: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .fontWeight(.medium)
                    .font(.subheadline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if !isGranted {
                Button("Grant Access") {
                    onGrant()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}
