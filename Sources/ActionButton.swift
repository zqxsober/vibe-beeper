import SwiftUI

// MARK: - Action Button

struct ActionButton: View {
    @EnvironmentObject var themeManager: ThemeManager

    let symbol: String
    var size: CGFloat = 9
    var iconColor: Color = .white
    let active: Bool
    var pulse: Bool = false
    var buttonSize: CGFloat = 28
    let action: () -> Void

    @State private var animating = false

    private var wellSize: CGFloat { buttonSize + 3 }
    private var frameSize: CGFloat { buttonSize + 4 }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Recessed well the button sits in
                Circle()
                    .fill(Color.black.opacity(0.25))
                    .frame(width: wellSize, height: wellSize)
                    .blur(radius: 1)

                // Button face — themed accent color
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                themeManager.accentBase.opacity(active ? 0.5 : 0.3),
                                themeManager.accentDark.opacity(active ? 0.6 : 0.35),
                            ],
                            center: UnitPoint(x: 0.4, y: 0.35),
                            startRadius: 0,
                            endRadius: buttonSize * 0.57
                        )
                    )
                    .frame(width: buttonSize, height: buttonSize)

                // Top specular highlight
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.4),
                                .white.opacity(0.05),
                                .clear,
                            ],
                            startPoint: .top, endPoint: .center
                        )
                    )
                    .frame(width: buttonSize, height: buttonSize)

                // Bottom catch light
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.08),
                            ],
                            startPoint: .center, endPoint: .bottom
                        )
                    )
                    .frame(width: buttonSize, height: buttonSize)

                // Rim
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.4),
                                .clear,
                                .black.opacity(0.15),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
                    .frame(width: buttonSize, height: buttonSize)

                Image(systemName: symbol)
                    .font(.system(size: size, weight: .black))
                    .foregroundColor(active ? iconColor : Color(hex: "A8A4A0"))
                    .shadow(color: .black.opacity(active ? 0.3 : 0), radius: 0.5, y: 0.5)
            }
            .frame(width: frameSize, height: frameSize)
            .scaleEffect(pulse && animating ? 1.08 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(!active)
        .onChange(of: pulse) {
            if pulse {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    animating = true
                }
            } else {
                withAnimation(.none) { animating = false }
            }
        }
    }
}
