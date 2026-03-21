// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TestModule",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "TestModule", targets: ["TestModule"]),
    ],
    dependencies: [
        .package(path: "../PressKit"),
    ],
    targets: [
        .target(
            name: "TestModule",
            dependencies: [
                .product(name: "PressKit", package: "PressKit"),
            ],
            resources: [
                .copy("Resources/images"),
                .copy("Resources/themes"),
                .copy("Resources/info.json"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .defaultIsolation(MainActor.self),
            ]
        ),
    ]
)
