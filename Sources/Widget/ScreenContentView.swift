import SwiftUI

struct ScreenContentView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager
    @State private var animFrame = 0
    @State private var tick = 0
    @State private var isWindowVisible = true
    @State private var bounceOffset: CGFloat = 0
    @State private var blinkOn: Bool = true
    @State private var pulseOpacity: Double = 1.0
    @State private var glitchActive: Bool = false

    private let animTimer = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let blinkTimer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()

    private var isYoloActive: Bool { monitor.autoAccept }

    var body: some View {
        ZStack {
            Rectangle().fill(themeManager.darkMode ? themeManager.lcdBg : Color.clear)

            HStack(spacing: 8) {
                // Character
                PixelCharacterView(
                    state: monitor.state,
                    frame: animFrame,
                    onColor: themeManager.lcdOn,
                    isYolo: isYoloActive,
                    isGlitching: glitchActive
                )
                .frame(width: 35, height: 30)
                .offset(y: bounceOffset)

                // Status: big title + scrolling detail
                VStack(alignment: .leading, spacing: 1) {
                    Text(titleText)
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundColor(themeManager.lcdOn)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .opacity(titleOpacity)

                    if let detail = detailText {
                        MarqueeText(text: detail, font: .system(size: 8, weight: .medium, design: .monospaced), color: themeManager.lcdOn.opacity(0.7))
                            .frame(height: 10)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // YOLO badge
                if isYoloActive {
                    HStack(spacing: 3) {
                        Image(systemName: "hare.fill")
                            .font(.system(size: 9))
                        Text("YOLO")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                    }
                    .foregroundColor(themeManager.lcdOn)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(themeManager.lcdOn.opacity(0.6), lineWidth: 1)
                    )
                    .offset(x: -2, y: -8)
                }
            }
            .padding(.leading, 10)
            .padding(.trailing, 6)
            .padding(.vertical, 3)

            // Auth flash overlay (LCD-07) — shows over current content for 2-3s
            if let flashText = monitor.authFlashMessage {
                Text(flashText)
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(themeManager.lcdOn)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(themeManager.darkMode ? themeManager.lcdBg.opacity(0.9) : Color.clear.opacity(0.9))
                    .transition(.opacity)
            }

            // Vignette
            RadialGradient(
                colors: [.clear, Color(hex: "1A3008").opacity(0.25)],
                center: .center,
                startRadius: 60,
                endRadius: 160
            )
            .allowsHitTesting(false)

            // Pixel grid
            Canvas { context, size in
                let lineColor = Color(hex: "2A4A10").opacity(themeManager.darkMode ? 0.25 : 0.12)
                let spacing: CGFloat = 2.0
                let lineW: CGFloat = 0.5

                var x: CGFloat = spacing
                while x < size.width {
                    context.fill(
                        Path(CGRect(x: x, y: 0, width: lineW, height: size.height)),
                        with: .color(lineColor)
                    )
                    x += spacing
                }
                var y: CGFloat = spacing
                while y < size.height {
                    context.fill(
                        Path(CGRect(x: 0, y: y, width: size.width, height: lineW)),
                        with: .color(lineColor)
                    )
                    y += spacing
                }
            }
            .allowsHitTesting(false)

            // Inner shadow top
            LinearGradient(
                colors: [Color(hex: "1A3008").opacity(0.15), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .allowsHitTesting(false)
        }
        .onReceive(animTimer) { _ in
            if isWindowVisible { animFrame += 1 }
        }
        .onReceive(ticker) { _ in
            tick += 1
            // Slow pulse for NEEDS INPUT (D-16) — sine wave oscillating 0.4 to 1.0
            if monitor.state == .needsInput {
                pulseOpacity = 0.4 + 0.6 * (0.5 + 0.5 * sin(Double(tick) * .pi))
            }
        }
        .onReceive(blinkTimer) { _ in
            // Fast blink only for APPROVE? (D-16, Pitfall 5)
            if monitor.state == .approveQuestion {
                blinkOn.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didChangeOcclusionStateNotification)) { notification in
            if let window = notification.object as? NSWindow {
                isWindowVisible = window.occlusionState.contains(.visible)
            }
        }
        .onChange(of: monitor.state) { oldState, newState in
            guard oldState != newState else { return }
            // Reset per-state animation vars
            blinkOn = true
            pulseOpacity = 1.0

            // Glitch entrance for ERROR (D-17)
            if newState == .error {
                glitchActive = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    glitchActive = false
                }
            }

            // Bounce animation (existing)
            withAnimation(.easeOut(duration: 0.1)) {
                bounceOffset = -4
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeIn(duration: 0.15)) {
                    bounceOffset = 0
                }
            }
        }
    }

    // MARK: - Text

    private var titleText: String {
        switch monitor.state {
        case .idle: return "ZZZ..."
        case .working: return "WORKING"
        case .done: return "DONE!"
        case .error: return "ERROR"
        case .approveQuestion: return "APPROVE?"
        case .needsInput: return "NEEDS INPUT"
        }
    }

    private var detailText: String? {
        switch monitor.state {
        case .working:
            // D-06: Humanized tool context, truncated to 30 chars, marquee scrolls if longer
            let tool = humanToolName(monitor.currentTool ?? "")
            let elapsed = monitor.elapsedSeconds
            let detail = "\(tool) \u{00B7} \(elapsed)s"
            return String(detail.prefix(30))
        case .done:
            // D-07: First ~50 chars of last_assistant_message
            if let summary = monitor.lastSummary, !summary.isEmpty {
                return String(summary.prefix(50))
            }
            return nil
        case .idle:
            // D-08: Elapsed idle time — "Idle 5m", "Idle 2h"
            if let start = monitor.idleStartTime {
                let elapsed = Int(Date().timeIntervalSince(start))
                if elapsed < 60 { return "Idle \(elapsed)s" }
                else if elapsed < 3600 { return "Idle \(elapsed / 60)m" }
                else { return "Idle \(elapsed / 3600)h" }
            }
            return nil
        case .approveQuestion:
            // D-09: Tool + permission summary, truncated to 30 chars
            if let p = monitor.pendingPermission {
                let tool = humanToolName(p.tool)
                let detail = "\(tool) \u{00B7} \(p.summary)"
                return String(detail.prefix(30))
            }
            return nil
        case .needsInput:
            // D-10: Notification message truncated to 30 chars
            if let msg = monitor.inputMessage {
                return String(msg.prefix(30))
            }
            return nil
        case .error:
            // D-11: Error detail from StopFailure, truncated to 30 chars
            return monitor.errorDetail
        }
    }

    // MARK: - Animation

    private var titleOpacity: Double {
        switch monitor.state {
        case .approveQuestion:
            return blinkOn ? 1.0 : 0.0  // Fast blink (D-16)
        case .needsInput:
            return pulseOpacity  // Slow pulse (D-16)
        default:
            return 1.0
        }
    }

    // MARK: - Tool Name

    private func humanToolName(_ tool: String) -> String {
        switch tool.lowercased() {
        case "bash": return "Running"
        case "read": return "Reading"
        case "write": return "Writing"
        case "edit": return "Editing"
        case "grep": return "Searching"
        case "glob": return "Finding"
        case "agent": return "Thinking"
        case "webfetch": return "Fetching"
        case "websearch": return "Searching"
        default: return tool
        }
    }
}

