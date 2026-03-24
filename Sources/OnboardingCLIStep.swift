import SwiftUI

struct OnboardingCLIStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Claude Code Setup")
                    .font(.headline)
                    .padding(.top, 32)
                    .frame(maxWidth: .infinity, alignment: .center)

                // Claude CLI detection row
                HStack(spacing: 12) {
                    if viewModel.isClaudeDetected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title2)
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.title2)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Claude Code CLI")
                            .fontWeight(.medium)
                        if viewModel.isClaudeDetected {
                            Text("Detected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            HStack(spacing: 4) {
                                Text("Not found —")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Link("Install Claude Code", destination: URL(string: "https://docs.anthropic.com/en/docs/claude-code/overview")!)
                                    .font(.caption)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 40)

                // Hooks installation row
                HStack(spacing: 12) {
                    if viewModel.isHooksInstalled {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title2)
                    } else {
                        Image(systemName: "circle")
                            .foregroundStyle(viewModel.isClaudeDetected ? Color.secondary : Color.secondary.opacity(0.4))
                            .font(.title2)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hooks")
                            .fontWeight(.medium)
                            .foregroundStyle(viewModel.isClaudeDetected ? .primary : .secondary)
                        if viewModel.isHooksInstalled {
                            Text("Installed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if viewModel.isClaudeDetected {
                            Text("Not installed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Requires Claude Code")
                                .font(.caption)
                                .foregroundStyle(.secondary.opacity(0.6))
                        }
                    }

                    Spacer()

                    if !viewModel.isHooksInstalled && viewModel.isClaudeDetected {
                        Button("Install Hooks") {
                            viewModel.installHooks()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.horizontal, 40)

                if let error = viewModel.hookInstallError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 40)
                }
            }

            Spacer()

            VStack(spacing: 8) {
                Button("Next") {
                    viewModel.goNext()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.isClaudeDetected)

                Button("Skip") {
                    viewModel.goNext()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)

                Text("You can set this up later from the menu")
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.7))
            }
            .padding(.bottom, 24)
        }
        .onAppear {
            viewModel.detectClaude()
        }
    }
}
