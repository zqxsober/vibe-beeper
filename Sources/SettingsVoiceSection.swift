import SwiftUI

struct SettingsVoiceSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    @State private var groqKey: String = ""
    @State private var openAIKey: String = ""

    var body: some View {
        Button("Download Voices...") {
            viewModel.openSpokenContent()
        }
        .buttonStyle(.link)

        Text("Download premium voices like Ava (Premium) for better speech output.")
            .font(.caption)
            .foregroundStyle(.secondary)

        Divider()

        LabeledContent("Groq (Transcription)") {
            SecureField("sk-...", text: $groqKey)
                .onSubmit { KeychainService.save(groqKey, account: KeychainService.groqAccount) }
                .textFieldStyle(.roundedBorder)
        }

        LabeledContent("OpenAI (Voice)") {
            SecureField("sk-...", text: $openAIKey)
                .onSubmit { KeychainService.save(openAIKey, account: KeychainService.openAIAccount) }
                .textFieldStyle(.roundedBorder)
        }

        Text("API Keys (Optional). When set, voice input uses Groq Whisper and speech uses OpenAI TTS for higher quality. Keys are stored securely in your Keychain.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .onAppear {
                groqKey = KeychainService.load(account: KeychainService.groqAccount) ?? ""
                openAIKey = KeychainService.load(account: KeychainService.openAIAccount) ?? ""
            }
    }
}
