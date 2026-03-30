import SwiftUI

struct ScreenView: View {
    var body: some View {
        ScreenContentView()
    }
}

// MARK: - LCD Status Icon

struct LCDIcon: View {
    let symbol: String
    let active: Bool
    var color: Color = Color(hex: "3A3A2E")

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 7, weight: .bold))
            .foregroundColor(color.opacity(active ? 0.85 : 0.08))
    }
}

// MARK: - Pixel Character

struct PixelCharacterView: View {
    let state: ClaudeState
    let frame: Int
    var onColor: Color = Color(hex: "3A3A2E")
    var isYolo: Bool = false
    var isGlitching: Bool = false

    private let pixelSize: CGFloat = 2.5

    private var currentSprite: [String] {
        if isGlitching {
            return Sprites.glitchFrame(frame: frame)
        }
        let sprites = isYolo ? [Sprites.yolo1, Sprites.yolo2] : spritesForState(state)
        return sprites[frame % sprites.count]
    }

    var body: some View {
        Canvas { context, size in
            let sprite = currentSprite
            guard let firstRow = sprite.first else { return }
            let cols = firstRow.count, rows = sprite.count
            let totalW = CGFloat(cols) * pixelSize
            let totalH = CGFloat(rows) * pixelSize
            let ox = (size.width - totalW) / 2
            let oy = (size.height - totalH) / 2

            for (row, line) in sprite.enumerated() {
                for (col, char) in line.enumerated() {
                    if char == "#" {
                        let rect = CGRect(
                            x: ox + CGFloat(col) * pixelSize,
                            y: oy + CGFloat(row) * pixelSize,
                            width: pixelSize, height: pixelSize
                        )
                        context.fill(Path(rect), with: .color(onColor))
                    }
                }
            }
        }
    }

    private func spritesForState(_ state: ClaudeState) -> [[String]] {
        switch state {
        case .idle: [Sprites.idle1, Sprites.idle2, Sprites.idle3, Sprites.idle4]
        case .working: [Sprites.working1, Sprites.working2, Sprites.working3, Sprites.working4]
        case .done: [Sprites.done1, Sprites.done2, Sprites.done3, Sprites.done4]
        case .error: [Sprites.error1, Sprites.error2, Sprites.error3, Sprites.error4]
        case .approveQuestion: [Sprites.approve1, Sprites.approve2, Sprites.approve3, Sprites.approve4]
        case .needsInput: [Sprites.input1, Sprites.input2, Sprites.input3, Sprites.input4]
        }
    }
}

// MARK: - Sprites (14 wide x 12 tall)

enum Sprites {

    // MARK: IDLE — eyes closed, ZZZ bubbles floating up, slow breathing, occasional snore twitch

    // Frame 1: eyes closed (dashes), ZZZ at top-right, body normal
    static let idle1: [String] = [
        "..........##..",
        ".........#..#.",
        ".....##.......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#..--..--..#.",
        ".#..........#.",
        ".#....##....#.",
        ".#..........#.",
        "..##########..",
        "....######....",
    ]

    // Frame 2: eyes closed, ZZZ shifted one row up, body slightly wider (breathing in)
    static let idle2: [String] = [
        ".........##...",
        "........#..#..",
        ".....##.......",
        "....######....",
        ".###########..",
        ".#..........#.",
        ".#..--..--..#.",
        ".#..........#.",
        ".#....##....#.",
        ".#..........##",
        ".###########..",
        "....######....",
    ]

    // Frame 3: eyes closed, ZZZ faded (at very top), body back to normal (breathing out)
    static let idle3: [String] = [
        "......##......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#..--..--..#.",
        ".#..........#.",
        ".#....##....#.",
        ".#..........#.",
        "..##########..",
        "....######....",
        "..............",
        "..............",
    ]

    // Frame 4: eyes closed, no ZZZ (pause), slight head tilt left (snore twitch)
    static let idle4: [String] = [
        "......##......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#.--....--...",
        ".#..........#.",
        ".#....##....#.",
        ".#..........#.",
        "..##########..",
        "....######....",
        "..#...........",
        "..##..........",
    ]

