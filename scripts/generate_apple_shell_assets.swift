import AppKit
import CoreGraphics
import Foundation

extension NSColor {
    convenience init(hex: String, alpha: CGFloat = 1) {
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        self.init(
            calibratedRed: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: alpha
        )
    }

    var deviceRGB: CGColor {
        usingColorSpace(.deviceRGB)?.cgColor ?? cgColor
    }
}

private func fillRounded(_ context: CGContext, _ rect: CGRect, radius: CGFloat, color: NSColor) {
    context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.setFillColor(color.deviceRGB)
    context.fillPath()
}

private func strokeRounded(_ context: CGContext, _ rect: CGRect, radius: CGFloat, color: NSColor, width: CGFloat) {
    context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.setStrokeColor(color.deviceRGB)
    context.setLineWidth(width)
    context.strokePath()
}

private func drawLinearGradient(_ context: CGContext, _ rect: CGRect, colors: [NSColor]) {
    guard let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors.map(\.deviceRGB) as CFArray,
        locations: nil
    ) else { return }

    context.saveGState()
    context.addPath(CGPath(roundedRect: rect, cornerWidth: 10, cornerHeight: 10, transform: nil))
    context.clip()
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: rect.minX, y: rect.minY),
        end: CGPoint(x: rect.maxX, y: rect.maxY),
        options: []
    )
    context.restoreGState()
}

