import SwiftUI

struct AboutWindow: View {
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    private let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"

    var body: some View {
        VStack(spacing: 16) {
            // Icon
            if let appIcon = NSApp.applicationIconImage {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 96, height: 96)
            }

            // Name & version
            VStack(spacing: 4) {
                Text("vibe-beeper")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Version \(version) (\(build))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            // Tagline
            Text("A desktop companion for Claude Code and Codex.")
                .font(.body)
                .foregroundStyle(.secondary)

            Divider()
                .padding(.horizontal, 40)

            // Links
            VStack(spacing: 8) {
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
            .font(.callout)

            Spacer()
                .frame(height: 4)

            Text("\u{00A9} 2026 zqxsober")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(width: 320, height: 400)
    }
}
