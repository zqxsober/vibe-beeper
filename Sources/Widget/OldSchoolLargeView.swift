import SwiftUI
import AppKit

struct OldSchoolLargeView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager

    @State private var buzzService = BuzzService()
    @State private var ledPulse = false
    private let ledTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    private var windowSize: CGSize {
        let size = themeManager.oldSchoolDisplaySize.windowSize
        return CGSize(width: size.width, height: size.height)
    }

    var body: some View {
        let size = windowSize
        let scale = min(size.width / 1020, size.height / 1147)
        let shellWidth = 1020 * scale
        let shellHeight = 1147 * scale
        let originX = (size.width - shellWidth) / 2
        let originY = (size.height - shellHeight) / 2

        ZStack(alignment: .topLeading) {
            OldSchoolShellArtwork()
                .frame(width: shellWidth, height: shellHeight)
                .offset(x: originX, y: originY)

            OldSchoolLCDPanel(cornerRadius: 18 * scale, inset: 8 * scale, contentPadding: 34 * scale) {
                OldSchoolReferenceScreen()
            }
            .frame(width: 736 * scale, height: 462 * scale)
            .offset(x: originX + 142 * scale, y: originY + 101 * scale)
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
            .offset(x: originX, y: originY)
            .zIndex(2)

            OldSchoolLED(color: driveLEDColor, active: ledAlertActive && ledPulse, size: 7 * scale)
                .offset(x: originX + 896 * scale, y: originY + 688 * scale)
        }
        .frame(width: size.width, height: size.height)
        .background(Color.clear)
        .onTapGesture {
            if buzzService.isVibrating {
                buzzService.cancelVibration()
            }
        }
        .contextMenu {
            Button("Quit vibe-beeper") { NSApplication.shared.terminate(nil) }
        }
        .onReceive(monitor.$state) { newState in
            handleStateChange(newState)
        }
        .onReceive(ledTimer) { _ in
            if monitor.state.needsAttention || monitor.state == .working {
                ledPulse.toggle()
            }
        }
        .onDisappear {
            buzzService.handleStateChange(.idle, vibrationEnabled: false, soundEnabled: false)
            if buzzService.isVibrating {
                buzzService.cancelVibration()
            }
        }
    }

    private func handleStateChange(_ newState: ClaudeState) {
        if !(newState.needsAttention || newState == .working) {
            ledPulse = false
        }

        buzzService.handleStateChange(newState, vibrationEnabled: monitor.vibrationEnabled, soundEnabled: monitor.soundEnabled && !monitor.isMuted)
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
    OldSchoolLargeView()
        .environmentObject(ClaudeMonitor())
        .environmentObject(ThemeManager())
}
