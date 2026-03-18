// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "LayoutTestModule",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "LayoutTestModule", targets: ["LayoutTestModule"]),
    ],
    dependencies: [
        .package(path: "../ConsoleKit"),
    ],
    targets: [
        .target(
            name: "LayoutTestModule",
            dependencies: [
                .product(name: "ConsoleKit", package: "ConsoleKit"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .defaultIsolation(MainActor.self),
            ]
        ),
    ]
)
