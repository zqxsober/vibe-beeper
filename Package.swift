// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "vibe-beeper",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/FluidInference/FluidAudio.git", exact: "0.12.4"),
        .package(url: "https://github.com/soffes/HotKey.git", from: "0.2.1"),
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.17.0"),
    ],
    targets: [
        .target(
            name: "UpdateCore",
            path: "Sources/UpdateCore",
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
        .executableTarget(
            name: "vibe-beeper",
            dependencies: [
                .target(name: "UpdateCore"),
                .product(name: "FluidAudio", package: "FluidAudio"),
                .product(name: "HotKey", package: "HotKey"),
                .product(name: "WhisperKit", package: "WhisperKit"),
            ],
            path: "Sources",
            exclude: [
                "UpdateCore",
                "shells",
                "buttons",
                "shell.svg",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ],
            linkerSettings: []
        ),
        .testTarget(
            name: "CC-BeeperTests",
            dependencies: [
                .target(name: "UpdateCore"),
                .product(name: "FluidAudio", package: "FluidAudio"),
            ],
            path: "Tests/CC-BeeperTests"
        )
    ]
)
