import Foundation
import AppKit

@MainActor
final class BuzzService {
    private var lastVibrateState: ClaudeState?
    private var reminderTimer: Timer?

    /// Called from ContentView.onReceive(monitor.$state) to handle vibration triggers.
    func handleStateChange(_ newState: ClaudeState, vibrationEnabled: Bool, soundEnabled: Bool) {
        // Vibration on done
        if vibrationEnabled && newState == .finished && lastVibrateState != newState {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.vibrate(soundEnabled: soundEnabled)
            }
        }

        // Needs permission: vibrate now + repeat every 15s
        if newState == .needsYou {
            if lastVibrateState != newState {
                if vibrationEnabled {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        self.vibrate(soundEnabled: soundEnabled)
                    }
                }
                reminderTimer?.invalidate()
                reminderTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
                    Task { @MainActor in
                        guard let self else { return }
                        self.vibrate(soundEnabled: soundEnabled)
                    }
                }
            }
        } else {
            reminderTimer?.invalidate()
            reminderTimer = nil
        }

        lastVibrateState = newState
    }

    func vibrate(soundEnabled: Bool) {
        if soundEnabled { playBeeps() }

        guard let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) else { return }
        let origin = window.frame.origin
        let shakes = 60
        let distance: CGFloat = 3
        let total = 3.0
        let interval = total / Double(shakes)

        for i in 0..<shakes {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                let dx: CGFloat = (i % 2 == 0) ? distance : -distance
                window.setFrameOrigin(NSPoint(x: origin.x + dx, y: origin.y))
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + total) {
            window.setFrameOrigin(origin)
        }
    }

    private func playBeeps() {
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                NSSound(named: "Tink")?.play()
            }
        }
    }
}
