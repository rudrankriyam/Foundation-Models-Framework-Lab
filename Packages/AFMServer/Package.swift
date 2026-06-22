// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AFMServer",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "AFMServer",
            targets: ["AFMServer"]
        )
    ],
    dependencies: [
        .package(path: "../FoundationModelsKit"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.101.0")
    ],
    targets: [
        .target(
            name: "AFMServer",
            dependencies: [
                .product(name: "FoundationModelsKit", package: "FoundationModelsKit"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio")
            ]
        ),
        .testTarget(
            name: "AFMServerTests",
            dependencies: [
                "AFMServer",
                .product(name: "FoundationModelsKit", package: "FoundationModelsKit"),
                .product(name: "NIOEmbedded", package: "swift-nio")
            ]
        )
    ]
)
