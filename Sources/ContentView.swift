import SwiftUI

struct ContentView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager

    private let shellW: CGFloat = 186
    private let shellH: CGFloat = 230

    var body: some View {
        ZStack {
            // Diffused drop shadow
            Ellipse()
                .fill(.black.opacity(0.45))
                .frame(width: shellW + 10, height: shellH + 10)
                .blur(radius: 28)
                .offset(y: 10)

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
                .opacity(0.15)
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
                            .white.opacity(themeManager.darkMode ? 0.20 : 0.45),
                            .white.opacity(themeManager.darkMode ? 0.04 : 0.1),
                            .clear,
                            .black.opacity(0.12),
                            .black.opacity(0.2),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.0
                )
                .frame(width: shellW, height: shellH)

            // Content layout
            VStack(spacing: 4) {
                // Pixel title
                PixelTitle()
                    .frame(width: 140, height: 12)
                    .padding(.top, 14)
                    .padding(.bottom, 2)

                // Screen — matching Figma proportions
                ZStack {
                    // LCD screen
                    ScreenView()
                        .frame(width: 130, height: 82)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    // Outer bezel ring
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.15),
                                    .clear,
                                    .black.opacity(0.1),
                                ],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 134, height: 86)
                        .allowsHitTesting(false)

                    // Inner shadow — crisp stroke
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .black.opacity(0.7),
                                    .black.opacity(0.15),
                                    .black.opacity(0.03),
                                    .black.opacity(0.08),
                                    .black.opacity(0.3),
                                ],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: 2.5
                        )
                        .frame(width: 130, height: 82)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .allowsHitTesting(false)

                    // Side inner shadow
                    RoundedRectangle(cornerRadius: 4)
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
                        .frame(width: 130, height: 82)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .allowsHitTesting(false)
                }

                Spacer().frame(height: 6)

                // Buttons — W-shape matching Figma exactly
                // Outer two (Deny, Terminal) higher + bigger
                // Inner two (Accept, Speak) lower + smaller
                ZStack {
                    // Deny — far left, higher
                    ActionButton(
                        symbol: "xmark", size: 11,
                        iconColor: .white,
                        active: monitor.state.needsAttention,
                        buttonSize: 28
                    ) { monitor.respondToPermission(allow: false) }
                    .accessibilityLabel("Deny permission")
                    .offset(x: -50, y: -8)

                    // Accept — center-left, lower
                    ActionButton(
                        symbol: "checkmark", size: 11,
                        iconColor: .white,
                        active: monitor.state.needsAttention,
                        pulse: monitor.state.needsAttention,
                        buttonSize: 28
                    ) { monitor.respondToPermission(allow: true) }
                    .accessibilityLabel("Accept permission")
                    .offset(x: -18, y: 8)

                    // Speak — center-right, lower
                    ActionButton(
                        symbol: monitor.isRecording ? "stop.fill" : "mic.fill",
                        size: 11,
                        iconColor: monitor.isRecording ? .red : .white,
                        active: true,
                        pulse: monitor.isRecording,
                        buttonSize: 28
                    ) {
                        monitor.isRecording.toggle()
                    }
                    .accessibilityLabel(monitor.isRecording ? "Stop recording" : "Speak")
                    .offset(x: 18, y: 8)

                    // Terminal — far right, higher
                    ActionButton(
                        symbol: "arrow.up.forward", size: 11,
                        iconColor: .white,
                        active: true,
                        buttonSize: 28
                    ) { monitor.goToConversation() }
                    .accessibilityLabel("Go to terminal")
                    .offset(x: 50, y: -8)
                }
                .animation(.easeInOut(duration: 0.3), value: monitor.state)
                .frame(height: 44)
                .offset(y: -2)
            }
        }
        .frame(width: 220, height: 270)
        .background(Color.clear)
        .contextMenu {
            Button("Quit Claumagotchi") { NSApplication.shared.terminate(nil) }
        }
    }

}
