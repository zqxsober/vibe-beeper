import SwiftUI

struct BrandBadgeView: View {
    var compact: Bool = false

    private var brandColor: Color { Color(hex: "6F6F6F") }
    private var bezelColor: Color { Color(hex: "171717") }
    private var iconSize: CGFloat { compact ? 6 : 8 }
    private var iconWidth: CGFloat { compact ? 5 : 7 }
    private var textSize: CGFloat { compact ? 7 : 8 }
    private var leadingInset: CGFloat { compact ? 3 : 4 }
    private var patchWidth: CGFloat { compact ? 82 : 128 }
    private var patchHeight: CGFloat { compact ? 10 : 11 }
    private var label: String { compact ? "VIBE" : "VIBE-BEEPER" }

    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle().fill(bezelColor)
                .frame(width: patchWidth, height: patchHeight)

            HStack(spacing: compact ? 0 : 2) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: iconSize, weight: .black))
                    .frame(width: iconWidth)

                Text(label)
                    .font(.system(size: textSize, weight: .black, design: .monospaced))
                    .tracking(compact ? 0.3 : 0.6)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .allowsTightening(true)
            }
            .foregroundStyle(brandColor)
            .padding(.leading, compact ? 3 : 4)
        }
        .fixedSize()
    }
}
