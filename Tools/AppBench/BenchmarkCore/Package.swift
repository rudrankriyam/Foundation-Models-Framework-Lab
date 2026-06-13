// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppBenchCore",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "AppBenchCore",
            targets: ["AppBenchCore"]
        ),
        .library(
            name: "BenchmarkCore",
            targets: ["AppBenchCore"]
        ),
        .executable(
            name: "AppBenchCLI",
            targets: ["AppBenchCLI"]
        )
    ],
    targets: [
        .target(
            name: "AppBenchCore"
        ),
        .executableTarget(
            name: "AppBenchCLI",
            dependencies: ["AppBenchCore"]
        ),
        .testTarget(
            name: "AppBenchCoreTests",
            dependencies: ["AppBenchCore"]
        )
    ]
)
