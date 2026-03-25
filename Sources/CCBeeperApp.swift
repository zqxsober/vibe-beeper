import SwiftUI
import AppKit
import ApplicationServices

@main
struct CCBeeperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var monitor = ClaudeMonitor()
    @StateObject private var themeManager = ThemeManager()
    @Environment(\.openWindow) private var openWindow
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        Window("CC-Beeper", id: "main") {
            ContentView()
                .environmentObject(monitor)
                .environmentObject(themeManager)
                .background(WindowConfigurator())
                .onAppear {
                    if !hasCompletedOnboarding {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            Self.hideMainWindow()
                            openWindow(id: "onboarding")
                        }
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.topTrailing)

        Window("Setup CC-Beeper", id: "onboarding") {
            OnboardingView()
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .defaultSize(width: 480, height: 400)

        Window("Settings", id: "settings") {
            SettingsView()
                .environmentObject(monitor)
                .environmentObject(themeManager)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .defaultSize(width: 460, height: 520)

        MenuBarExtra {
            // Status
            Text("Sessions: \(monitor.sessionCount)")
            Text(monitor.autoAccept ? "YOLO MODE" : monitor.state.label)
                .foregroundColor(.secondary)

            Divider()

            // Quick toggles
            Toggle("YOLO Mode", isOn: $monitor.autoAccept)
                .keyboardShortcut("y")
            Toggle("Sound Effects", isOn: $monitor.soundEnabled)
                .keyboardShortcut("s")

            Divider()

            // Theme
            Menu("Theme") {
                Picker("Color", selection: $themeManager.currentThemeId) {
                    ForEach(ThemeManager.themes) { theme in
                        Text(theme.name).tag(theme.id)
                    }
                }
                Divider()
                Toggle("Dark Mode", isOn: $themeManager.darkMode)
            }

            Divider()

            Button("Show / Hide Widget") {
                Self.toggleMainWindow()
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])

            Button(monitor.isActive ? "Power Off" : "Power On") {
                monitor.isActive.toggle()
                if !monitor.isActive {
                    Self.hideMainWindow()
                } else {
                    Self.showMainWindow()
                }
            }
            .keyboardShortcut("p")

            Divider()

            Button("Settings...") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "settings")
            }

            Button("Setup Wizard...") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "onboarding")
            }

            Divider()

            Button("Quit CC-Beeper") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        } label: {
            Image(nsImage: EggIcon.image(state: monitor.menuBarIconState))
        }
        .menuBarExtraStyle(.menu)
    }

    static func toggleMainWindow() {
        for window in NSApp.windows where window.identifier?.rawValue == "main" {
            window.isVisible ? window.orderOut(nil) : window.makeKeyAndOrderFront(nil)
            return
        }
    }

    static func showMainWindow() {
        for window in NSApp.windows where window.identifier?.rawValue == "main" {
            if !window.isVisible {
                window.makeKeyAndOrderFront(nil)
            }
            return
        }
    }

    static func hideMainWindow() {
        for window in NSApp.windows where window.identifier?.rawValue == "main" {
            window.orderOut(nil)
            return
        }
    }
}

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let pidFile = NSHomeDirectory() + "/.claude/cc-beeper/cc-beeper.pid"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Migration: move old IPC directory to new cc-beeper path
        migrateIPCDirectoryIfNeeded()

        if let existing = Self.readPID(), Self.isProcessAlive(existing) {
            NSApp.terminate(nil)
            return
        }
        Self.writePID()

        AppMover.moveToApplicationsIfNeeded()

        let hasOnboarded = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        if hasOnboarded && !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        Self.removePID()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            CCBeeperApp.showMainWindow()
        }
        return false
    }

    // MARK: - IPC Migration

    /// Migrate old ~/.claude/claumagotchi/ IPC directory to ~/.claude/cc-beeper/
    private func migrateIPCDirectoryIfNeeded() {
        let fm = FileManager.default
        let oldPath = NSHomeDirectory() + "/.claude/claumagotchi"
        let newPath = NSHomeDirectory() + "/.claude/cc-beeper"

        var isOldDir: ObjCBool = false
        guard fm.fileExists(atPath: oldPath, isDirectory: &isOldDir), isOldDir.boolValue else {
            return // old path doesn't exist — nothing to migrate
        }

        // Ensure new directory exists
        try? fm.createDirectory(atPath: newPath, withIntermediateDirectories: true)

        // Copy each item from old to new (skip if already exists at destination)
        if let items = try? fm.contentsOfDirectory(atPath: oldPath) {
            for item in items {
                let src = oldPath + "/" + item
                let dst = newPath + "/" + item
                if !fm.fileExists(atPath: dst) {
                    try? fm.copyItem(atPath: src, toPath: dst)
                }
            }
        }

        // Remove old directory
        try? fm.removeItem(atPath: oldPath)
    }

    // MARK: - PID Management

    private static func readPID() -> pid_t? {
        guard let data = FileManager.default.contents(atPath: pidFile),
              let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let pid = Int32(str) else { return nil }
        return pid
    }

    private static func writePID() {
        let dir = (pidFile as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let pid = ProcessInfo.processInfo.processIdentifier
        try? "\(pid)\n".write(toFile: pidFile, atomically: true, encoding: .utf8)
    }

    private static func removePID() {
        if let stored = readPID(), stored == ProcessInfo.processInfo.processIdentifier {
            try? FileManager.default.removeItem(atPath: pidFile)
        }
    }

    private static func isProcessAlive(_ pid: pid_t) -> Bool {
        kill(pid, 0) == 0
    }
}
