import SwiftUI

struct ContentView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager

    private let shellW: CGFloat = 186
    private let shellH: CGFloat = 224

    var body: some View {
        ZStack {
            // Diffused drop shadow
            Ellipse()
                .fill(.black.opacity(0.3))
                .frame(width: shellW + 10, height: shellH + 10)
                .blur(radius: 20)
                .offset(y: 6)

            // Main shell body
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: themeManager.shellColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: shellW, height: shellH)

            // Noise texture overlay for plastic grain
            NoiseView()
                .frame(width: shellW, height: shellH)
                .clipShape(Ellipse())
                .opacity(0.08)
                .allowsHitTesting(false)

            // Top-left glossy highlight
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.35),
                            .white.opacity(0.08),
                            .clear,
                        ],
                        center: UnitPoint(x: 0.3, y: 0.12),
                        startRadius: 0,
                        endRadius: 90
                    )
                )
                .frame(width: shellW, height: shellH)

            // Rim bevel
            Ellipse()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(themeManager.darkMode ? 0.15 : 0.35),
                            .white.opacity(themeManager.darkMode ? 0.04 : 0.1),
                            .clear,
                            .black.opacity(0.12),
                            .black.opacity(0.2),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: shellW, height: shellH)

            // Content layout
            VStack(spacing: 4) {
                // Pixel title
                PixelTitle()
                    .frame(width: 160, height: 14)
                    .padding(.top, 18)
                    .padding(.bottom, 4)

                // Screen
                ZStack {
                    // LCD screen
                    ScreenView()
                        .frame(width: 116, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 5))

                    // Inner shadow — crisp stroke
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .black.opacity(0.6),
                                    .black.opacity(0.15),
                                    .black.opacity(0.03),
                                    .black.opacity(0.08),
                                    .black.opacity(0.3),
                                ],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: 2.5
                        )
                        .frame(width: 116, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .allowsHitTesting(false)

                    // Side inner shadow
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .black.opacity(0.2),
                                    .clear,
                                    .clear,
                                    .black.opacity(0.12),
                                ],
                                startPoint: .leading, endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 116, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .allowsHitTesting(false)
                    }

                Spacer().frame(height: 6)

                // Buttons — V-shaped layout (middle slightly lower)
                HStack(alignment: .top, spacing: 5) {
                    if monitor.autoAccept {
                        // YOLO mode: bolt (disable) + go-to-convo — centered, no V
                        ActionButton(
                            symbol: "bolt.slash.fill", size: 12,
                            iconColor: .white,
                            active: true
                        ) { monitor.autoAccept = false }
                        .accessibilityLabel("Disable YOLO mode")

                        centerButton
                    } else {
                        // Normal mode: deny / center / allow
                        ActionButton(
                            symbol: "xmark", size: 12,
                            iconColor: .white,
                            active: monitor.state.needsAttention
                        ) { monitor.respondToPermission(allow: false) }
                        .accessibilityLabel("Deny permission")

                        centerButton
                            .offset(y: 5)

                        ActionButton(
                            symbol: "checkmark", size: 12,
                            iconColor: .white,
                            active: monitor.state.needsAttention,
                            pulse: monitor.state.needsAttention
                        ) { monitor.respondToPermission(allow: true) }
                        .accessibilityLabel("Allow permission")
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: monitor.state)
                .animation(.easeInOut(duration: 0.3), value: monitor.autoAccept)
                .frame(height: 40)
                .offset(y: -8)
            }
        }
        .frame(width: 250, height: 300)
        .background(Color.clear)
        .contextMenu {
            Button("Quit Claumagotchi") { NSApplication.shared.terminate(nil) }
        }
    }

    private var centerButton: some View {
        ActionButton(
            symbol: "arrow.up.forward", size: 12,
            iconColor: .white,
            active: monitor.state.canGoToConvo || monitor.state.needsAttention,
            pulse: monitor.state.canGoToConvo
        ) { monitor.goToConversation() }
        .accessibilityLabel("Go to conversation")
    }
}
