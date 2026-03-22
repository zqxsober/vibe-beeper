import SwiftUI

struct ContentView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager

    // Shell image: egg only, no padding. 200×242 (from 800×970 @ 4x)
    private let canvasW: CGFloat = 200
    private let canvasH: CGFloat = 242

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Shell background image — themed
            Image(nsImage: loadShellImage(themeManager.shellImageName))
                .resizable()
                .frame(width: canvasW, height: canvasH)

            // LCD screen content — centered horizontally, top=54, 120×88 (from Figma)
            ScreenView()
                .frame(width: 116, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 1))
                .position(x: canvasW / 2, y: 99)
                .allowsHitTesting(false)

            // 5 buttons: top row (stop speaking, go terminal, accept), bottom row (mic, deny)
            // Center button is 4px lower than flanking top buttons

            // Stop Speaking (top-left)
            LeftActionButton(
                symbol: "speaker.slash.fill",
                active: monitor.ttsService.isSpeaking
            ) { monitor.ttsService.stopSpeaking() }
            .position(x: 46, y: 172)
            .accessibilityLabel("Stop speaking")

            // Go to Terminal (top-center, 4px lower, no rotation)
            Button(action: { monitor.goToConversation() }) {
                ZStack {
                    Ellipse()
                        .fill(LinearGradient(
                            colors: [Color.black.opacity(0.56), Color.black.opacity(0)],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .frame(width: 40, height: 28)
                        .blur(radius: 2)

                    Ellipse()
                        .fill(Color(hex: "1C1C1C"))
                        .frame(width: 36, height: 24)

                    Ellipse()
                        .fill(LinearGradient(
                            colors: [.white.opacity(0.10), .clear],
                            startPoint: .top, endPoint: .center
                        ))
                        .frame(width: 30, height: 16)
                        .offset(y: -2)

                    Ellipse()
                        .stroke(LinearGradient(
                            colors: [.white.opacity(0.06), .clear, .clear, .black.opacity(0.15)],
                            startPoint: .top, endPoint: .bottom
                        ), lineWidth: 0.75)
                        .frame(width: 35, height: 23)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(white: 0.72, opacity: 0.80))
                        .shadow(color: Color(red: 0, green: 0.07, blue: 0.18).opacity(0.32), radius: 4)
                }
                .frame(width: 46, height: 34)
            }
            .buttonStyle(ShellButtonStyle())
            .position(x: 100, y: 176)
            .accessibilityLabel("Go to terminal")

            // Accept (top-right)
            ActionButton(
                symbol: "checkmark",
                active: monitor.state.needsAttention,
                pulse: monitor.state.needsAttention
            ) { monitor.respondToPermission(allow: true) }
            .position(x: 154, y: 172)
            .accessibilityLabel("Accept permission")

            // Record/Mic (bottom-left)
            LeftActionButton(
                symbol: monitor.isRecording ? "stop.fill" : "mic.fill",
                active: true,
                pulse: monitor.isRecording,
                iconColor: monitor.isRecording ? Color(hex: "FF2929") : nil
            ) { monitor.voiceService.toggle() }
            .position(x: 68, y: 204)
            .accessibilityLabel(monitor.isRecording ? "Stop recording" : "Speak")

            // Deny (bottom-right)
            ActionButton(
                symbol: "xmark",
                active: monitor.state.needsAttention
            ) { monitor.respondToPermission(allow: false) }
            .position(x: 132, y: 204)
            .accessibilityLabel("Deny permission")
        }
        .frame(width: canvasW, height: canvasH)
        .background(Color.clear)
        .contextMenu {
            Button("Quit Claumagotchi") { NSApplication.shared.terminate(nil) }
        }
    }


    // Load shell image by theme name — try bundle Resources, then source tree
    private func loadShellImage(_ name: String) -> NSImage {
        if let path = Bundle.main.resourcePath,
           let img = NSImage(contentsOfFile: path + "/" + name) { return img }
        if let img = NSImage(contentsOfFile: "/Users/vcartier/Desktop/Claumagotchi/Sources/shells/" + name) { return img }
        // Fallback to default
        if let path = Bundle.main.resourcePath,
           let img = NSImage(contentsOfFile: path + "/shell.png") { return img }
        if let img = NSImage(contentsOfFile: "/Users/vcartier/Desktop/Claumagotchi/Sources/shells/shell-orange.png") { return img }
        return NSImage()
    }
}

