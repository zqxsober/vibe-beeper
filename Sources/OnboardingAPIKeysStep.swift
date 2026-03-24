import SwiftUI

struct OnboardingAPIKeysStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    @State private var groqKey: String = ""
    @State private var openAIKey: String = ""

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "key.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.accentColor)

                VStack(spacing: 12) {
                    Text("Upgrade Your Voice")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Optionally add API keys for higher-quality transcription and speech. This is free to skip — on-device voice works great.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 32)
                }

                VStack(spacing: 12) {
                    LabeledContent("Groq (Transcription)") {
                        SecureField("sk-...", text: $groqKey)
                            .textFieldStyle(.roundedBorder)
                    }

                    LabeledContent("OpenAI (Voice)") {
                        SecureField("sk-...", text: $openAIKey)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
            }

            HStack(spacing: 16) {
                Button("Skip") {
                    viewModel.goNext()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button("Save & Continue") {
                    saveKeys()
                    viewModel.goNext()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 40)
        .onAppear {
            // Load existing keys so user can see/edit them if they revisit
            groqKey = KeychainService.load(account: KeychainService.groqAccount) ?? ""
            openAIKey = KeychainService.load(account: KeychainService.openAIAccount) ?? ""
        }
    }

    private func saveKeys() {
        KeychainService.save(groqKey, account: KeychainService.groqAccount)
        KeychainService.save(openAIKey, account: KeychainService.openAIAccount)
    }
}
