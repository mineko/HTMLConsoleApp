// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ConsoleKit",
    platforms: [.macOS(.v14)],
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
            ]
        ),
        .target(
            name: "TestModule",
            dependencies: ["ConsoleKit"],
            resources: [
                .copy("Resources/test.bundle")
            ]
        ),
        .target(
            name: "LayoutTestModule",
            dependencies: ["ConsoleKit"]
        ),
    ]
)
