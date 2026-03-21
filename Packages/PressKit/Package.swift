// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PressKit",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "PressKit", targets: ["PressKit"]),
    ],
    targets: [
        .target(
            name: "PressKit",
            resources: [
                .copy("Resources/themes"),
                .process("Resources/console.html"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .defaultIsolation(MainActor.self),
            ]
        ),
    ]
)
