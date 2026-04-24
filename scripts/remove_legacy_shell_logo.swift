import AppKit
import CoreGraphics
import Foundation

struct Region {
    let target: CGRect   // top-left based pixels
    let sample: CGRect   // top-left based pixels
}

func averageColor(bitmap: NSBitmapImageRep, rect: CGRect) -> NSColor {
    var r = 0.0
    var g = 0.0
    var b = 0.0
    var a = 0.0
    var count = 0.0

    for x in Int(rect.minX)..<Int(rect.maxX) {
        for y in Int(rect.minY)..<Int(rect.maxY) {
            guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
            r += Double(color.redComponent)
            g += Double(color.greenComponent)
            b += Double(color.blueComponent)
            a += Double(color.alphaComponent)
            count += 1
        }
    }

    return NSColor(
        deviceRed: r / count,
        green: g / count,
        blue: b / count,
        alpha: a / count
    )
}

func paint(bitmap: NSBitmapImageRep, rect: CGRect, color: NSColor) {
    guard let bitmapData = bitmap.bitmapData else { return }
    guard let context = CGContext(
        data: bitmapData,
        width: bitmap.pixelsWide,
        height: bitmap.pixelsHigh,
        bitsPerComponent: 8,
        bytesPerRow: bitmap.bytesPerRow,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        return
    }

    context.setFillColor(color.cgColor)
    context.fill(
        CGRect(
            x: rect.minX,
            y: CGFloat(bitmap.pixelsHigh) - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    )
}

let root = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? FileManager.default.currentDirectoryPath)
let shellsDir = root.appendingPathComponent("Sources/shells", isDirectory: true)
let fm = FileManager.default

let largeRegion = Region(
    target: CGRect(x: 190, y: 58, width: 250, height: 62),
    sample: CGRect(x: 470, y: 68, width: 60, height: 36)
)
let smallRegion = Region(
    target: CGRect(x: 120, y: 44, width: 182, height: 48),
    sample: CGRect(x: 310, y: 48, width: 32, height: 28)
)

for name in try fm.contentsOfDirectory(atPath: shellsDir.path).sorted() where name.hasSuffix(".png") {
    let region = name.contains("beeper-small-") ? smallRegion : largeRegion
    let fileURL = shellsDir.appendingPathComponent(name)

    guard
        let image = NSImage(contentsOf: fileURL),
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff)
    else {
        continue
    }

    let fillColor = averageColor(bitmap: bitmap, rect: region.sample)
    paint(bitmap: bitmap, rect: region.target, color: fillColor)

    if let data = bitmap.representation(using: .png, properties: [:]) {
        try data.write(to: fileURL)
        print("cleaned \(name)")
    }
}
