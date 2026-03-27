import SwiftUI

struct SettingsAudioSection: View {
    @EnvironmentObject var monitor: ClaudeMonitor

    private let pocketttsVoices: [(id: String, label: String)] = [
        ("alba", "Alba"),
        ("anna", "Anna"),
        ("azelma", "Azelma"),
        ("bill_boerst", "Bill Boerst"),
        ("caro_davy", "Caro Davy"),
        ("charles", "Charles"),
        ("cosette", "Cosette"),
        ("eponine", "Eponine"),
        ("eve", "Eve"),
        ("fantine", "Fantine"),
        ("george", "George"),
        ("jane", "Jane"),
        ("javert", "Javert"),
        ("jean", "Jean"),
        ("marius", "Marius"),
        ("mary", "Mary"),
        ("michael", "Michael"),
        ("paul", "Paul"),
        ("peter_yearsley", "Peter Yearsley"),
        ("stuart_bell", "Stuart Bell"),
        ("vera", "Vera"),
    ]

    var body: some View {
        Toggle(isOn: $monitor.voiceOver) {
            Label("VoiceOver", systemImage: "speaker.wave.2.fill")
        }
        .toggleStyle(.switch)

        HStack {
            Label("STT Engine", systemImage: "waveform.and.mic")
            Spacer()
            Text(monitor.voiceService.sttEngineLabel)
                .foregroundStyle(.secondary)
                .font(.caption)
        }

        Picker("TTS Provider", selection: $monitor.ttsProvider) {
            Text("PocketTTS (local)").tag("pockettts")
            Text("Apple").tag("apple")
        }
        .pickerStyle(.menu)

        HStack {
            Label("TTS Engine", systemImage: "speaker.wave.2")
            Spacer()
            Text(PocketTTSService.modelsDownloaded ? "PocketTTS (local)" : "Apple Ava (fallback)")
                .foregroundStyle(.secondary)
                .font(.caption)
        }

        if monitor.ttsProvider == "pockettts" {
            Picker("Voice", selection: $monitor.pocketttsVoice) {
                ForEach(pocketttsVoices, id: \.id) { voice in
                    Text(voice.label).tag(voice.id)
                }
            }
            .pickerStyle(.menu)
        }

        Toggle(isOn: $monitor.vibrationEnabled) {
            Label("Vibration", systemImage: "waveform")
        }
        .toggleStyle(.switch)

        Toggle(isOn: $monitor.soundEnabled) {
            Label("Sound Effects", systemImage: "speaker.fill")
        }
        .toggleStyle(.switch)
    }
}
