// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FoundationModelsFrameworkLab",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .executable(
            name: "fmfbench",
            targets: ["FMFBenchCLI"]
        ),
        .library(
            name: "FoundationLabCore",
            targets: ["FoundationLabCore"]
        ),
        .library(
            name: "FMFBenchCore",
            targets: ["FMFBenchCore"]
        ),
        .library(
            name: "BenchmarkCore",
            targets: ["FMFBenchCore"]
        )
    ],
    dependencies: [
        .package(path: "Packages/FoundationModelsKit")
    ],
    targets: [
        .target(
            name: "FoundationLabCore",
            dependencies: [
                .product(name: "FoundationModelsKit", package: "FoundationModelsKit"),
                .product(name: "FoundationModelsTools", package: "FoundationModelsKit")
            ],
            path: "FoundationLabCore/Sources/FoundationLabCore"
        ),
        .target(
            name: "FMFBenchCore",
            dependencies: [
                .product(name: "FoundationModelsKit", package: "FoundationModelsKit")
            ],
            path: "Tools/FMFBench/BenchmarkCore/Sources/FMFBenchCore"
        ),
        .executableTarget(
            name: "FMFBenchCLI",
            dependencies: ["FMFBenchCore"],
            path: "Tools/FMFBench/BenchmarkCore/Sources/FMFBenchCLI"
        ),
        .testTarget(
            name: "FoundationModelsKitTests",
            dependencies: [
                .product(name: "FoundationModelsKit", package: "FoundationModelsKit")
            ],
            path: "Packages/FoundationModelsKit/Tests/FoundationModelsKitTests"
        ),
        .testTarget(
            name: "FoundationModelsToolsTests",
            dependencies: [
                .product(name: "FoundationModelsTools", package: "FoundationModelsKit")
            ],
            path: "Packages/FoundationModelsKit/Tests/FoundationModelsToolsTests"
        ),
        .testTarget(
            name: "FoundationLabCoreTests",
            dependencies: [
                "FoundationLabCore",
                .product(name: "FoundationModelsKit", package: "FoundationModelsKit")
            ],
            path: "FoundationLabCore/Tests/FoundationLabCoreTests"
        ),
        .testTarget(
            name: "FMFBenchCoreTests",
            dependencies: ["FMFBenchCore"],
            path: "Tools/FMFBench/BenchmarkCore/Tests/FMFBenchCoreTests"
        )
    ]
)