private func drawClassicRainbowAppleLogo(_ context: CGContext, at origin: CGPoint, scale: CGFloat) {
    let logo = CGRect(x: origin.x, y: origin.y, width: 20 * scale, height: 23 * scale)
    let biteCutoutColor = NSColor(hex: "E5DAC0")
    let bodyPath = CGMutablePath()

    bodyPath.move(to: CGPoint(x: logo.minX + 0.52 * logo.width, y: logo.minY + 0.22 * logo.height))
    bodyPath.addCurve(
        to: CGPoint(x: logo.minX + 0.34 * logo.width, y: logo.minY + 0.15 * logo.height),
        control1: CGPoint(x: logo.minX + 0.47 * logo.width, y: logo.minY + 0.14 * logo.height),
        control2: CGPoint(x: logo.minX + 0.40 * logo.width, y: logo.minY + 0.12 * logo.height)
    )
    bodyPath.addCurve(
        to: CGPoint(x: logo.minX + 0.14 * logo.width, y: logo.minY + 0.34 * logo.height),
        control1: CGPoint(x: logo.minX + 0.22 * logo.width, y: logo.minY + 0.16 * logo.height),
        control2: CGPoint(x: logo.minX + 0.15 * logo.width, y: logo.minY + 0.25 * logo.height)
    )
    bodyPath.addCurve(
        to: CGPoint(x: logo.minX + 0.23 * logo.width, y: logo.minY + 0.82 * logo.height),
        control1: CGPoint(x: logo.minX + 0.05 * logo.width, y: logo.minY + 0.49 * logo.height),
        control2: CGPoint(x: logo.minX + 0.09 * logo.width, y: logo.minY + 0.72 * logo.height)
    )
    bodyPath.addCurve(
        to: CGPoint(x: logo.minX + 0.43 * logo.width, y: logo.minY + 0.91 * logo.height),
        control1: CGPoint(x: logo.minX + 0.31 * logo.width, y: logo.minY + 0.90 * logo.height),
        control2: CGPoint(x: logo.minX + 0.37 * logo.width, y: logo.minY + 0.95 * logo.height)
    )
    bodyPath.addCurve(
        to: CGPoint(x: logo.minX + 0.57 * logo.width, y: logo.minY + 0.91 * logo.height),
        control1: CGPoint(x: logo.minX + 0.48 * logo.width, y: logo.minY + 0.87 * logo.height),
        control2: CGPoint(x: logo.minX + 0.52 * logo.width, y: logo.minY + 0.87 * logo.height)
    )
    bodyPath.addCurve(
        to: CGPoint(x: logo.minX + 0.78 * logo.width, y: logo.minY + 0.80 * logo.height),
        control1: CGPoint(x: logo.minX + 0.66 * logo.width, y: logo.minY + 0.97 * logo.height),
        control2: CGPoint(x: logo.minX + 0.73 * logo.width, y: logo.minY + 0.90 * logo.height)
    )
    bodyPath.addCurve(
        to: CGPoint(x: logo.minX + 0.86 * logo.width, y: logo.minY + 0.36 * logo.height),
        control1: CGPoint(x: logo.minX + 0.91 * logo.width, y: logo.minY + 0.63 * logo.height),
        control2: CGPoint(x: logo.minX + 0.93 * logo.width, y: logo.minY + 0.47 * logo.height)
    )
    bodyPath.addCurve(
        to: CGPoint(x: logo.minX + 0.63 * logo.width, y: logo.minY + 0.19 * logo.height),
        control1: CGPoint(x: logo.minX + 0.80 * logo.width, y: logo.minY + 0.24 * logo.height),
        control2: CGPoint(x: logo.minX + 0.72 * logo.width, y: logo.minY + 0.17 * logo.height)
    )
    bodyPath.addCurve(
        to: CGPoint(x: logo.minX + 0.52 * logo.width, y: logo.minY + 0.22 * logo.height),
        control1: CGPoint(x: logo.minX + 0.58 * logo.width, y: logo.minY + 0.20 * logo.height),
        control2: CGPoint(x: logo.minX + 0.55 * logo.width, y: logo.minY + 0.21 * logo.height)
    )
    bodyPath.closeSubpath()

    context.saveGState()
    context.addPath(bodyPath)
    context.clip()

    let stripeColors = ["5EB24F", "F4D34D", "F08B31", "E94648", "8E67B5", "5B7DDB"].map { NSColor(hex: $0) }
    let stripeHeight = logo.height * 0.72 / CGFloat(stripeColors.count)
    let stripeStartY = logo.minY + logo.height * 0.22
    for (index, color) in stripeColors.enumerated() {
        context.setFillColor(color.deviceRGB)
        context.fill(CGRect(
            x: logo.minX - 1 * scale,
            y: stripeStartY + CGFloat(index) * stripeHeight,
            width: logo.width + 2 * scale,
            height: stripeHeight + 0.6 * scale
        ))
    }

    context.restoreGState()

    context.setFillColor(biteCutoutColor.deviceRGB)
    context.fillEllipse(in: CGRect(
        x: logo.minX + 0.74 * logo.width,
        y: logo.minY + 0.32 * logo.height,
        width: 0.26 * logo.width,
        height: 0.22 * logo.height
    ))

    let leafPath = CGMutablePath()
    leafPath.move(to: CGPoint(x: logo.minX + 0.50 * logo.width, y: logo.minY + 0.14 * logo.height))
    leafPath.addCurve(
        to: CGPoint(x: logo.minX + 0.78 * logo.width, y: logo.minY + 0.01 * logo.height),
        control1: CGPoint(x: logo.minX + 0.56 * logo.width, y: logo.minY + 0.01 * logo.height),
        control2: CGPoint(x: logo.minX + 0.69 * logo.width, y: logo.minY - 0.02 * logo.height)
    )
    leafPath.addCurve(
        to: CGPoint(x: logo.minX + 0.58 * logo.width, y: logo.minY + 0.19 * logo.height),
        control1: CGPoint(x: logo.minX + 0.77 * logo.width, y: logo.minY + 0.12 * logo.height),
        control2: CGPoint(x: logo.minX + 0.67 * logo.width, y: logo.minY + 0.18 * logo.height)
    )
    leafPath.closeSubpath()
    context.addPath(leafPath)
    context.setFillColor(NSColor(hex: "5EB24F").deviceRGB)
    context.fillPath()
}

private func drawDriveSlot(_ context: CGContext, _ rect: CGRect) {
    fillRounded(context, rect, radius: 1.5, color: NSColor(hex: "27231C"))
    fillRounded(
        context,
        CGRect(x: rect.minX - 4, y: rect.midY - 1.2, width: rect.width * 0.78, height: 2.4),
        radius: 1.2,
        color: NSColor(hex: "F7EFD9")
    )
    fillRounded(
        context,
        CGRect(x: rect.maxX - 13, y: rect.minY + 1.5, width: 9, height: rect.height - 3),
        radius: 1,
        color: NSColor(hex: "181611")
    )
}

