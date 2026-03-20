import SwiftUI

struct ActivityFeedView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        let activities = monitor.currentSessionActivities

        VStack(spacing: 0) {
            // Summary section — only shown when summary exists or is loading
            if monitor.isSummarizing {
                HStack(spacing: 4) {
                    ProgressView()
                        .controlSize(.mini)
                        .scaleEffect(0.5)
                    Text("SUMMARIZING...")
                        .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(themeManager.lcdOn.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(themeManager.lcdOn.opacity(0.03))
            } else if let summary = monitor.sessionSummary {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SESSION RECAP")
                        .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(themeManager.lcdOn.opacity(0.3))

                    Text(summary)
                        .font(.system(size: 7, weight: .medium, design: .monospaced))
                        .foregroundStyle(themeManager.lcdOn.opacity(0.6))
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(themeManager.lcdOn.opacity(0.03))
            }

            // Divider between summary and feed (only if summary is shown)
            if monitor.sessionSummary != nil || monitor.isSummarizing {
                Rectangle()
                    .fill(themeManager.lcdOn.opacity(0.08))
                    .frame(height: 0.5)
            }

            // Existing feed content — unchanged logic
            if activities.isEmpty && monitor.sessionSummary == nil && !monitor.isSummarizing {
                Text("NO ACTIVITY")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(themeManager.lcdOn.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            } else if !activities.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .leading, spacing: 1) {
                            ForEach(activities.suffix(50)) { entry in
                                ActivityRowView(entry: entry)
                                    .id(entry.id)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: activities.count) {
                        if let last = activities.last {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ActivityRowView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let entry: ActivityEntry

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            // Tool icon
            Image(systemName: iconForTool(entry.tool))
                .font(.system(size: 6, weight: .bold))
                .foregroundStyle(entry.isError
                    ? Color.red.opacity(0.7)
                    : themeManager.lcdOn.opacity(0.5))
                .frame(width: 8)

            // Summary text
            Text(entry.summary.isEmpty ? entry.tool.lowercased() : entry.summary)
                .font(.system(size: 6.5, weight: .medium, design: .monospaced))
                .foregroundStyle(entry.isError
                    ? Color.red.opacity(0.6)
                    : themeManager.lcdOn.opacity(0.45))
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 0)

            // Relative timestamp
            Text(relativeTime(entry.timestamp))
                .font(.system(size: 5.5, weight: .regular, design: .monospaced))
                .foregroundStyle(themeManager.lcdOn.opacity(0.25))
        }
        .frame(height: 10)
    }

    private func iconForTool(_ tool: String) -> String {
        switch tool {
        case "Bash": return "terminal"
        case "Write": return "pencil"
        case "Read": return "doc.text"
        case "Edit": return "pencil.line"
        case "Grep": return "magnifyingglass"
        case "Glob": return "folder"
        case "Agent": return "person.2"
        case "WebFetch": return "globe"
        default: return "wrench"
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 5 { return "now" }
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h"
    }
}
