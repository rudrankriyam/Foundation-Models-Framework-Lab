// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FoundationLabCore",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "FoundationLabCore",
            targets: ["FoundationLabCore"]
        )
    ],
    dependencies: [
        .package(path: "../Packages/FoundationModelsKit")
    ],
    targets: [
        .target(
            name: "FoundationLabCore",
            dependencies: [
                .product(name: "FoundationModelsKit", package: "FoundationModelsKit"),
                .product(name: "FoundationModelsTools", package: "FoundationModelsKit")
            ]
        ),
        .testTarget(
            name: "FoundationLabCoreTests",
            dependencies: [
                "FoundationLabCore",
                .product(name: "FoundationModelsKit", package: "FoundationModelsKit")
            ]
        )
    ]
)
