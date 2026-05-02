import SwiftUI

struct SettingsThemeSection: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Group {
            Section("Widget Size") {
                VStack(alignment: .leading, spacing: 6) {
                    Picker("Widget Size", selection: $monitor.widgetSize) {
                        ForEach(WidgetSize.allCases, id: \.self) { size in
                            Text(size.label)
                                .tag(size)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(monitor.widgetSize.menuDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Shell Theme") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 14) {
                        if themeManager.isOldSchoolTheme {
                            OldSchoolSettingsPreview()
                                .frame(width: 132, height: 104)
                        } else {
                            Image(nsImage: loadShellPreview(themeManager.smallShellImageName))
                                .resizable()
                                .interpolation(.high)
                                .frame(width: 132, height: 68)
                                .padding(8)
                                .background(Color(.controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(themeManager.theme.displayName)
                                .font(.headline)
                            Text(themeSubtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }

                    ThemeDotsRow()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if themeManager.isOldSchoolTheme {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Old School Size")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Picker("Old School Size", selection: $themeManager.oldSchoolDisplaySize) {
                                ForEach(OldSchoolDisplaySize.allCases) { displaySize in
                                    Text(displaySize.label)
                                        .tag(displaySize)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var themeSubtitle: String {
        if themeManager.isOldSchoolTheme {
            return "retro Mac shell"
        }
        if themeManager.isAppleTheme {
            return "Classic Mac shell"
        }
        return "Original color shell"
    }

    private func loadShellPreview(_ name: String) -> NSImage {
        if let path = Bundle.main.resourcePath,
           let image = NSImage(contentsOfFile: path + "/" + name) {
            return image
        }
        return NSImage()
    }
}

private struct OldSchoolSettingsPreview: View {
    var body: some View {
        OldSchoolPreviewMachine()
        .padding(8)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
