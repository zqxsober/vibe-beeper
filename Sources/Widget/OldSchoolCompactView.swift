import SwiftUI
import AppKit

struct OldSchoolCompactView: View {
    @EnvironmentObject var monitor: ClaudeMonitor

    @State private var ledPulse = false
    private let ledTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    private let shellW: CGFloat = 310
    private let shellH: CGFloat = 245

    var body: some View {
        ZStack(alignment: .topLeading) {
            OldSchoolDesktopMacBody(includesKeyboardBase: false)
                .frame(width: shellW, height: shellH)

            OldSchoolLCDPanel(cornerRadius: 8, inset: 5, contentPadding: 8) {
                OldSchoolReferenceScreen(compact: true)
            }
            .frame(width: 240, height: 139)
            .offset(x: 35, y: 30)

            OldSchoolAppleLogo(size: 26)
                .offset(x: 40, y: 172)

            OldSchoolFloppyDrive()
                .frame(width: 88, height: 16)
                .offset(x: 185, y: 184)

            OldSchoolLED(color: driveLEDColor, active: ledAlertActive && ledPulse, size: 6)
                .offset(x: 281, y: 189)
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
