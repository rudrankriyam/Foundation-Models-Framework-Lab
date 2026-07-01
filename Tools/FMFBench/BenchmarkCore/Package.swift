// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FMFBenchCore",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "FMFBenchCore",
            targets: ["FMFBenchCore"]
        ),
        .library(
            name: "BenchmarkCore",
            targets: ["FMFBenchCore"]
        ),
        .executable(
            name: "FMFBenchCLI",
            targets: ["FMFBenchCLI"]
        ),
        .executable(
            name: "fmfbench-bridge-run",
            targets: ["FMFBenchBridgeRunner"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/rryam/FoundationModelsKit.git", branch: "main")
    ],
    targets: [
        .target(
            name: "FMFBenchCore",
            dependencies: [
                .product(name: "FoundationModelsKit", package: "FoundationModelsKit")
            ]
        ),
        .executableTarget(
            name: "FMFBenchCLI",
            dependencies: ["FMFBenchCore"]
        ),
        .executableTarget(
            name: "FMFBenchBridgeRunner",
            dependencies: ["FMFBenchCore"]
        ),
        .testTarget(
            name: "FMFBenchCoreTests",
            dependencies: ["FMFBenchCore"]
        )
    ]
)
