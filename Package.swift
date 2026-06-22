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
            name: "FMFBenchCore",
            targets: ["FMFBenchCore"]
        ),
        .library(
            name: "BenchmarkCore",
            targets: ["FMFBenchCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.101.0"),
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
                "AFMServer",
                "FoundationLabCore",
                "FoundationModelsKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Yams", package: "Yams")
            ],
            path: "Tools/AFMCLI/Sources/AFMCLI"
        ),
        .target(
            name: "AFMServer",
            dependencies: [
                "FoundationModelsKit",
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio")
            ],
            path: "Tools/AFMCLI/Sources/AFMServer"
        ),
        .target(
            name: "FMFBenchCore",
            path: "Tools/FMFBench/BenchmarkCore/Sources/FMFBenchCore"
        ),
        .executableTarget(
            name: "FMFBenchCLI",
            dependencies: ["FMFBenchCore"],
            path: "Tools/FMFBench/BenchmarkCore/Sources/FMFBenchCLI"
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
            name: "AFMServerTests",
            dependencies: [
                "AFMServer",
                "FoundationModelsKit",
                .product(name: "NIOEmbedded", package: "swift-nio")
            ],
            path: "Tools/AFMCLI/Tests/AFMServerTests"
        ),
        .testTarget(
            name: "FMFBenchCoreTests",
            dependencies: ["FMFBenchCore"],
            path: "Tools/FMFBench/BenchmarkCore/Tests/FMFBenchCoreTests"
        )
    ]
)
