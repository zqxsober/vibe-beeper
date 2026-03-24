import SwiftUI

struct ThemeDotsRow: View {
    @EnvironmentObject var themeManager: ThemeManager

    private let colorMap: [String: Color] = [
        "black": .black,
        "orange": .orange,
        "blue": .blue,
        "green": .green,
        "purple": .purple,
        "red": .red,
        "white": Color(white: 0.9),
        "yellow": .yellow,
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ThemeManager.themes) { theme in
                let color = colorMap[theme.id] ?? .gray
                Button {
                    themeManager.currentThemeId = theme.id
                } label: {
                    ZStack {
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                        if themeManager.currentThemeId == theme.id {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
