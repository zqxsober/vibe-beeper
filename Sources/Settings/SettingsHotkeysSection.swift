import SwiftUI

struct SettingsHotkeysSection: View {
    @EnvironmentObject var monitor: ClaudeMonitor

    var body: some View {
        Section("Global Hotkeys") {
            Text("All hotkeys use **⌥ Option** as the modifier. Click a key then press any letter to remap.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HotkeyRow(action: "Accept Permission", key: $monitor.hotkeyAccept)
            HotkeyRow(action: "Deny Permission", key: $monitor.hotkeyDeny)
            HotkeyRow(action: "Dictation", key: $monitor.hotkeyVoice)
            HotkeyRow(action: "Go to Terminal", key: $monitor.hotkeyTerminal)
            HotkeyRow(action: "Read Over / Stop", key: $monitor.hotkeyMute)
        }
    }
}

// MARK: - Hotkey Row

struct HotkeyRow: View {
    let action: String
    @Binding var key: String

    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        HStack {
            Text(action)
            Spacer()
            Button(isRecording ? "Press a key…" : "⌥ \(key)") {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }
            .buttonStyle(.bordered)
            .foregroundStyle(isRecording ? .orange : .primary)
        }
        .onDisappear { stopRecording() }
    }

    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Escape — cancel
                stopRecording()
                return nil
            }
            // Use the character the key actually produces (layout-aware)
            if let chars = event.charactersIgnoringModifiers?.uppercased(),
               chars.count == 1,
               chars.first?.isLetter == true {
                key = chars
                stopRecording()
                return nil
            }
            return event
        }
    }

    private func stopRecording() {
        isRecording = false
        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
    }
}
