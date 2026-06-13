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
            name: "appbench",
            targets: ["AppBenchCLI"]
        ),
        .library(
            name: "FoundationModelsKit",
            targets: ["FoundationModelsKit"]
        ),
        .library(
            name: "FoundationModelsTools",
            targets: ["FoundationModelsTools"]
        ),
        .library(
            name: "FoundationLabCore",
            targets: ["FoundationLabCore"]
        ),
        .library(
            name: "AppBenchCore",
            targets: ["AppBenchCore"]
        ),
        .library(
            name: "BenchmarkCore",
            targets: ["AppBenchCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.0.1")
    ],
    targets: [
        .target(
            name: "FoundationModelsKit",
            path: "Packages/FoundationModelsKit/Sources/FoundationModelsKit"
        ),
        .target(
            name: "FoundationModelsTools",
            dependencies: ["FoundationModelsKit"],
            path: "Packages/FoundationModelsKit/Sources/FoundationModelsTools"
        ),
        .target(
            name: "FoundationLabCore",
            dependencies: [
                "FoundationModelsKit",
                "FoundationModelsTools"
            ],
            path: "FoundationLabCore/Sources/FoundationLabCore"
        ),
        .executableTarget(
            name: "AFMCLI",
            dependencies: [
                "FoundationLabCore",
                "FoundationModelsKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Yams", package: "Yams")
            ],
            path: "Tools/AFMCLI/Sources/AFMCLI"
        ),
        .target(
            name: "AppBenchCore",
            path: "Tools/AppBench/BenchmarkCore/Sources/AppBenchCore"
        ),
        .executableTarget(
            name: "AppBenchCLI",
            dependencies: ["AppBenchCore"],
            path: "Tools/AppBench/BenchmarkCore/Sources/AppBenchCLI"
        ),
        .testTarget(
            name: "FoundationModelsKitTests",
            dependencies: ["FoundationModelsKit"],
            path: "Packages/FoundationModelsKit/Tests/FoundationModelsKitTests"
        ),
        .testTarget(
            name: "FoundationModelsToolsTests",
            dependencies: ["FoundationModelsTools"],
            path: "Packages/FoundationModelsKit/Tests/FoundationModelsToolsTests"
        ),
        .testTarget(
            name: "FoundationLabCoreTests",
            dependencies: ["FoundationLabCore"],
            path: "FoundationLabCore/Tests/FoundationLabCoreTests"
        ),
        .testTarget(
            name: "AFMCLITests",
            dependencies: ["AFMCLI"],
            path: "Tools/AFMCLI/Tests/AFMCLITests"
        ),
        .testTarget(
            name: "AppBenchCoreTests",
            dependencies: ["AppBenchCore"],
            path: "Tools/AppBench/BenchmarkCore/Tests/AppBenchCoreTests"
        )
    ]
)
