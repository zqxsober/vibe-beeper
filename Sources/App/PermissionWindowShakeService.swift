import AppKit
import Combine

@MainActor
final class PermissionWindowShakeService: ObservableObject {
    private let offsets: [CGFloat] = [0, 5, -5, 4, -4, 3, -3]

    private var timer: Timer?
    private weak var window: NSWindow?
    private var baseOrigin: NSPoint?
    private var frameIndex = 0
    private var lastAppliedOffset: CGFloat = 0
    private var madeWindowVisible = false

    deinit {
        timer?.invalidate()
    }

    func update(isPermissionPending: Bool) {
        if isPermissionPending {
            start()
        } else {
            stop()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil

        if let window {
            restoreWindow(window)
            if madeWindowVisible {
                window.orderOut(nil)
            }
        }

        window = nil
        baseOrigin = nil
        frameIndex = 0
        lastAppliedOffset = 0
        madeWindowVisible = false
    }

    private func start() {
        guard timer == nil else { return }
        captureMainWindow()

        timer = Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.shakeNextFrame()
            }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func shakeNextFrame() {
        captureMainWindow()

        guard let window, window.isVisible else { return }

        if NSEvent.pressedMouseButtons & 1 != 0 {
            baseOrigin = window.frame.origin
            lastAppliedOffset = 0
            return
        }

        let currentOrigin = window.frame.origin
        if let baseOrigin {
            let expectedX = baseOrigin.x + lastAppliedOffset
            if abs(currentOrigin.x - expectedX) > 1 || abs(currentOrigin.y - baseOrigin.y) > 1 {
                self.baseOrigin = currentOrigin
                lastAppliedOffset = 0
            }
        } else {
            baseOrigin = currentOrigin
        }

        guard let baseOrigin else { return }

        let offset = offsets[frameIndex % offsets.count]
        window.setFrameOrigin(NSPoint(x: baseOrigin.x + offset, y: baseOrigin.y))
        lastAppliedOffset = offset
        frameIndex += 1
    }

    private func captureMainWindow() {
        guard let mainWindow = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) else { return }
        guard window !== mainWindow else { return }

        window = mainWindow
        baseOrigin = mainWindow.frame.origin
        frameIndex = 0
        lastAppliedOffset = 0

        if !mainWindow.isVisible {
            mainWindow.orderFrontRegardless()
            madeWindowVisible = true
        }
    }

    private func restoreWindow(_ window: NSWindow) {
        let origin = baseOrigin ?? window.frame.origin
        window.setFrameOrigin(NSPoint(x: round(origin.x), y: round(origin.y)))
    }
}
