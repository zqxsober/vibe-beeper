import SwiftUI

enum OldSchoolPalette {
    static let caseTop = Color(hex: "F3EBD8")
    static let caseMid = Color(hex: "E7DCC2")
    static let caseBottom = Color(hex: "CFC09B")
    static let caseStroke = Color(hex: "9A8E72")
    static let bevelLight = Color(hex: "FFF8E8")
    static let bevelDark = Color(hex: "AFA17E")
    static let shadow = Color(hex: "6D634F")
    static let lcdFrame = Color(hex: "141710")
    static let lcdGlass = Color(hex: "A6B58A")
    static let lcdDark = Color(hex: "2F3A29")
    static let lcdLine = Color(hex: "40503A")
    static let keyTop = Color(hex: "F8F0D9")
    static let keyBottom = Color(hex: "D4C6A5")
    static let keyText = Color(hex: "242016")
    static let disabledText = Color(hex: "837A68")
}

struct OldSchoolDesktopMacBody: View {
    let includesKeyboardBase: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let upperHeight = includesKeyboardBase ? size.height * 0.78 : size.height

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: size.width * 0.055, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [OldSchoolPalette.caseTop, OldSchoolPalette.caseMid, OldSchoolPalette.caseBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size.width, height: upperHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: size.width * 0.055, style: .continuous)
                            .stroke(OldSchoolPalette.caseStroke.opacity(0.45), lineWidth: max(1, size.width * 0.004))
                    )
                    .shadow(color: OldSchoolPalette.shadow.opacity(0.42), radius: size.width * 0.035, x: 0, y: size.height * 0.028)

                RoundedRectangle(cornerRadius: size.width * 0.043, style: .continuous)
                    .stroke(OldSchoolPalette.bevelLight.opacity(0.7), lineWidth: max(1, size.width * 0.005))
                    .frame(width: size.width * 0.94, height: upperHeight * 0.90)
                    .offset(x: size.width * 0.03, y: upperHeight * 0.04)

                RoundedRectangle(cornerRadius: size.width * 0.025, style: .continuous)
                    .fill(Color.black.opacity(0.11))
                    .frame(width: size.width * 0.77, height: upperHeight * 0.58)
                    .offset(x: size.width * 0.115, y: upperHeight * 0.12)
                    .shadow(color: Color.white.opacity(0.36), radius: size.width * 0.012, x: -1, y: -1)

                if includesKeyboardBase {
                    OldSchoolKeyboardBase()
                        .frame(width: size.width * 0.98, height: size.height * 0.26)
                        .offset(x: size.width * 0.01, y: upperHeight - size.height * 0.02)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct OldSchoolKeyboardBase: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack(alignment: .topLeading) {
                KeyboardBaseShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                OldSchoolPalette.bevelLight,
                                OldSchoolPalette.caseTop,
                                OldSchoolPalette.caseMid,
                                OldSchoolPalette.caseBottom,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        KeyboardBaseShape()
                            .stroke(OldSchoolPalette.caseStroke.opacity(0.46), lineWidth: max(1, size.width * 0.004))
                    )
                    .shadow(color: Color.white.opacity(0.34), radius: size.width * 0.012, x: -1, y: -1)
                    .shadow(color: OldSchoolPalette.shadow.opacity(0.38), radius: size.width * 0.024, x: 0, y: size.height * 0.08)

                KeyboardBaseTrayShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                OldSchoolPalette.caseBottom.opacity(0.72),
                                OldSchoolPalette.caseTop.opacity(0.96),
                                OldSchoolPalette.caseMid,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size.width * 0.88, height: size.height * 0.56)
                    .offset(x: size.width * 0.06, y: size.height * 0.18)
                    .overlay(
                        KeyboardBaseTrayShape()
                            .stroke(OldSchoolPalette.bevelLight.opacity(0.82), lineWidth: max(1, size.height * 0.030))
                            .frame(width: size.width * 0.88, height: size.height * 0.56)
                            .offset(x: size.width * 0.06, y: size.height * 0.18)
                    )
                    .overlay(
                        KeyboardBaseTrayShape()
                            .stroke(OldSchoolPalette.caseStroke.opacity(0.28), lineWidth: max(1, size.height * 0.015))
                            .frame(width: size.width * 0.86, height: size.height * 0.50)
                            .offset(x: size.width * 0.07, y: size.height * 0.21)
                    )

                KeyboardBaseFrontEdgeShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                OldSchoolPalette.caseMid.opacity(0.55),
                                OldSchoolPalette.caseBottom,
                                OldSchoolPalette.shadow.opacity(0.42),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size.width * 0.97, height: size.height * 0.18)
                    .offset(x: size.width * 0.015, y: size.height * 0.82)
                    .overlay(
                        KeyboardBaseFrontEdgeShape()
                            .stroke(OldSchoolPalette.caseStroke.opacity(0.34), lineWidth: max(1, size.height * 0.012))
                            .frame(width: size.width * 0.97, height: size.height * 0.18)
                            .offset(x: size.width * 0.015, y: size.height * 0.82)
                    )
            }
        }
        .allowsHitTesting(false)
    }
}

