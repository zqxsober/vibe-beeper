import SwiftUI

struct SettingsVoiceSection: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @StateObject private var depsInstaller = KokoroDepsInstaller()
    @State private var depsReady: Bool = true

    /// Voices filtered to current language code
    private var currentVoices: [KokoroVoiceCatalog.Voice] {
        KokoroVoiceCatalog.voicesByLang[monitor.kokoroLangCode] ?? KokoroVoiceCatalog.voicesByLang["a"]!
    }

    /// Sorted language codes for the picker (English US first, then alphabetical by name)
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
        Section("TTS Provider") {
            Picker("Provider", selection: $monitor.ttsProvider) {
                Text("Kokoro (local)").tag("kokoro")
                Text("Apple").tag("apple")
            }
            .pickerStyle(.menu)
        }

        if monitor.ttsProvider == "kokoro" {
            Section("Language") {
                Picker("Language", selection: $monitor.kokoroLangCode) {
                    ForEach(sortedLangCodes, id: \.code) { lang in
                        Text(lang.name).tag(lang.code)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: monitor.kokoroLangCode) { _, newLang in
                    checkDeps(for: newLang)
                }
            }

            // Dep install section — only for Japanese/Chinese when deps missing
            if KokoroVoiceCatalog.langCodesRequiringDeps.contains(monitor.kokoroLangCode) && !depsReady {
                Section {
                    if depsInstaller.isInstalling {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text(depsInstaller.installProgress)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            let langName = KokoroVoiceCatalog.languageNames[monitor.kokoroLangCode] ?? "this language"
                            let sizeHint = monitor.kokoroLangCode == "j" ? " (~500 MB)" : " (~45 MB)"
                            Text("\(langName) requires additional dependencies\(sizeHint).")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Button("Install Dependencies") {
                                Task {
                                    let success = await depsInstaller.installDeps(for: monitor.kokoroLangCode)
                                    depsReady = success
                                }
                            }

                            if let error = depsInstaller.installError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }

            Section("Kokoro Voice") {
                HStack {
                    Picker("Voice", selection: $monitor.kokoroVoice) {
                        ForEach(currentVoices, id: \.id) { voice in
                            Text("\(voice.gender) — \(voice.label)").tag(voice.id)
                        }
                    }
                    .pickerStyle(.menu)

                    Button {
                        monitor.ttsService.stopSpeaking()
                        Task {
                            await monitor.ttsService.speakSummary(
                                "Hello, I'm \(monitor.kokoroVoice). This is how I sound.",
                                provider: "kokoro"
                            )
                        }
                    } label: {
                        Image(systemName: "play.circle")
                    }
                    .buttonStyle(.plain)
                    .help("Preview voice")
                }
            }
        }
    }

    private func checkDeps(for langCode: String) {
        guard KokoroVoiceCatalog.langCodesRequiringDeps.contains(langCode) else {
            depsReady = true
            return
        }
        Task {
            depsReady = await depsInstaller.areDepsInstalled(for: langCode)
        }
    }
}
