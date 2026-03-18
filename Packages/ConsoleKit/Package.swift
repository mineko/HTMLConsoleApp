// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ConsoleKit",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "ConsoleKit", targets: ["ConsoleKit"]),
        .library(name: "TestModule", targets: ["TestModule"]),
        .library(name: "LayoutTestModule", targets: ["LayoutTestModule"]),
    ],
    targets: [
        .target(
            name: "ConsoleKit",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .defaultIsolation(MainActor.self),
            ]
        ),
        .target(
            name: "TestModule",
            dependencies: ["ConsoleKit"],
            resources: [
                .copy("Resources/test.bundle")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .defaultIsolation(MainActor.self),
            ]
        ),
        .target(
            name: "LayoutTestModule",
            dependencies: ["ConsoleKit"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .defaultIsolation(MainActor.self),
            ]
        ),
    ]
)