private struct KeyboardBaseShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let topInset = rect.width * 0.055
        let radius = rect.height * 0.16

        path.move(to: CGPoint(x: rect.minX + topInset + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topInset - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - topInset, y: rect.minY + radius),
            control: CGPoint(x: rect.maxX - topInset, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - radius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + topInset, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + topInset + radius, y: rect.minY),
            control: CGPoint(x: rect.minX + topInset, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}

private struct KeyboardBaseTrayShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = rect.height * 0.18
        let topInset = rect.width * 0.035

        path.move(to: CGPoint(x: rect.minX + topInset + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topInset - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - topInset, y: rect.minY + radius),
            control: CGPoint(x: rect.maxX - topInset, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - radius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + topInset, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + topInset + radius, y: rect.minY),
            control: CGPoint(x: rect.minX + topInset, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}

private struct KeyboardBaseFrontEdgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = rect.height * 0.32
        let inset = rect.width * 0.025

        path.move(to: CGPoint(x: rect.minX + inset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - radius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

struct OldSchoolLCDPanel<Content: View>: View {
    let cornerRadius: CGFloat
    let inset: CGFloat
    let contentPadding: CGFloat
    let content: Content

    init(
        cornerRadius: CGFloat = 7,
        inset: CGFloat = 6,
        contentPadding: CGFloat = 9,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.inset = inset
        self.contentPadding = contentPadding
        self.content = content()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(OldSchoolPalette.lcdFrame)
                .shadow(color: Color.black.opacity(0.52), radius: 4, x: 0, y: 3)
            RoundedRectangle(cornerRadius: innerCornerRadius, style: .continuous)
                .fill(OldSchoolPalette.lcdGlass)
                .padding(inset)
                .overlay(
                    RoundedRectangle(cornerRadius: innerCornerRadius, style: .continuous)
                        .stroke(OldSchoolPalette.lcdDark.opacity(0.42), lineWidth: 1)
                        .padding(inset)
                )

            Canvas { context, size in
                let lineColor = OldSchoolPalette.lcdDark.opacity(0.08)
                let step: CGFloat = 2
                var x = inset
                while x < size.width - inset {
                    context.fill(
                        Path(CGRect(x: x, y: inset, width: 0.5, height: size.height - inset * 2)),
                        with: .color(lineColor)
                    )
                    x += step
                }
                var y = inset
                while y < size.height - inset {
                    context.fill(
                        Path(CGRect(x: inset, y: y, width: size.width - inset * 2, height: 0.5)),
                        with: .color(lineColor)
                    )
                    y += step
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: innerCornerRadius, style: .continuous).inset(by: inset))
            .allowsHitTesting(false)

            RadialGradient(
                colors: [.clear, OldSchoolPalette.lcdDark.opacity(0.18)],
                center: .center,
                startRadius: 10,
                endRadius: 150
            )
            .padding(inset)
            .clipShape(RoundedRectangle(cornerRadius: innerCornerRadius, style: .continuous).inset(by: inset))
            .allowsHitTesting(false)

            content
                .padding(contentPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .clipped()
        }
    }

    private var innerCornerRadius: CGFloat {
        max(cornerRadius - 3, 0)
    }
}

struct OldSchoolReferenceScreen: View {
    var compact: Bool = false

    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("useChineseRuntimeCopy") private var useChineseRuntimeCopy = false
    @State private var animFrame = 0
    @State private var tick = 0

    private let animTimer = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { proxy in
            let metrics = OldSchoolScreenMetrics(size: proxy.size, compact: compact)

            VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
                HStack(spacing: metrics.headerSpacing) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: metrics.headerIconSize, weight: .black))
                    Text("VIBE-BEEPER")
                        .font(.system(size: metrics.headerTextSize, weight: .black, design: .monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                    Spacer(minLength: 0)
                }
                .foregroundStyle(OldSchoolPalette.lcdDark)

                Rectangle()
                    .fill(OldSchoolPalette.lcdLine.opacity(0.78))
                    .frame(height: metrics.separatorHeight)

                HStack(alignment: .center, spacing: metrics.bodySpacing) {
                    PixelCharacterView(
                        state: monitor.state,
                        frame: animFrame,
                        onColor: OldSchoolPalette.lcdDark,
                        pixelSize: metrics.pixelSize
                    )
                    .frame(width: metrics.characterWidth, height: metrics.characterHeight)

                    VStack(alignment: .leading, spacing: metrics.textSpacing) {
                        Text(displayTitleText)
                            .font(.system(size: metrics.titleTextSize, weight: .black, design: .monospaced))
                            .lineLimit(1)
                            .minimumScaleFactor(0.48)
                            .allowsTightening(true)
                        Text(detailText)
                            .font(.system(size: metrics.detailTextSize, weight: .bold, design: .monospaced))
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                            .allowsTightening(true)
                            .opacity(0.82)
                    }
                    .foregroundStyle(OldSchoolPalette.lcdDark)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)

                    presetBadge(metrics: metrics)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .onReceive(animTimer) { _ in animFrame += 1 }
        .onReceive(ticker) { _ in tick += 1 }
        .allowsHitTesting(false)
    }

    private func presetBadge(metrics: OldSchoolScreenMetrics) -> some View {
        HStack(spacing: metrics.badgeSpacing) {
            Image(systemName: monitor.currentPreset.badgeIcon)
                .font(.system(size: metrics.badgeIconSize, weight: .black))
            Text(monitor.currentPreset.badgeLabel)
                .font(.system(size: metrics.badgeTextSize, weight: .black, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .foregroundStyle(OldSchoolPalette.lcdDark)
        .padding(.horizontal, metrics.badgeHorizontalPadding)
        .padding(.vertical, metrics.badgeVerticalPadding)
        .overlay(
            RoundedRectangle(cornerRadius: metrics.badgeCornerRadius, style: .continuous)
                .stroke(OldSchoolPalette.lcdDark.opacity(0.86), lineWidth: metrics.badgeStrokeWidth)
        )
    }

    private var displayTitleText: String {
        return shouldShowActivityDots ? "\(titleText)..." : titleText
    }

    private var titleText: String {
        if useChineseRuntimeCopy {
            switch monitor.state {
            case .idle: return "摸鱼中"
            case .working: return "搬砖中"
            case .done: return "搞定啦"
            case .error: return "翻车了"
            case .approveQuestion: return "等放行"
            case .needsInput: return "喊你呢"
            case .listening: return "听着呢"
            case .speaking: return "开讲啦"
            }
        }

        switch monitor.state {
        case .idle: return "SNOOZING"
        case .working: return "WORKING"
        case .done: return "DONE!"
        case .error: return "ERROR"
        case .approveQuestion: return "ALLOW?"
        case .needsInput: return "INPUT?"
        case .listening: return "LISTENING"
        case .speaking: return "RECAP"
        }
    }

    private var detailText: String {
        let prefix: String
        switch monitor.state {
        case .idle: prefix = useChineseRuntimeCopy ? "省电模式" : "Idle"
        case .working: prefix = monitor.currentTool?.isEmpty == false ? monitor.currentTool! : (useChineseRuntimeCopy ? "工具上场" : "Running")
        case .done: prefix = useChineseRuntimeCopy ? "轮到你啦" : "Your turn"
        case .error: prefix = monitor.errorDetail?.isEmpty == false ? monitor.errorDetail! : (useChineseRuntimeCopy ? "需要救场" : "Needs help")
        case .approveQuestion: prefix = monitor.pendingPermission?.tool.isEmpty == false ? monitor.pendingPermission!.tool : (useChineseRuntimeCopy ? "求放行" : "Permission")
        case .needsInput: prefix = monitor.inputMessage?.isEmpty == false ? monitor.inputMessage! : (useChineseRuntimeCopy ? "等你回话" : "Input needed")
        case .listening: prefix = useChineseRuntimeCopy ? "麦开啦" : "Mic on"
        case .speaking: prefix = useChineseRuntimeCopy ? "给你复盘" : "Recap"
        }

        return "\(prefix) · \(elapsedText)"
    }

    private var elapsedText: String {
        let elapsed: Int
        if let start = monitor.idleStartTime, monitor.state == .idle {
            elapsed = Int(Date().timeIntervalSince(start))
        } else {
            elapsed = tick
        }

        if elapsed < 60 { return "\(elapsed)s" }
        if elapsed < 3600 { return "\(elapsed / 60)m" }
        return "\(elapsed / 3600)h"
    }

    private var shouldShowActivityDots: Bool {
        switch monitor.state {
        case .working, .approveQuestion, .needsInput: return true
        default: return false
        }
    }
}

private struct OldSchoolScreenMetrics {
    let size: CGSize
    let compact: Bool

    private var scale: CGFloat {
        if compact {
            return min(size.width / 210, size.height / 98)
        }
        return min(size.width / 282, size.height / 154)
    }

    var sectionSpacing: CGFloat { compact ? max(2, 6 * scale) : max(6, 9 * scale) }
    var headerSpacing: CGFloat { compact ? max(3, 4 * scale) : max(5, 8 * scale) }
    var headerIconSize: CGFloat { compact ? max(9, 13 * scale) : max(14, 20 * scale) }
    var headerTextSize: CGFloat { compact ? max(11, 14 * scale) : max(17, 22 * scale) }
    var separatorHeight: CGFloat { compact ? 1 : max(1.5, 2 * scale) }
    var bodySpacing: CGFloat { compact ? max(7, 9 * scale) : max(12, 18 * scale) }
    var characterWidth: CGFloat { compact ? max(38, 42 * scale) : max(52, 64 * scale) }
    var characterHeight: CGFloat { compact ? max(36, 42 * scale) : max(54, 68 * scale) }
    var pixelSize: CGFloat { compact ? max(2.8, 3.1 * scale) : max(4.0, 4.6 * scale) }
    var textSpacing: CGFloat { compact ? max(1, 3 * scale) : max(4, 7 * scale) }
    var titleTextSize: CGFloat { compact ? max(17, 21 * scale) : max(25, 30 * scale) }
    var detailTextSize: CGFloat { compact ? max(10, 12 * scale) : max(14, 17 * scale) }
    var badgeSpacing: CGFloat { compact ? max(2, 4 * scale) : max(4, 6 * scale) }
    var badgeIconSize: CGFloat { compact ? max(9, 11 * scale) : max(13, 15 * scale) }
    var badgeTextSize: CGFloat { compact ? max(9, 11 * scale) : max(13, 15 * scale) }
    var badgeHorizontalPadding: CGFloat { compact ? max(5, 7 * scale) : max(8, 11 * scale) }
    var badgeVerticalPadding: CGFloat { compact ? max(3, 4 * scale) : max(5, 7 * scale) }
    var badgeCornerRadius: CGFloat { compact ? max(4, 5 * scale) : max(6, 8 * scale) }
    var badgeStrokeWidth: CGFloat { compact ? 1 : max(1.5, 2 * scale) }
}

struct OldSchoolAppleLogo: View {
    var size: CGFloat = 38

    private let colors: [Color] = [
        Color(hex: "61B96D"),
        Color(hex: "F0D254"),
        Color(hex: "F0A040"),
        Color(hex: "DE5A58"),
        Color(hex: "5E83D9"),
    ]

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ForEach(colors.indices, id: \.self) { index in
                    colors[index]
                }
            }
            .mask(
                Image(systemName: "apple.logo")
                    .font(.system(size: size, weight: .regular))
            )

            Image(systemName: "apple.logo")
                .font(.system(size: size, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.28))
                .offset(x: -size * 0.02, y: -size * 0.04)
        }
        .frame(width: size * 1.05, height: size * 1.05)
        .shadow(color: Color.black.opacity(0.18), radius: size * 0.08, x: 0, y: size * 0.04)
        .allowsHitTesting(false)
    }
}

struct OldSchoolFloppyDrive: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: size.height * 0.18, style: .continuous)
                    .fill(Color(hex: "27231E"))
                    .frame(height: size.height * 0.56)
                    .overlay(
                        RoundedRectangle(cornerRadius: size.height * 0.18, style: .continuous)
                            .stroke(OldSchoolPalette.bevelLight.opacity(0.55), lineWidth: max(1, size.height * 0.07))
                    )
                    .shadow(color: Color.white.opacity(0.36), radius: 1, x: -1, y: -1)
                    .shadow(color: Color.black.opacity(0.32), radius: 2, x: 0, y: 1)

                RoundedRectangle(cornerRadius: size.height * 0.08, style: .continuous)
                    .fill(Color(hex: "0F0F0C"))
                    .frame(width: size.width * 0.29, height: size.height * 0.34)
                    .padding(.trailing, size.width * 0.08)

                RoundedRectangle(cornerRadius: size.height * 0.06, style: .continuous)
                    .fill(Color(hex: "6E6657"))
                    .frame(width: size.width * 0.08, height: size.height * 0.30)
                    .padding(.trailing, size.width * 0.04)
            }
            .frame(width: size.width, height: size.height, alignment: .center)
        }
        .allowsHitTesting(false)
    }
}

