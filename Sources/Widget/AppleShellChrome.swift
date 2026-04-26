import SwiftUI

struct AppleLCDHeader: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "apple.logo")
                .font(.system(size: 8, weight: .black))
            Text("VIBE-BEEPER")
                .font(.system(size: 8, weight: .black, design: .monospaced))
            Spacer(minLength: 0)
        }
        .foregroundStyle(Color(hex: "1F2A1B"))
        .padding(.horizontal, 5)
        .allowsHitTesting(false)
    }
}

struct AppleDriveLED: View {
    let color: Color
    let active: Bool

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 4, height: 4)
            .opacity(active ? 1.0 : 0.75)
            .shadow(color: color.opacity(active ? 0.65 : 0), radius: active ? 3 : 0)
            .allowsHitTesting(false)
    }
}

struct AppleShellControls: View {
    let permissionActive: Bool
    let isRecording: Bool
    let isSpeaking: Bool
    let onAccept: () -> Void
    let onDeny: () -> Void
    let onRecord: () -> Void
    let onStopSpeaking: () -> Void
    let onTerminal: () -> Void

    var body: some View {
        HStack(spacing: 7) {
            AppleKeyButton(symbol: "checkmark", isEnabled: permissionActive, action: onAccept)
                .help("Accept")
            AppleKeyButton(symbol: "xmark", isEnabled: permissionActive, action: onDeny)
                .help("Deny")
            AppleKeyButton(symbol: isRecording ? "stop.fill" : "mic.fill", isEnabled: true, action: onRecord)
                .help(isRecording ? "Stop recording" : "Record")
            AppleKeyButton(symbol: "speaker.wave.2.fill", isEnabled: isSpeaking, action: onStopSpeaking)
                .help("Stop speaking")
            AppleKeyButton(symbol: "terminal.fill", isEnabled: true, action: onTerminal)
                .help("Go to terminal")
        }
    }
}

private struct AppleKeyButton: View {
    let symbol: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(isEnabled ? Color(hex: "1F1D16") : Color(hex: "8C8779"))
                .frame(width: 22, height: 22)
        }
        .buttonStyle(AppleKeyButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.55)
    }
}

private struct AppleKeyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                LinearGradient(
                    colors: configuration.isPressed
                        ? [Color(hex: "BDB59E"), Color(hex: "DAD3BD")]
                        : [Color(hex: "F4EEDC"), Color(hex: "CFC7AE")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(Color(hex: "9E967F"), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.08 : 0.22), radius: 2, x: 0, y: configuration.isPressed ? 0 : 1)
            .offset(y: configuration.isPressed ? 1 : 0)
    }
}