    // MARK: WORKING — focused eyes, head bobs, eyes dart left-right scanning

    // Frame 1: eyes looking left, arms typing left
    static let working1: [String] = [
        "......##......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#.##.....##.#",
        ".#..........#.",
        ".#...####...#.",
        ".#..........#.",
        "############..",
        "....######....",
        "..#...........",
        ".##...........",
    ]

    // Frame 2: eyes looking right, arms typing right
    static let working2: [String] = [
        "......##......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#..##.....##.",
        ".#..........#.",
        ".#...####...#.",
        ".#..........#.",
        "..############",
        "....######....",
        "...........#..",
        "...........##.",
    ]

    // Frame 3: eyes center, head bobbed down 1px (focus dip)
    static let working3: [String] = [
        "......##......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#..##..##..#.",
        ".#..........#.",
        ".#...####...#.",
        ".#..........#.",
        "..##########..",
        "....########..",
        "...#......#...",
        "..##......##..",
    ]

    // Frame 4: eyes center, head up (normal), raised arm gesture
    static let working4: [String] = [
        "......##......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#..##..##..#.",
        ".#..........#.",
        ".#...####...#.",
        ".#..........#.",
        "..##########..",
        "....######....",
        "...#......####",
        "..##..........",
    ]

    // MARK: DONE — big grin, arms-up celebration, victory wiggle then settles

    // Frame 1: big grin (wide mouth), arms straight up
    static let done1: [String] = [
        "...#......#...",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#..##..##..#.",
        ".#..........#.",
        ".#.########.#.",
        ".#..........#.",
        "..##########..",
        "....######....",
        "...#......#...",
        "..##......##..",
    ]

    // Frame 2: grin, arms angled outward (V shape), sparkle dots at top
    static let done2: [String] = [
        ".#..........#.",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#..##..##..#.",
        ".#..........#.",
        ".#.########.#.",
        ".#..........#.",
        "..##########..",
        "....######....",
        "..#........#..",
        ".##........##.",
    ]

    // Frame 3: grin, arms down, body wiggle left
    static let done3: [String] = [
        ".....##.......",
        "...######.....",
        ".##########...",
        "#..........#..",
        "#..##..##..#..",
        "#..........#..",
        "#.########.#..",
        "#..........#..",
        ".##########...",
        "...######.....",
        "..#......#....",
        ".##......##...",
    ]

    // Frame 4: settled — gentle smile, arms relaxed at sides, normal pose
    static let done4: [String] = [
        "......##......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#..##..##..#.",
        ".#..........#.",
        ".#..######..#.",
        ".#..........#.",
        "..##########..",
        "....######....",
        "...#......#...",
        "..##......##..",
    ]

    // MARK: ERROR — X-eyes, sparks/lightning bolts around head

    // Frame 1: X-eyes, spark top-left
    static let error1: [String] = [
        ".#............",
        "..#...........",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#.##..##...#.",
        ".#..##..##..#.",
        ".#..........#.",
        ".#....##....#.",
        "..##########..",
        "....######....",
        "..##......##..",
    ]

    // Frame 2: X-eyes, spark top-right
    static let error2: [String] = [
        "............#.",
        "...........#..",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#...##..##.#.",
        ".#..##..##..#.",
        ".#..........#.",
        ".#....##....#.",
        "..##########..",
        "....######....",
        "..##......##..",
    ]

    // Frame 3: X-eyes, sparks both sides
    static let error3: [String] = [
        ".#.........#..",
        "..#.......#...",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#.##..##...#.",
        ".#..##..##..#.",
        ".#..........#.",
        ".#....##....#.",
        "..##########..",
        "....######....",
        ".##.......##..",
    ]

    // Frame 4: X-eyes, no sparks (flash settled), just X-eyes steady
    static let error4: [String] = [
        "......##......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#.##..##...#.",
        ".#..##..##..#.",
        ".#..........#.",
        ".#....##....#.",
        ".#..........#.",
        "..##########..",
        "....######....",
        "..##......##..",
    ]

    // MARK: APPROVE? — wide eyes, hand-up stop gesture, whole body vibrates/shakes

