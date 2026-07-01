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
            name: "afm",
            targets: ["AFMCLI"]
        ),
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
        .package(path: "Packages/AFMServer"),
        .package(url: "https://github.com/rryam/FoundationModelsKit.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.0.1")
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
        .executableTarget(
            name: "AFMCLI",
            dependencies: [
                .product(name: "AFMServer", package: "AFMServer"),
                .product(name: "FoundationModelsKit", package: "FoundationModelsKit"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Yams", package: "Yams")
            ],
            path: "Tools/AFMCLI/Sources/AFMCLI"
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
            name: "FoundationLabCoreTests",
            dependencies: [
                "FoundationLabCore",
                .product(name: "FoundationModelsKit", package: "FoundationModelsKit")
            ],
            path: "FoundationLabCore/Tests/FoundationLabCoreTests"
        ),
        .testTarget(
            name: "AFMCLITests",
            dependencies: ["AFMCLI"],
            path: "Tools/AFMCLI/Tests/AFMCLITests",
            resources: [
                .copy("Fixtures")
            ]
        ),
        .testTarget(
            name: "FMFBenchCoreTests",
            dependencies: ["FMFBenchCore"],
            path: "Tools/FMFBench/BenchmarkCore/Tests/FMFBenchCoreTests"
        )
    ]
)
