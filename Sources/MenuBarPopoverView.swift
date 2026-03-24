import SwiftUI
import AppKit

struct MenuBarPopoverView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 16) {
            // SECTION 1: Quick action row
            HStack(spacing: 0) {
                Spacer()
                QuickActionButton(
                    icon: "bolt.fill",
                    label: "YOLO",
                    isActive: monitor.autoAccept,
                    activeColor: .purple
                ) {
                    monitor.autoAccept.toggle()
                }
                Spacer()
                QuickActionButton(
                    icon: "speaker.slash.fill",
                    label: "Mute",
                    isActive: !monitor.soundEnabled,
                    activeColor: .red
                ) {
                    monitor.soundEnabled.toggle()
                }
                Spacer()
                QuickActionButton(
                    icon: "eye.slash.fill",
                    label: "Hide",
                    isActive: false,
                    activeColor: .secondary
                ) {
                    ClaumagotchiApp.toggleMainWindow()
                }
                Spacer()
                QuickActionButton(
                    icon: "power",
                    label: monitor.isActive ? "On" : "Off",
                    isActive: monitor.isActive,
                    activeColor: .green
                ) {
                    monitor.isActive.toggle()
                    if !monitor.isActive {
                        ClaumagotchiApp.hideMainWindow()
                    } else {
                        ClaumagotchiApp.showMainWindow()
                    }
                }
                Spacer()
            }

            // SECTION 2: Theme dots
            ThemeDotsRow()

            // SECTION 3: Dark Mode toggle
            Toggle("Dark Mode", isOn: $themeManager.darkMode)
                .toggleStyle(.switch)

            Divider()

            // SECTION 4: Setup button
            Button("Setup...") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "settings")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // SECTION 5: Download Voices button
            Button("Download Voices...") {
                openSpokenContent()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // SECTION 6: Quit
            Button("Quit CC-Beeper") {
                NSApp.terminate(nil)
            }
            .foregroundStyle(.secondary)
            .font(.footnote)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 320)
        .padding(16)
    }

    private func openSpokenContent() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Accessibility-Settings.extension?SpokenContent") else { return }
        NSWorkspace.shared.open(url)
    }
}
