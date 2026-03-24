import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        Form {
            Section("Audio") {
                SettingsAudioSection()
            }
            Section("Permissions") {
                SettingsPermissionsSection(viewModel: viewModel)
            }
            Section("Voice") {
                SettingsVoiceSection(viewModel: viewModel)
            }
            Section("About") {
                SettingsAboutSection()
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 400, minHeight: 450)
        .onAppear { viewModel.startPolling() }
        .onDisappear { viewModel.stopPolling() }
    }
}
