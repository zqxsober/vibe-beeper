import SwiftUI
import AppKit

struct OldSchoolCompactView: View {
    @EnvironmentObject var monitor: ClaudeMonitor

    @State private var ledPulse = false
    private let ledTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    private let shellW: CGFloat = 310
    private let shellH: CGFloat = 349

    var body: some View {
        let scale = shellW / 1020

        ZStack(alignment: .topLeading) {
            OldSchoolShellArtwork()
                .frame(width: shellW, height: shellH)

            OldSchoolLCDPanel(cornerRadius: 18 * scale, inset: 8 * scale, contentPadding: 34 * scale) {
                OldSchoolReferenceScreen(compact: true)
            }
            .frame(width: 736 * scale, height: 462 * scale)
            .offset(x: 142 * scale, y: 101 * scale)
            .zIndex(1)

            OldSchoolControlHitAreas(
                scale: scale,
                permissionActive: monitor.state.needsAttention,
                isSpeaking: monitor.ttsService.isSpeaking,
                onAccept: { monitor.respondToPermission(allow: true) },
                onDeny: { monitor.respondToPermission(allow: false) },
                onRecord: { monitor.voiceService.toggle() },
                onStopSpeaking: {
                    if monitor.ttsService.isSpeaking {
                        monitor.ttsService.stopSpeaking()
                    }
                },
                onTerminal: { monitor.goToConversation() }
            )
            .zIndex(2)

            OldSchoolLED(color: driveLEDColor, active: ledAlertActive && ledPulse, size: 7 * scale)
                .offset(x: 896 * scale, y: 688 * scale)
        }
        .frame(width: shellW, height: shellH)
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

    private var driveLEDColor: Color {
        if ledAlertActive {
            return AppConstants.ledAmber
        }
        if monitor.state == .done {
            return AppConstants.ledGreen
        }
        return Color(hex: "D64A3A")
    }

    private var ledAlertActive: Bool {
        monitor.state == .working || monitor.state.needsAttention
    }
}

#Preview {
    OldSchoolCompactView()
        .environmentObject(ClaudeMonitor())
}
