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
        let scale = min(size.width / 420, size.height / 420)

        ZStack(alignment: .topLeading) {
            OldSchoolDesktopMacBody(includesKeyboardBase: true)
                .frame(width: 396 * scale, height: 410 * scale)
                .offset(x: 12 * scale, y: 5 * scale)

            OldSchoolLCDPanel(cornerRadius: 10 * scale, inset: 6 * scale, contentPadding: 12 * scale) {
                OldSchoolReferenceScreen()
            }
            .frame(width: 306 * scale, height: 178 * scale)
            .offset(x: 54 * scale, y: 44 * scale)

            OldSchoolAppleLogo(size: 35 * scale)
                .offset(x: 45 * scale, y: 252 * scale)

            OldSchoolFloppyDrive()
                .frame(width: 114 * scale, height: 22 * scale)
                .offset(x: 254 * scale, y: 266 * scale)

            OldSchoolLED(color: driveLEDColor, active: ledAlertActive && ledPulse, size: 7 * scale)
                .offset(x: 375 * scale, y: 274 * scale)

            OldSchoolControls(
                permissionActive: monitor.state.needsAttention,
                isRecording: monitor.isRecording,
                isSpeaking: monitor.ttsService.isSpeaking,
                onAccept: { monitor.respondToPermission(allow: true) },
                onDeny: { monitor.respondToPermission(allow: false) },
                onRecord: { monitor.voiceService.toggle() },
                onStopSpeaking: {
                    if monitor.ttsService.isSpeaking {
                        monitor.ttsService.stopSpeaking()
                    }
                },
                onTerminal: { monitor.goToConversation() },
                keySize: CGSize(width: 56 * scale, height: 51 * scale),
                iconSize: 25 * scale,
                spacing: 16 * scale
            )
            .offset(x: 35 * scale, y: 331 * scale)
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
