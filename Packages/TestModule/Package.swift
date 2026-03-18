// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TestModule",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "TestModule", targets: ["TestModule"]),
    ],
    dependencies: [
        .package(path: "../ConsoleKit"),
    ],
    targets: [
        .target(
            name: "TestModule",
            dependencies: [
                .product(name: "ConsoleKit", package: "ConsoleKit"),
            ],
            resources: [
                .copy("Resources/test.bundle")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .defaultIsolation(MainActor.self),
            ]
        ),
    ]
)