private func drawAppleShell(context: CGContext, size: CGSize, compact: Bool) {
    let body = CGRect(x: compact ? 4 : 5, y: compact ? 4 : 5, width: size.width - (compact ? 8 : 10), height: size.height - (compact ? 9 : 10))
    let shadow = body.offsetBy(dx: 0, dy: compact ? 4 : 6)
    fillRounded(context, shadow, radius: compact ? 9 : 13, color: NSColor(hex: "6D624A", alpha: 0.22))
    drawLinearGradient(context, body, colors: [NSColor(hex: "F5EFD9"), NSColor(hex: "E1D6BA"), NSColor(hex: "C9BFA3")])
    strokeRounded(context, body.insetBy(dx: 1, dy: 1), radius: compact ? 9 : 13, color: NSColor(hex: "FFF7E4", alpha: 0.9), width: 2)
    strokeRounded(context, body.insetBy(dx: 3, dy: 3), radius: compact ? 7 : 11, color: NSColor(hex: "B4AA8F", alpha: 0.65), width: 1)

    let recess = compact
        ? CGRect(x: 20, y: 14, width: 181, height: 72)
        : CGRect(x: 28, y: 13, width: 310, height: 92)
    fillRounded(context, recess, radius: compact ? 7 : 10, color: NSColor(hex: "D4CAB0"))
    strokeRounded(context, recess.insetBy(dx: 1, dy: 1), radius: compact ? 7 : 10, color: NSColor(hex: "FFF5DF", alpha: 0.75), width: 1.5)
    strokeRounded(context, recess.insetBy(dx: 4, dy: 4), radius: compact ? 5 : 8, color: NSColor(hex: "AFA58C", alpha: 0.55), width: 1)

    let screenOuter = compact
        ? CGRect(x: 25, y: 20, width: 172, height: 63)
        : CGRect(x: 40, y: 24, width: 286, height: 70)
    fillRounded(context, screenOuter.insetBy(dx: -3, dy: -3), radius: compact ? 5 : 7, color: NSColor(hex: "1A2117"))
    fillRounded(context, screenOuter, radius: compact ? 4 : 6, color: NSColor(hex: "B8C1A3"))
    strokeRounded(context, screenOuter.insetBy(dx: 1, dy: 1), radius: compact ? 4 : 6, color: NSColor(hex: "647050"), width: compact ? 1 : 1.2)

    let screenShade = screenOuter.insetBy(dx: compact ? 5 : 8, dy: compact ? 5 : 7)
    fillRounded(context, screenShade, radius: compact ? 2 : 3, color: NSColor(hex: "AAB592", alpha: 0.45))
    strokeRounded(context, screenOuter.insetBy(dx: -1, dy: -1), radius: compact ? 5 : 7, color: NSColor(hex: "10160F"), width: compact ? 1.4 : 1.8)

    if compact {
        drawClassicRainbowAppleLogo(context, at: CGPoint(x: 29, y: 86), scale: 0.72)
        drawDriveSlot(context, CGRect(x: 156, y: 87, width: 39, height: 5))
    } else {
        drawClassicRainbowAppleLogo(context, at: CGPoint(x: 38, y: 116), scale: 1.08)
        drawDriveSlot(context, CGRect(x: 249, y: 124, width: 67, height: 6))
    }
}

private func renderAppleShell(logicalSize: CGSize, scale: CGFloat, compact: Bool) -> Data {
    let pixelSize = CGSize(width: logicalSize.width * scale, height: logicalSize.height * scale)
    let image = NSImage(size: pixelSize)

    image.lockFocus()
    guard let context = NSGraphicsContext.current?.cgContext else {
        fatalError("Unable to create graphics context")
    }
    context.clear(CGRect(origin: .zero, size: pixelSize))
    context.translateBy(x: 0, y: pixelSize.height)
    context.scaleBy(x: scale, y: -scale)
    drawAppleShell(context: context, size: logicalSize, compact: compact)
    image.unlockFocus()

    guard
        let tiff = image.tiffRepresentation,
        let rep = NSBitmapImageRep(data: tiff),
        let data = rep.representation(using: .png, properties: [:])
    else {
        fatalError("Unable to encode PNG")
    }
    return data
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let shellDir = root.appendingPathComponent("Sources/shells", isDirectory: true)

try renderAppleShell(logicalSize: CGSize(width: 366, height: 160), scale: 4, compact: false)
    .write(to: shellDir.appendingPathComponent("vibe-beeper-apple.png"), options: .atomic)
try renderAppleShell(logicalSize: CGSize(width: 222, height: 114), scale: 4, compact: true)
    .write(to: shellDir.appendingPathComponent("vibe-beeper-small-apple.png"), options: .atomic)
