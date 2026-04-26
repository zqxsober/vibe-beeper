import SwiftUI

struct SettingsThemeSection: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Section("Shell Theme") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    Image(nsImage: loadShellPreview(themeManager.smallShellImageName))
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 132, height: 68)
                        .padding(8)
                        .background(Color(.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(themeManager.theme.displayName)
                            .font(.headline)
                        Text(themeManager.isAppleTheme ? "Classic Mac shell" : "Original color shell")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }

                ThemeDotsRow()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 4)
        }
    }

    private func loadShellPreview(_ name: String) -> NSImage {
        if let path = Bundle.main.resourcePath,
           let image = NSImage(contentsOfFile: path + "/" + name) {
            return image
        }
        return NSImage()
    }
}
