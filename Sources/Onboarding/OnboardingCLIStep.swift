import SwiftUI

struct OnboardingCLIStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingShell(
            stepNumber: 1,
            totalSteps: OnboardingViewModel.totalCountedSteps,
            title: "Connect supported CLIs",
            subtitle: "vibe-beeper can connect to Claude Code and Codex. You can enable each CLI now or revisit setup later.",
            primaryLabel: "Next",
            primaryAction: handlePrimary,
            skipLabel: "Skip",
            skipAction: { viewModel.goNext() },
            onBack: { viewModel.goBack() }
        ) {
            VStack(spacing: 14) {
                ProviderConfigCard(
                    title: ProviderKind.claude.displayName,
                    path: "~/.claude/settings.json",
                    status: claudeStatus
                )

                ProviderConfigCard(
                    title: ProviderKind.codex.displayName,
                    path: "~/.codex/hooks.json",
                    status: codexStatus
                )

                if !viewModel.isClaudeDetected {
                    HStack(spacing: 4) {
                        Text("Claude Code CLI not found.")
                            .foregroundStyle(OnboardingTheme.stone)
                        Link("Install it", destination: URL(string: "https://docs.anthropic.com/en/docs/claude-code/overview")!)
                            .foregroundStyle(OnboardingTheme.terracotta)
                    }
                    .font(OnboardingTheme.sans(12))
                }

                if !viewModel.isCodexDetected {
                    HStack(spacing: 4) {
                        Text("Codex CLI not found.")
                            .foregroundStyle(OnboardingTheme.stone)
                        Link("Install it", destination: URL(string: "https://developers.openai.com/codex")!)
                            .foregroundStyle(OnboardingTheme.terracotta)
                    }
                    .font(OnboardingTheme.sans(12))
                }

                if let error = viewModel.setupErrorMessage {
                    Text(error)
                        .font(OnboardingTheme.sans(11))
                        .foregroundStyle(OnboardingTheme.crimson)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                }
            }
        }
        .onAppear { viewModel.detectProviders() }
    }

    private var claudeStatus: ProviderConfigCard.Status {
        if !viewModel.isClaudeDetected { return .notFound }
        return viewModel.isClaudeHooksInstalled ? .installed : .pending
    }

    private var codexStatus: ProviderConfigCard.Status {
        if !viewModel.isCodexDetected { return .notFound }
        return viewModel.isCodexHooksInstalled ? .installed : .pending
    }

    private func handlePrimary() {
        // If we can install, try it; only advance on success.
        if viewModel.isClaudeDetected && !viewModel.isClaudeHooksInstalled {
            viewModel.installClaudeHooks()
            if viewModel.setupErrorMessage == nil {
                handlePrimary()
            }
            return
        }
        if viewModel.isCodexDetected && !viewModel.isCodexHooksInstalled {
            viewModel.installCodexHooks()
            if viewModel.setupErrorMessage == nil {
                viewModel.goNext()
            }
            return
        }
        viewModel.goNext()
    }
}

// MARK: - Settings.json card

struct ProviderConfigCard: View {
    enum Status { case pending, installed, notFound }
    let title: String
    let path: String
    let status: Status

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(OnboardingTheme.sans(13, weight: .semibold))
                    .foregroundStyle(OnboardingTheme.nearBlack)
                Text(path)
                    .font(OnboardingTheme.mono(11))
                    .foregroundStyle(OnboardingTheme.stone)
            }
            Spacer(minLength: 16)
            badge
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(minWidth: 340)
        .onboardingCard(radius: OnboardingTheme.radiusMedium)
    }

    @ViewBuilder private var badge: some View {
        switch status {
        case .pending:
            badgePill(text: "Pending", color: OnboardingTheme.amber)
        case .installed:
            badgePill(text: "Installed", color: OnboardingTheme.green)
        case .notFound:
            badgePill(text: "Not Found", color: OnboardingTheme.amber)
        }
    }

    private func badgePill(text: String, color: Color) -> some View {
        Text(text.uppercased())
            .font(OnboardingTheme.mono(10, weight: .semibold))
            .tracking(0.5)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(color.opacity(0.12))
            )
    }
}

typealias SettingsJsonCard = ProviderConfigCard

// MARK: - Legacy components (still used by remaining pre-migration step files)

struct SetupRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    var link: (String, URL)? = nil
    var action: (String, () -> Void)? = nil

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.system(size: 20))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(OnboardingTheme.sans(13, weight: .medium))
                    .foregroundStyle(OnboardingTheme.nearBlack)
                if let subtitle {
                    Text(subtitle)
                        .font(OnboardingTheme.sans(11))
                        .foregroundStyle(OnboardingTheme.stone)
                }
                if let link {
                    Link(link.0, destination: link.1)
                        .font(OnboardingTheme.sans(11))
                        .foregroundStyle(OnboardingTheme.terracotta)
                }
            }

            Spacer()

            if let action {
                Button(action.0) { action.1() }
                    .buttonStyle(.bordered)
                    .tint(OnboardingTheme.terracotta)
                    .controlSize(.small)
            }
        }
        .padding(14)
        .onboardingCard(radius: OnboardingTheme.radiusMedium)
    }
}

struct OnboardingFooter: View {
    let primaryLabel: String
    let primaryAction: () -> Void
    var primaryDisabled: Bool = false
    var showSkip: Bool = false
    var skipAction: (() -> Void)? = nil
    var backAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 10) {
            Button {
                primaryAction()
            } label: {
                Text(primaryLabel)
                    .font(OnboardingTheme.sans(14, weight: .semibold))
                    .foregroundStyle(OnboardingTheme.ivory)
                    .frame(maxWidth: 240)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: OnboardingTheme.radiusMedium, style: .continuous)
                            .fill(primaryDisabled ? OnboardingTheme.warmSilver : OnboardingTheme.terracotta)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(primaryDisabled)

            HStack(spacing: 18) {
                if let backAction {
                    Button {
                        backAction()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Back")
                        }
                        .font(OnboardingTheme.sans(11))
                        .foregroundStyle(OnboardingTheme.stone)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                if showSkip, let skipAction {
                    Button {
                        skipAction()
                    } label: {
                        Text("Skip")
                            .font(OnboardingTheme.sans(11))
                            .foregroundStyle(OnboardingTheme.stone)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 18)
        }
        .padding(.bottom, 36)
    }
}
