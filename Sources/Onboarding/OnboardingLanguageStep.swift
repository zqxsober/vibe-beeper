import SwiftUI

struct OnboardingLanguageStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private var sortedLangCodes: [(code: String, name: String)] {
        KokoroVoiceCatalog.languageNames
            .map { (code: $0.key, name: $0.value) }
            .sorted { a, b in
                if a.code == "a" { return true }
                if b.code == "a" { return false }
                return a.name < b.name
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "globe")
                    .font(.system(size: 48))
                    .foregroundStyle(.primary)

                VStack(spacing: 8) {
                    Text("Language")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Choose the language for voice recording and read-over.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Picker("Language", selection: $viewModel.selectedLangCode) {
                    ForEach(sortedLangCodes, id: \.code) { lang in
                        Text(lang.name).tag(lang.code)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 240)

                Text("You can change the voice in Settings later.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                // Dep install section for Japanese/Chinese
                if viewModel.needsLangDeps && !viewModel.langDepsReady {
                    VStack(spacing: 8) {
                        if viewModel.depsInstaller.isInstalling {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text(viewModel.depsInstaller.installProgress)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        } else {
                            let langName = KokoroVoiceCatalog.languageNames[viewModel.selectedLangCode] ?? "This language"
                            let sizeHint = viewModel.selectedLangCode == "j" ? " (~500 MB)" : " (~45 MB)"
                            Text("\(langName) requires additional dependencies\(sizeHint).")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Button("Install Dependencies") {
                                viewModel.installLangDeps()
                            }
                            .buttonStyle(.bordered)

                            if let error = viewModel.depsInstaller.installError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding(14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 48)
                }

                Spacer()
            }

            OnboardingFooter(
                primaryLabel: "Continue",
                primaryAction: {
                    viewModel.applyLanguageChoice()
                    viewModel.goNext()
                }
            )
        }
        .padding(.horizontal, 48)
    }
}
