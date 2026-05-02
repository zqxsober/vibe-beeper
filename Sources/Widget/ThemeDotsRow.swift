import SwiftUI

struct ThemeDotsRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    private let columns = [
        GridItem(.adaptive(minimum: 24, maximum: 24), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(ThemeManager.themes) { theme in
                let color = Color(hex: theme.dotColor)
                Button {
                    themeManager.currentThemeId = theme.id
                } label: {
                    ZStack {
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                        if theme.id == "white" || theme.id == "apple" {
                            Circle()
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                .frame(width: 24, height: 24)
                        }
                        if themeManager.currentThemeId == theme.id {
                            Circle()
                                .strokeBorder(Color.primary.opacity(0.82), lineWidth: 2)
                                .frame(width: 32, height: 32)
                        }
                    }
                    .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .help(theme.displayName)
            }
        }
    }
}
