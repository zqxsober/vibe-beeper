import SwiftUI

struct OnboardingModelDownloadStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.accentColor)

                VStack(spacing: 12) {
                    Text("Download Voice Model")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("CC-Beeper uses an on-device AI model for speech recognition. No internet needed after download.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 32)
                }

                if viewModel.isModelReady {
                    Label("Model Ready", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.headline)
                } else if viewModel.isModelDownloading {
                    VStack(spacing: 8) {
                        ProgressView(value: viewModel.modelDownloadProgress)
                            .progressViewStyle(.linear)
                            .padding(.horizontal, 40)

                        Text(viewModel.modelDownloadPhase)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button("Download (~600 MB)") {
                        viewModel.downloadParakeetModel()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    if !viewModel.modelDownloadPhase.isEmpty {
                        Text(viewModel.modelDownloadPhase)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            HStack(spacing: 16) {
                Button("Skip") {
                    viewModel.goNext()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                if viewModel.isModelReady {
                    Button("Continue") {
                        viewModel.goNext()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 40)
        .onAppear {
            // Auto-start download if not already downloaded
            if !viewModel.isModelReady && !viewModel.isModelDownloading {
                viewModel.downloadParakeetModel()
            }
        }
    }
}
