import Foundation

public struct AppVersion: Comparable {
    private let components: [Int]

    public init(_ rawValue: String) {
        let normalizedValue = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .dropLeadingVersionPrefix()
            .split(separator: "-", maxSplits: 1)
            .first
            .map(String.init) ?? ""

        components = normalizedValue
            .split(separator: ".")
            .map { AppVersion.parseNumericPrefix(from: String($0)) }
    }

    public static func isRemoteVersion(_ remoteVersion: String, newerThan currentVersion: String) -> Bool {
        AppVersion(remoteVersion) > AppVersion(currentVersion)
    }

    public static func < (leftVersion: AppVersion, rightVersion: AppVersion) -> Bool {
        let componentCount = max(leftVersion.components.count, rightVersion.components.count)

        for index in 0..<componentCount {
            let leftComponent = leftVersion.components[safe: index] ?? 0
            let rightComponent = rightVersion.components[safe: index] ?? 0

            if leftComponent != rightComponent {
                return leftComponent < rightComponent
            }
        }

        return false
    }

    private static func parseNumericPrefix(from component: String) -> Int {
        let digits = component.prefix { $0.isNumber }
        return Int(digits) ?? 0
    }
}

private extension String {
    func dropLeadingVersionPrefix() -> String {
        guard let firstCharacter = first, firstCharacter == "v" || firstCharacter == "V" else {
            return self
        }
        return String(dropFirst())
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

