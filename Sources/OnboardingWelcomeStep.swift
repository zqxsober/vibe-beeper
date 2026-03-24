import SwiftUI

struct OnboardingWelcomeStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)

            VStack(spacing: 12) {
                Text("Welcome to CC-Beeper")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Your desktop companion for Claude Code. See what Claude is doing, respond to permissions, and talk to it — all without leaving your workflow.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button("Get Started") {
                viewModel.goNext()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 40)
    }
}