// MARK: - Marquee Scrolling Text

struct MarqueeText: View {
    let text: String
    let font: Font
    let color: Color
    let speed: Double = 30

    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var scrollTimer: Timer?

    private var needsScroll: Bool { textWidth > containerWidth }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Text(text)
                    .font(font)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .fixedSize()
                    .offset(x: needsScroll ? offset : 0)
                    .onAppear {
                        containerWidth = geo.size.width
                    }
                    .onChange(of: geo.size.width) {
                        containerWidth = geo.size.width
                    }
                    .background(
                        GeometryReader { textGeo in
                            Color.clear.onAppear {
                                textWidth = textGeo.size.width
                                startScrollIfNeeded()
                            }
                            .onChange(of: text) {
                                textWidth = textGeo.size.width
                                offset = 0
                                startScrollIfNeeded()
                            }
                        }
                    )
            }
            .frame(width: geo.size.width, alignment: .leading)
            .clipped()
            .mask(
                HStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .white], startPoint: .leading, endPoint: .trailing)
                        .frame(width: needsScroll ? 8 : 0)
                    Rectangle().fill(Color.white)
                    LinearGradient(colors: [.white, .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: needsScroll ? 8 : 0)
                }
            )
        }
    }

    private func startScrollIfNeeded() {
        scrollTimer?.invalidate()
        guard needsScroll else { return }

        let totalDistance = textWidth - containerWidth + 20

        scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            if offset > -totalDistance {
                offset -= 0.9
            } else {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    offset = 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        startScrollIfNeeded()
                    }
                }
            }
        }
    }
}
