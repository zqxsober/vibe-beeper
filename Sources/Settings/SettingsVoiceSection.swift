import SwiftUI

struct SettingsVoiceSection: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0
    @State private var downloadLabel: String = ""
    @State private var downloadError: String?

    var body: some View {
        Section("Voice Commands") {
            Toggle(isOn: $monitor.clapDictationEnabled) {
                Label("Double Clap Dictation", systemImage: "hands.sparkles.fill")
            }

            if monitor.clapDictationEnabled {
                Text("Double clap to start dictating, double clap again to stop and send. Microphone is always on while this is enabled.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 2)
            }
        }

        Section("Speech Recognition") {
            HStack {
                Label("STT Engine", systemImage: "waveform.and.mic")
                Spacer()
                Text(monitor.voiceService.sttEngineLabel)
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }

            Picker("Whisper Model", selection: $monitor.whisperModelSize) {
                Text("Small (~500 MB) — Recommended").tag("small")
                Text("Medium (~1.5 GB) — Higher accuracy").tag("medium")
            }
            .pickerStyle(.menu)

            if !WhisperService.isModelDownloaded(size: WhisperModelSize(rawValue: monitor.whisperModelSize) ?? .small) {
                if isDownloading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text(downloadLabel.isEmpty ? "Downloading..." : downloadLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button {
                        let size = WhisperModelSize(rawValue: monitor.whisperModelSize) ?? .small
                        isDownloading = true
                        downloadError = nil
                        Task {
                            do {
                                try await WhisperService.shared.downloadModel(size: size) { progress, label in
                                    Task { @MainActor in
                                        downloadProgress = progress
                                        downloadLabel = label
                                    }
                                }
                                await MainActor.run {
                                    isDownloading = false
                                }
                            } catch {
                                await MainActor.run {
                                    isDownloading = false
                                    downloadError = "[v2] \(error)"
                                }
                            }
                        }
                    } label: {
                        Label("Download Model", systemImage: "arrow.down.circle")
                    }
                }

                if let error = downloadError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }
}
