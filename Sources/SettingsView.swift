import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        Form {
            Section("Audio") {
                Text("Audio settings")
            }
            Section("Permissions") {
                Text("Permissions")
            }
            Section("Voice") {
                Text("Voice")
            }
            Section("About") {
                Text("About")
            }
        }
        .frame(width: 460, height: 520)
        .onAppear { viewModel.startPolling() }
        .onDisappear { viewModel.stopPolling() }
    }
}
