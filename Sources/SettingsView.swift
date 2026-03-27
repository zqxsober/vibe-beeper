import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case audio = "Audio"
    case permissions = "Permissions"
    case about = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .audio: return "speaker.wave.2.fill"
        case .permissions: return "lock.shield.fill"
        case .about: return "info.circle.fill"
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = SettingsViewModel()
    @State private var selectedTab: SettingsTab = .audio

    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 150, ideal: 170, max: 200)
        } detail: {
            Form {
                switch selectedTab {
                case .audio:
                    SettingsAudioSection()
                case .permissions:
                    SettingsPermissionsSection(viewModel: viewModel)
                case .about:
                    SettingsAboutSection()
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.visible)
        }
        .frame(width: 580, height: 420)
        .onAppear { viewModel.startPolling() }
        .onDisappear { viewModel.stopPolling() }
    }
}
