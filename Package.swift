// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CC-Beeper",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "CC-Beeper",
            path: "Sources",
            exclude: [
                "shells",
                "buttons",
                "shell.svg",
            ],
            resources: [
                .copy("cc-beeper-hook.py"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ],
            linkerSettings: [
                .linkedFramework("FoundationModels")
            ]
        ),
        .testTarget(
            name: "CC-BeeperTests",
            dependencies: [],
            path: "Tests/CC-BeeperTests"
        )
    ]
)
