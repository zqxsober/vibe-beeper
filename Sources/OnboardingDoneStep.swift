import SwiftUI
import AppKit

struct OnboardingDoneStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            VStack(spacing: 12) {
                Text("You're All Set!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Restart Claude Code to activate hooks. CC-Beeper will appear in your menu bar and react to Claude's activity.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
            }

            // Important note
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.orange)
                Text("Important: Restart any running Claude Code sessions for hooks to take effect.")
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 32)

            Spacer()

            Button("Launch CC-Beeper") {
                viewModel.completeOnboarding()
                for window in NSApp.windows {
                    if window.identifier?.rawValue == "main" {
                        window.makeKeyAndOrderFront(nil)
                    }
                    if window.identifier?.rawValue == "onboarding" {
                        window.orderOut(nil)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 40)
    }
}
