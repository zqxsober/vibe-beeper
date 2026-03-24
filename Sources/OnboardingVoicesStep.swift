import SwiftUI

struct OnboardingVoicesStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "waveform.circle")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.accentColor)

                VStack(spacing: 12) {
                    Text("Download Premium Voices")
                        .font(.headline)

                    Text("CC-Beeper can read Claude's responses aloud. For the best experience, download a premium voice like Ava (Premium) from System Settings.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 32)
                }

                Button("Open Spoken Content Settings") {
                    viewModel.openSpokenContent()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Text("System Settings > Accessibility > Spoken Content > System Voice > Manage Voices")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
            }

            Button("Next") {
                viewModel.goNext()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 40)
    }
}