    // Frame 1: wide eyes (big dots), hand up left side, body shifted left
    static let approve1: [String] = [
        ".....##.......",
        "...######.....",
        ".##########...",
        "#..........#..",
        "#.###..###.#..",
        "#..........#..",
        "#....##....#..",
        "#..........#..",
        ".##########...",
        "...######.....",
        "#.#......#....",
        "##.......##...",
    ]

    // Frame 2: wide eyes, hand up right side, body shifted right
    static let approve2: [String] = [
        ".......##.....",
        ".....######...",
        "...##########.",
        "..#..........#",
        "..#.###..###.#",
        "..#..........#",
        "..#....##....#",
        "..#..........#",
        "...##########.",
        ".....######...",
        "....#......#.#",
        "...##......###",
    ]

    // Frame 3: wide eyes, both hands up (stop gesture), body center
    static let approve3: [String] = [
        "......##......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#.###..###.#.",
        ".#..........#.",
        ".#....##....#.",
        ".#..........#.",
        "..##########..",
        "....######....",
        "##.#......#.##",
        "...##....##...",
    ]

    // Frame 4: wide eyes, hands down, body shifted left again (vibrate cycle)
    static let approve4: [String] = [
        ".....##.......",
        "...######.....",
        ".##########...",
        "#..........#..",
        "#.###..###.#..",
        "#..........#..",
        "#....##....#..",
        "#..........#..",
        ".##########...",
        "...######.....",
        "..#......#....",
        ".##......##...",
    ]

    // MARK: NEEDS INPUT — head tilted, floating "?" above, question mark bobs, curious blink

    // Frame 1: tilted head (leaning right), "?" at top center, eyes open curious
    static let input1: [String] = [
        ".....#........",
        ".....##.......",
        "......#.......",
        "...#######....",
        ".#########....",
        "#..........#..",
        "#..##..##..#..",
        "#..........#..",
        "#....##....#..",
        ".#########....",
        "..#######.....",
        "..##....##....",
    ]

    // Frame 2: tilted head, "?" shifted right, eyes blink (closed dashes)
    static let input2: [String] = [
        "......#.......",
        "......##......",
        ".......#......",
        "...#######....",
        ".#########....",
        "#..........#..",
        "#..--..--..#..",
        "#..........#..",
        "#....##....#..",
        ".#########....",
        "..#######.....",
        "..##....##....",
    ]

    // Frame 3: tilted head, "?" back center but lower, eyes open
    static let input3: [String] = [
        "......##......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#..##..##..#.",
        ".#..........#.",
        ".#....##....#.",
        ".#..........#.",
        "..##########..",
        "....######....",
        "...#......#...",
        "..##......##..",
    ]

    // Frame 4: head straight (un-tilted), "?" at top, eyes wide/curious
    static let input4: [String] = [
        "......#.......",
        "......##......",
        "......#.......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#..##..##..#.",
        ".#..........#.",
        ".#....##....#.",
        "..##########..",
        "....######....",
        "..##......##..",
    ]

    // MARK: YOLO mode — sunglasses character (unchanged from original)

    static let yolo1: [String] = [
        "......##......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#.####.###.#.",
        ".#..........#.",
        ".#.########.#.",
        ".#..........#.",
        "..##########..",
        "....######....",
        "...#......#...",
        "..##......##..",
    ]
    static let yolo2: [String] = [
        "......##......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#.###.####.#.",
        ".#..........#.",
        ".#.########.#.",
        ".#..........#.",
        "..##########..",
        "....######....",
        "..............",
        "..##..##..##..",
    ]

    // MARK: Glitch helper (D-17 — randomized pixels for ~0.5s ERROR entrance)

    /// Pseudo-random grid using frame as seed — deterministic for visual consistency
    static func glitchFrame(frame: Int) -> [String] {
        let chars: [Character] = ["#", ".", ".", "#", ".", ".", "#", "."]
        var rows: [String] = []
        for row in 0..<12 {
            var line: [Character] = []
            for col in 0..<14 {
                let idx = (row * 14 + col + frame * 7) % chars.count
                line.append(chars[idx])
            }
            rows.append(String(line))
        }
        return rows
    }
}