struct OldSchoolLED: View {
    let color: Color
    let active: Bool
    var size: CGFloat = 7

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .opacity(active ? 1.0 : 0.72)
            .shadow(color: color.opacity(active ? 0.75 : 0), radius: active ? 4 : 0)
            .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 1))
            .allowsHitTesting(false)
    }
}

struct OldSchoolControls: View {
    let permissionActive: Bool
    let isRecording: Bool
    let isSpeaking: Bool
    let onAccept: () -> Void
    let onDeny: () -> Void
    let onRecord: () -> Void
    let onStopSpeaking: () -> Void
    let onTerminal: () -> Void
    var keySize: CGSize = CGSize(width: 52, height: 46)
    var iconSize: CGFloat = 25
    var spacing: CGFloat = 18

    var body: some View {
        HStack(spacing: spacing) {
            OldSchoolKeyButton(icon: .check, isEnabled: permissionActive, keySize: keySize, iconSize: iconSize, action: onAccept)
                .help("Accept")
            OldSchoolKeyButton(icon: .cross, isEnabled: permissionActive, keySize: keySize, iconSize: iconSize, action: onDeny)
                .help("Deny")
            OldSchoolKeyButton(icon: isRecording ? .stop : .microphone, isEnabled: true, keySize: keySize, iconSize: iconSize, action: onRecord)
                .help(isRecording ? "Stop recording" : "Record")
            OldSchoolKeyButton(icon: .speaker, isEnabled: isSpeaking, keySize: keySize, iconSize: iconSize, action: onStopSpeaking)
                .help("Stop speaking")
            OldSchoolKeyButton(icon: .terminal, isEnabled: true, keySize: keySize, iconSize: iconSize, action: onTerminal)
                .help("Go to terminal")
        }
    }
}

