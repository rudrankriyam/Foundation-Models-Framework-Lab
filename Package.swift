// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FoundationModelsFrameworkLab",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "FoundationLabCore",
            targets: ["FoundationLabCore"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/rryam/FoundationModelsKit.git",
            revision: "65834b11d6da41e4a2f51003eba930b211d6f031"
        )
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
        .testTarget(
            name: "FoundationLabCoreTests",
            dependencies: [
                "FoundationLabCore",
                .product(name: "FoundationModelsKit", package: "FoundationModelsKit"),
                .product(name: "FoundationModelsTools", package: "FoundationModelsKit")
            ],
            path: "FoundationLabCore/Tests/FoundationLabCoreTests"
        )
    ]
)
