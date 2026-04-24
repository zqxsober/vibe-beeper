import SwiftUI

struct SettingsSetupSection: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var viewModel: SettingsViewModel
    @State private var showUninstallConfirmation = false

    var body: some View {
        Section("CLI Integrations") {
            ProviderSetupRow(
                title: ProviderKind.claude.displayName,
                isDetected: viewModel.isClaudeDetected,
                isInstalled: viewModel.isClaudeHooksInstalled
            )

            ProviderSetupRow(
                title: ProviderKind.codex.displayName,
                isDetected: viewModel.isCodexDetected,
                isInstalled: viewModel.isCodexHooksInstalled
            )

            Button("Install Missing Integrations") {
                viewModel.installMissingIntegrations()
            }

            Button("Refresh Integration Status") {
                viewModel.detectProviders()
            }

            if let error = viewModel.setupErrorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }

        Section("Setup Wizard") {
            Button("Run Setup Wizard...") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "onboarding")
            }

            Text("Re-run to install hooks, grant permissions, or download voice models.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Section("Uninstall") {
            Button("Uninstall vibe-beeper...", role: .destructive) {
                showUninstallConfirmation = true
            }

            Text("Removes the app, hooks, cached models, and configuration files.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .confirmationDialog(
            "Uninstall vibe-beeper?",
            isPresented: $showUninstallConfirmation,
            titleVisibility: .visible
        ) {
            Button("Uninstall", role: .destructive) {
                performUninstall()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove vibe-beeper, its hooks, cached voice models, and configuration. This cannot be undone.")
        }
    }

    private func performUninstall() {
        let path = Bundle.main.url(forResource: "uninstall", withExtension: "py")?.path
            ?? Bundle.main.bundlePath
                .replacingOccurrences(of: "/vibe-beeper.app", with: "/uninstall.py")
                .replacingOccurrences(of: "/CC-Beeper.app", with: "/uninstall.py")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [path]
        try? process.run()
        process.waitUntilExit()
        NSApp.terminate(nil)
    }
}

private struct ProviderSetupRow: View {
    let title: String
    let isDetected: Bool
    let isInstalled: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(isDetected ? "CLI detected" : "CLI not found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(statusText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(statusColor)
        }
    }

    private var statusText: String {
        if !isDetected { return "Not Found" }
        return isInstalled ? "Installed" : "Pending"
    }

    private var statusColor: Color {
        if !isDetected { return .orange }
        return isInstalled ? .green : .secondary
    }
}
