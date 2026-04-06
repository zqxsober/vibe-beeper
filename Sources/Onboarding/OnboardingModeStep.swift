import SwiftUI

struct OnboardingModeStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private let presets: [PermissionPreset] = [.cautious, .relaxed, .trusted, .yolo]
    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        OnboardingShell(
            stepNumber: 4,
            totalSteps: OnboardingViewModel.totalCountedSteps,
            title: "How much should Claude do on its own?",
            subtitle: "Controls when CC-Beeper asks you before acting. Easy to change later.",
            primaryLabel: "Next",
            primaryAction: { viewModel.goNext() },
            skipLabel: nil,
            skipAction: nil,
            onBack: { viewModel.goBack() }
        ) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(presets, id: \.self) { preset in
                    PresetCard(
                        preset: preset,
                        isSelected: viewModel.selectedPreset == preset,
                        onSelect: { viewModel.selectedPreset = preset }
                    )
                }
            }
            .frame(maxWidth: 460)
            .animation(.easeInOut(duration: 0.15), value: viewModel.selectedPreset)
        }
    }
}

private struct PresetCard: View {
    let preset: PermissionPreset
    let isSelected: Bool
    let onSelect: () -> Void

    private var shortDescription: String {
        switch preset {
        case .cautious: "Ask me every time."
        case .relaxed: "Reads are fine. Ask for writes."
        case .trusted: "Auto file ops. Ask for bash."
        case .yolo: "Don't ask. Just do it."
        }
    }

    private var accentColor: Color {
        switch preset {
        case .cautious: return ClaudeTheme.green
        case .relaxed: return ClaudeTheme.stone
        case .trusted: return ClaudeTheme.amber
        case .yolo: return ClaudeTheme.crimson
        }
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: preset.badgeIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(accentColor)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.label.uppercased())
                        .font(ClaudeTheme.mono(11, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(ClaudeTheme.nearBlack)
                    Text(shortDescription)
                        .font(ClaudeTheme.sans(11))
                        .foregroundStyle(ClaudeTheme.stone)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: ClaudeTheme.radiusMedium, style: .continuous)
                    .fill(isSelected ? Color(hex: "FBF7F4") : ClaudeTheme.ivory)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ClaudeTheme.radiusMedium, style: .continuous)
                    .strokeBorder(isSelected ? ClaudeTheme.terracotta : ClaudeTheme.borderCream, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
