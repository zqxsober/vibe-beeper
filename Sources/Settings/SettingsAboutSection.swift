import SwiftUI

struct SettingsAboutSection: View {
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    private let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    @StateObject private var updateChecker = InAppUpdateChecker()

    var body: some View {
        Section {
            VStack(spacing: 12) {
                if let appIcon = NSApp.applicationIconImage {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 80, height: 80)
                }

                Text("vibe-beeper")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Version \(version) (\(build))")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Text("A desktop companion for Claude Code and Codex.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Text("Not affiliated with or endorsed by Anthropic.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }

        Section("Updates") {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(updateStatusTitle)
                    Text(updateStatusDetail)
                        .font(.caption)
                        .foregroundStyle(updateStatusColor)
                }

                Spacer()

                if updateChecker.status == .checking {
                    ProgressView()
                        .controlSize(.small)
                }

                Button(updateButtonTitle) {
                    handleUpdateButton()
                }
                .disabled(updateChecker.status == .checking)
            }
        }

        Section {
            Link(destination: URL(string: "https://github.com/zqxsober/vibe-beeper")!) {
                Label("GitHub", systemImage: "link")
            }

            Link(destination: URL(string: "https://github.com/zqxsober/vibe-beeper/releases")!) {
                Label("Releases", systemImage: "arrow.down.circle")
            }

            Link(destination: URL(string: "https://github.com/zqxsober/vibe-beeper/issues")!) {
                Label("Report an Issue", systemImage: "exclamationmark.bubble")
            }
        }
    }

    private var updateButtonTitle: String {
        switch updateChecker.status {
        case .updateAvailable:
            return "Download Update..."
        case .checking:
            return "Checking..."
        default:
            return "Check for Updates"
        }
    }

    private var updateStatusTitle: String {
        switch updateChecker.status {
        case .updateAvailable(let version, _):
            return "Version \(version) is available"
        case .checking:
            return "Checking for updates"
        case .upToDate:
            return "vibe-beeper is up to date"
        case .failed:
            return "Update check failed"
        case .idle:
            return "Manual updates"
        }
    }

    private var updateStatusDetail: String {
        switch updateChecker.status {
        case .updateAvailable:
            return "Open GitHub Releases to download the latest DMG."
        case .checking:
            return "Contacting GitHub Releases..."
        case .upToDate(let version):
            return "Latest release: \(version)"
        case .failed(let message):
            return message
        case .idle:
            return "Check GitHub Releases for a newer version."
        }
    }

    private var updateStatusColor: Color {
        switch updateChecker.status {
        case .failed:
            return .red
        case .updateAvailable:
            return .green
        default:
            return .secondary
        }
    }

    private func handleUpdateButton() {
        if case .updateAvailable(_, let url) = updateChecker.status {
            NSWorkspace.shared.open(url)
        } else {
            updateChecker.checkForUpdates()
        }
    }
}