struct OldSchoolKeyButton: View {
    let icon: OldSchoolPixelIconKind
    let isEnabled: Bool
    var keySize: CGSize = CGSize(width: 52, height: 46)
    var iconSize: CGFloat = 25
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            OldSchoolPixelIcon(kind: icon, color: isEnabled ? OldSchoolPalette.keyText : OldSchoolPalette.disabledText)
                .frame(width: iconSize, height: iconSize)
                .frame(width: keySize.width, height: keySize.height)
        }
        .buttonStyle(OldSchoolKeyButtonStyle(keySize: keySize))
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.55)
    }
}

struct OldSchoolKeyButtonStyle: ButtonStyle {
    var keySize: CGSize = CGSize(width: 52, height: 46)

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            OldSchoolKeyShadowShape()
                .fill(OldSchoolPalette.shadow.opacity(configuration.isPressed ? 0.22 : 0.48))
                .frame(width: keySize.width, height: keySize.height)
                .offset(y: configuration.isPressed ? keySize.height * 0.06 : keySize.height * 0.12)
                .blur(radius: configuration.isPressed ? 1.5 : 2.5)

            OldSchoolKeyFaceShape()
                .fill(
                    LinearGradient(
                        colors: configuration.isPressed
                            ? [OldSchoolPalette.keyBottom, OldSchoolPalette.keyTop]
                            : [OldSchoolPalette.keyTop, Color(hex: "EFE4C9"), OldSchoolPalette.keyBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    OldSchoolKeyFaceShape()
                        .stroke(OldSchoolPalette.caseStroke.opacity(0.78), lineWidth: 1.4)
                )
                .overlay(
                    OldSchoolKeyFaceShape()
                        .stroke(Color.white.opacity(configuration.isPressed ? 0.22 : 0.58), lineWidth: 1.2)
                        .padding(3)
                )
                .shadow(color: Color.white.opacity(configuration.isPressed ? 0.18 : 0.42), radius: 1.5, x: -1, y: -1)
                .shadow(color: Color.black.opacity(configuration.isPressed ? 0.10 : 0.22), radius: 2.5, x: 0, y: 1.5)

            configuration.label
                .offset(y: configuration.isPressed ? 1 : 0)
        }
        .frame(width: keySize.width, height: keySize.height + keySize.height * 0.16)
        .offset(y: configuration.isPressed ? 1 : 0)
    }
}

