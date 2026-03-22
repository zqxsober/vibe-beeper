import SwiftUI

// MARK: - Right-Side Button (rotated -15°, light from topLeading)

struct ActionButton: View {
    let symbol: String
    var size: CGFloat = 10
    let active: Bool
    var pulse: Bool = false
    let action: () -> Void

    @State private var animating = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Background shadow shape: 40×28, blurred
                Ellipse()
                    .fill(LinearGradient(
                        colors: [Color.black.opacity(0.56), Color.black.opacity(0)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(width: 40, height: 28)
                    .blur(radius: 2)

                // Button face: 36×24, #1C1C1C
                Ellipse()
                    .fill(Color(hex: "1C1C1C"))
                    .frame(width: 36, height: 24)

                // Top specular highlight
                Ellipse()
                    .fill(LinearGradient(
                        colors: [.white.opacity(0.10), .clear],
                        startPoint: .top, endPoint: .center
                    ))
                    .frame(width: 30, height: 16)
                    .offset(y: -2)

                // Inner shadow — light on topLeading
                Ellipse()
                    .stroke(LinearGradient(
                        colors: [.white.opacity(0.06), .clear, .clear, .black.opacity(0.15)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ), lineWidth: 0.75)
                    .frame(width: 35, height: 23)

                // Icon
                Image(systemName: symbol)
                    .font(.system(size: size, weight: .bold))
                    .foregroundColor(active ? Color(white: 0.72, opacity: 0.80) : Color(white: 0.62, opacity: 0.3))
                    .shadow(color: Color(red: 0, green: 0.07, blue: 0.18).opacity(0.32), radius: 4)
                    .rotationEffect(.degrees(15))
            }
            .frame(width: 46, height: 34)
            .rotationEffect(.degrees(-15))
            //.scaleEffect(pulse && animating ? 1.08 : 1.0)
        }
        .buttonStyle(ShellButtonStyle())
        .disabled(!active)
        .onChange(of: pulse) {
            if pulse {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { animating = true }
            } else {
                withAnimation(.none) { animating = false }
            }
        }
    }
}

// MARK: - Left-Side Button (rotated +15°, light from topTrailing)

struct LeftActionButton: View {
    let symbol: String
    var size: CGFloat = 10
    let active: Bool
    var pulse: Bool = false
    var iconColor: Color? = nil
    let action: () -> Void

    @State private var animating = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Background shadow shape: 40×28, blurred
                Ellipse()
                    .fill(LinearGradient(
                        colors: [Color.black.opacity(0.56), Color.black.opacity(0)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(width: 40, height: 28)
                    .blur(radius: 2)

                // Button face: 36×24, #1C1C1C
                Ellipse()
                    .fill(Color(hex: "1C1C1C"))
                    .frame(width: 36, height: 24)

                // Top specular highlight
                Ellipse()
                    .fill(LinearGradient(
                        colors: [.white.opacity(0.10), .clear],
                        startPoint: .top, endPoint: .center
                    ))
                    .frame(width: 30, height: 16)
                    .offset(y: -2)

                // Inner shadow — light on topTrailing (mirrored)
                Ellipse()
                    .stroke(LinearGradient(
                        colors: [.white.opacity(0.06), .clear, .clear, .black.opacity(0.15)],
                        startPoint: .topTrailing, endPoint: .bottomLeading
                    ), lineWidth: 0.75)
                    .frame(width: 35, height: 23)

                // Icon
                Image(systemName: symbol)
                    .font(.system(size: size, weight: .bold))
                    .foregroundColor(iconColor ?? (active ? Color(white: 0.72, opacity: 0.80) : Color(white: 0.62, opacity: 0.3)))
                    .shadow(color: Color(red: 0, green: 0.07, blue: 0.18).opacity(0.32), radius: 4)
                    .rotationEffect(.degrees(-15))
            }
            .frame(width: 46, height: 34)
            .rotationEffect(.degrees(15))
            //.scaleEffect(pulse && animating ? 1.08 : 1.0)
        }
        .buttonStyle(ShellButtonStyle())
        .disabled(!active)
        .onChange(of: pulse) {
            if pulse {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { animating = true }
            } else {
                withAnimation(.none) { animating = false }
            }
        }
    }
}

// MARK: - Shell Button Style

struct ShellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .brightness(configuration.isPressed ? 0.15 : 0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}
