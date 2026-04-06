import SwiftUI

struct OnboardingVoiceStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private var isKokoroSelected: Bool { viewModel.ttsProvider == "kokoro" }

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
        OnboardingShell(
            stepNumber: 6,
            totalSteps: OnboardingViewModel.totalCountedSteps,
            title: "Download the voice engine?",
            subtitle: "Kokoro runs on-device (~930 MB). Skip to use Apple Speech instead.",
            primaryLabel: "Next",
            primaryAction: { viewModel.goNext() },
            primaryDisabled: isKokoroSelected && !viewModel.isModelReady,
            skipLabel: viewModel.isModelReady ? nil : "Skip",
            skipAction: viewModel.isModelReady ? nil : { viewModel.ttsProvider = "apple"; viewModel.goNext() },
            onBack: { viewModel.goBack() }
        ) {
            VStack(spacing: 10) {
                // Kokoro card
                Button { viewModel.ttsProvider = "kokoro" } label: {
                    KokoroCardContent(viewModel: viewModel)
                        .voiceCardStyle(isSelected: isKokoroSelected)
                }
                .buttonStyle(.plain)

                // Apple Speech card
                Button { viewModel.ttsProvider = "apple" } label: {
                    HStack(spacing: 12) {
                        voiceIcon(symbol: "applelogo", color: ClaudeTheme.stone)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Apple Speech")
                                .font(ClaudeTheme.sans(13, weight: .semibold))
                                .foregroundStyle(ClaudeTheme.nearBlack)
                            Text("No download · Built-in macOS speech")
                                .font(ClaudeTheme.sans(11))
                                .foregroundStyle(ClaudeTheme.stone)
                        }
                        Spacer()
                    }
                    .voiceCardStyle(isSelected: !isKokoroSelected)
                }
                .buttonStyle(.plain)

                // Language picker
                if isKokoroSelected {
                    LanguagePicker(viewModel: viewModel, sortedLangCodes: sortedLangCodes)
                        .padding(.top, 4)

                    if viewModel.needsLangDeps && !viewModel.langDepsReady {
                        LangDepsCard(viewModel: viewModel)
                    }
                }
            }
            .frame(maxWidth: 460)
        }
    }

    private func voiceIcon(symbol: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(ClaudeTheme.parchment)
                .frame(width: 34, height: 34)
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Card style modifier

private struct VoiceCardStyleModifier: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: ClaudeTheme.radiusMedium, style: .continuous)
                    .fill(isSelected ? Color(hex: "FBF7F4") : ClaudeTheme.ivory)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ClaudeTheme.radiusMedium, style: .continuous)
                    .strokeBorder(isSelected ? ClaudeTheme.terracotta : ClaudeTheme.borderCream, lineWidth: isSelected ? 1.5 : 1)
            )
    }
}

private extension View {
    func voiceCardStyle(isSelected: Bool) -> some View {
        modifier(VoiceCardStyleModifier(isSelected: isSelected))
    }
}

// MARK: - Kokoro card content (handles download states)

private struct KokoroCardContent: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(ClaudeTheme.parchment)
                    .frame(width: 34, height: 34)
                Image(systemName: "waveform")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(ClaudeTheme.terracotta)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Kokoro · On-device")
                    .font(ClaudeTheme.sans(13, weight: .semibold))
                    .foregroundStyle(ClaudeTheme.nearBlack)
                if viewModel.isModelDownloading {
                    Text(viewModel.modelDownloadPhase)
                        .font(ClaudeTheme.sans(11))
                        .foregroundStyle(ClaudeTheme.stone)
                        .lineLimit(1)
                } else if viewModel.isModelReady {
                    Text("~930 MB · Ready")
                        .font(ClaudeTheme.sans(11))
                        .foregroundStyle(ClaudeTheme.green)
                } else {
                    Text("~930 MB · No API keys · Best quality")
                        .font(ClaudeTheme.sans(11))
                        .foregroundStyle(ClaudeTheme.stone)
                }
            }

            Spacer()

            if viewModel.isModelReady {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(ClaudeTheme.green)
            } else if viewModel.isModelDownloading {
                Text("\(Int(viewModel.modelDownloadProgress * 100))%")
                    .font(ClaudeTheme.mono(11, weight: .semibold))
                    .foregroundStyle(ClaudeTheme.terracotta)
            } else {
                Button(action: { viewModel.downloadModels() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Download")
                    }
                    .font(ClaudeTheme.sans(12, weight: .semibold))
                    .foregroundStyle(ClaudeTheme.nearBlack)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(ClaudeTheme.ivory))
                    .overlay(Capsule().strokeBorder(ClaudeTheme.ringWarm, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(alignment: .bottom) {
            if viewModel.isModelDownloading {
                GeometryReader { geo in
                    Capsule()
                        .fill(ClaudeTheme.terracotta)
                        .frame(width: geo.size.width * viewModel.modelDownloadProgress, height: 2)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.modelDownloadProgress)
                }
                .frame(height: 2)
            }
        }
    }
}

// MARK: - Language picker

private struct LanguagePicker: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let sortedLangCodes: [(code: String, name: String)]

    var body: some View {
        HStack(spacing: 10) {
            Text("Kokoro language")
                .font(ClaudeTheme.sans(12))
                .foregroundStyle(ClaudeTheme.stone)
            Spacer()
            Picker("", selection: $viewModel.selectedLangCode) {
                ForEach(sortedLangCodes, id: \.code) { lang in
                    Text(lang.name).tag(lang.code)
                }
            }
            .pickerStyle(.menu)
            .colorScheme(.light)
            .frame(maxWidth: 180)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Language dependencies

private struct LangDepsCard: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 8) {
            if viewModel.depsInstaller.isInstalling {
                HStack {
                    ProgressView().scaleEffect(0.7)
                    Text(viewModel.depsInstaller.installProgress)
                        .font(ClaudeTheme.sans(11))
                        .foregroundStyle(ClaudeTheme.stone)
                        .lineLimit(1)
                }
            } else {
                let langName = KokoroVoiceCatalog.languageNames[viewModel.selectedLangCode] ?? "This language"
                let sizeHint = viewModel.selectedLangCode == "j" ? " (~500 MB)" : " (~45 MB)"
                Text("\(langName) needs extra dependencies\(sizeHint).")
                    .font(ClaudeTheme.sans(11))
                    .foregroundStyle(ClaudeTheme.stone)

                Button("Install") { viewModel.installLangDeps() }
                    .buttonStyle(.bordered)
                    .tint(ClaudeTheme.terracotta)
                    .controlSize(.small)

                if let error = viewModel.depsInstaller.installError {
                    Text(error)
                        .font(ClaudeTheme.sans(11))
                        .foregroundStyle(ClaudeTheme.crimson)
                }
            }
        }
        .padding(12)
        .claudeCard(radius: ClaudeTheme.radiusMedium)
    }
}
