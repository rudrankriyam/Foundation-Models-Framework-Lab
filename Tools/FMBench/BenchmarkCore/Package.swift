// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FMBenchCore",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "FMBenchCore",
            targets: ["FMBenchCore"]
        ),
        .library(
            name: "BenchmarkCore",
            targets: ["FMBenchCore"]
        ),
        .executable(
            name: "FMBenchCLI",
            targets: ["FMBenchCLI"]
        )
    ],
    targets: [
        .target(
            name: "FMBenchCore"
        ),
        .executableTarget(
            name: "FMBenchCLI",
            dependencies: ["FMBenchCore"]
        ),
        .testTarget(
            name: "FMBenchCoreTests",
            dependencies: ["FMBenchCore"]
        )
    ]
)
