import SwiftUI
import AppKit

struct CompactView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager

    @State private var ledPulse = false
    private let ledTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    private var shellW: CGFloat { 220 }
    private var shellH: CGFloat { 113 }

    // LCD screen -- proportional from large shell (286x45 in 360x160)
    private var lcdW: CGFloat { themeManager.isAppleTheme ? 160 : 175 }
    private var lcdH: CGFloat { themeManager.isAppleTheme ? 36 : 47 }
    private var lcdX: CGFloat { themeManager.isAppleTheme ? 30 : 26 }
    private var lcdY: CGFloat { themeManager.isAppleTheme ? 38 : 31 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Small shell background
            Image(nsImage: loadShellImage(themeManager.smallShellImageName))
                .resizable()
                .interpolation(.high)
                .frame(width: shellW, height: shellH)

            if themeManager.isAppleTheme {
                AppleDriveLED(color: appleDriveLEDColor, active: ledAlertActive && ledPulse)
                    .offset(x: 198, y: 87)
            } else {
                // LED indicators — top right of bezel
                HStack(spacing: 3) {
                    Circle()
                        .fill(ledGreenColor)
                        .frame(width: 4, height: 4)
                        .shadow(color: ledGreenColor.opacity(0.6), radius: ledGreenGlow ? 2 : 0)
                    Circle()
                        .fill(ledAlertColor)
                        .frame(width: 4, height: 4)
                        .opacity(ledAlertActive ? (ledPulse ? 1.0 : 0.3) : 1.0)
                        .shadow(color: ledAlertColor.opacity(0.6), radius: ledAlertActive && ledPulse ? 3 : 0)
                }
                .offset(x: 173, y: 21)
            }

            if themeManager.isAppleTheme {
                AppleLCDHeader()
                    .frame(width: 160, height: 10)
                    .offset(x: 30, y: 27)
            }

            // LCD screen -- compact mode (icon-only badge)
            ScreenView(compact: true)
                .frame(width: lcdW, height: lcdH)
                .clipped()
                .offset(x: lcdX, y: lcdY)
                .allowsHitTesting(false)
        }
        .frame(width: shellW, height: shellH)
        .padding(40)
        .background(Color.clear)
        .contextMenu {
            Button("Quit vibe-beeper") { NSApplication.shared.terminate(nil) }
        }
        .onReceive(ledTimer) { _ in
            if monitor.state.needsAttention || monitor.state == .working {
                ledPulse.toggle()
            }
        }
        .onChange(of: monitor.state) { _, newState in
            if !(newState.needsAttention || newState == .working) {
                ledPulse = false
            }
        }
    }

    // MARK: - LEDs (same logic as ContentView)

    private var ledGreenColor: Color {
        if monitor.state == .working || monitor.state.needsAttention {
            return AppConstants.ledOff
        }
        return AppConstants.ledGreen
    }

    private var ledGreenGlow: Bool {
        monitor.state == .done || monitor.state == .idle
    }

    private var ledAlertColor: Color {
        if monitor.state == .working || monitor.state.needsAttention {
            return AppConstants.ledAmber
        }
        return AppConstants.ledOff
    }

    private var ledAlertActive: Bool {
        monitor.state == .working || monitor.state.needsAttention
    }

    private var appleDriveLEDColor: Color {
        if ledAlertActive {
            return AppConstants.ledAmber
        }
        if monitor.state == .done {
            return AppConstants.ledGreen
        }
        return Color(hex: "D64A3A")
    }

    private func loadShellImage(_ name: String) -> NSImage {
        if let path = Bundle.main.resourcePath,
           let img = NSImage(contentsOfFile: path + "/" + name) { return img }
        return NSImage()
    }
}

#Preview {
    CompactView()
        .environmentObject(ClaudeMonitor())
        .environmentObject(ThemeManager())
}