enum OldSchoolPixelIconKind {
    case check
    case cross
    case microphone
    case stop
    case speaker
    case terminal
}

struct OldSchoolPixelIcon: View {
    let kind: OldSchoolPixelIconKind
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let pattern = pixelPattern
            let columns = pattern.map(\.count).max() ?? 1
            let rows = pattern.count
            let unit = floor(min(proxy.size.width / CGFloat(columns), proxy.size.height / CGFloat(rows)))
            let width = unit * CGFloat(columns)
            let height = unit * CGFloat(rows)
            let originX = (proxy.size.width - width) / 2
            let originY = (proxy.size.height - height) / 2

            Canvas { context, _ in
                for row in pattern.indices {
                    for column in pattern[row].indices where pattern[row][column] == "1" {
                        let rect = CGRect(
                            x: originX + CGFloat(column) * unit,
                            y: originY + CGFloat(row) * unit,
                            width: unit,
                            height: unit
                        )
                        context.fill(Path(rect), with: .color(color))
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .allowsHitTesting(false)
    }

    private var pixelPattern: [[Character]] {
        patternLines.map { Array($0) }
    }

    private var patternLines: [String] {
        switch kind {
        case .check:
            return [
                "000000001",
                "000000010",
                "000000100",
                "100001000",
                "010010000",
                "001100000",
                "000000000",
                "000000000",
                "000000000",
            ]
        case .cross:
            return [
                "100000001",
                "010000010",
                "001000100",
                "000101000",
                "000010000",
                "000101000",
                "001000100",
                "010000010",
                "100000001",
            ]
        case .microphone:
            return [
                "000111000",
                "001111100",
                "001111100",
                "001111100",
                "001111100",
                "101111101",
                "100111001",
                "010111010",
                "000111000",
                "000111000",
                "001111100",
            ]
        case .stop:
            return [
                "000000000",
                "011111110",
                "011111110",
                "011111110",
                "011111110",
                "011111110",
                "011111110",
                "011111110",
                "000000000",
            ]
        case .speaker:
            return [
                "00001000100",
                "00011000010",
                "00111001001",
                "11111001001",
                "11111001001",
                "11111001001",
                "00111001001",
                "00011000010",
                "00001000100",
            ]
        case .terminal:
            return [
                "11111111111",
                "10000000001",
                "10000000001",
                "10110000001",
                "10011000001",
                "10110001101",
                "10000001101",
                "10000000001",
                "11111111111",
            ]
        }
    }
}

private struct OldSchoolKeyFaceShape: Shape {
    func path(in rect: CGRect) -> Path {
        let corner = rect.height * 0.12
        return RoundedRectangle(cornerRadius: corner, style: .continuous).path(in: rect)
    }
}

private struct OldSchoolKeyShadowShape: Shape {
    func path(in rect: CGRect) -> Path {
        let shadowRect = CGRect(
            x: rect.minX + rect.width * 0.03,
            y: rect.minY + rect.height * 0.05,
            width: rect.width * 0.94,
            height: rect.height * 0.86
        )
        return RoundedRectangle(cornerRadius: rect.height * 0.12, style: .continuous).path(in: shadowRect)
    }
}

struct OldSchoolPreviewMachine: View {
    var compact: Bool = false
    var showScreenContent: Bool = false

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let scale = min(size.width / 180, size.height / 142)
            let originX = (size.width - 180 * scale) / 2
            let originY = (size.height - 142 * scale) / 2

            ZStack(alignment: .topLeading) {
                OldSchoolDesktopMacBody(includesKeyboardBase: false)
                    .frame(width: 180 * scale, height: 142 * scale)
                    .offset(x: originX, y: originY)

                OldSchoolLCDPanel(cornerRadius: 5 * scale, inset: 3 * scale, contentPadding: 4 * scale) {
                    if showScreenContent {
                        OldSchoolStaticPreviewScreen(compact: compact)
                    }
                }
                .frame(width: 140 * scale, height: 81 * scale)
                .offset(x: originX + 23 * scale, y: originY + 19 * scale)

                OldSchoolAppleLogo(size: 16 * scale)
                    .offset(x: originX + 24 * scale, y: originY + 101 * scale)

                OldSchoolFloppyDrive()
                    .frame(width: 52 * scale, height: 10 * scale)
                    .offset(x: originX + 108 * scale, y: originY + 108 * scale)

                OldSchoolLED(color: Color(hex: "D64A3A"), active: true, size: 3.5 * scale)
                    .offset(x: originX + 163 * scale, y: originY + 111 * scale)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct OldSchoolStaticPreviewScreen: View {
    let compact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 1 : 3) {
            HStack(spacing: compact ? 2 : 4) {
                Image(systemName: "apple.logo")
                    .font(.system(size: compact ? 4 : 7, weight: .black))
                Text("VIBE-BEEPER")
                    .font(.system(size: compact ? 5 : 8, weight: .black, design: .monospaced))
                Spacer(minLength: 0)
            }

            Rectangle()
                .fill(OldSchoolPalette.lcdLine.opacity(0.78))
                .frame(height: 1)

            HStack(spacing: compact ? 2 : 4) {
                PixelCharacterView(state: .idle, frame: 0, onColor: OldSchoolPalette.lcdDark)
                    .frame(width: compact ? 10 : 18, height: compact ? 10 : 16)

                VStack(alignment: .leading, spacing: 0) {
                    Text("摸鱼中")
                        .font(.system(size: compact ? 7 : 12, weight: .black, design: .monospaced))
                    Text("省电模式 · 0s")
                        .font(.system(size: compact ? 4 : 6, weight: .bold, design: .monospaced))
                }

                Spacer(minLength: 0)
            }
        }
        .foregroundStyle(OldSchoolPalette.lcdDark)
    }
}
