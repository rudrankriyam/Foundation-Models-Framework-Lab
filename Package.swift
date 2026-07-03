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
            revision: "1cad71a114cd8b321804b4f73a550ac500aafe1b"
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
                .product(name: "FoundationModelsKit", package: "FoundationModelsKit")
            ],
            path: "FoundationLabCore/Tests/FoundationLabCoreTests"
        )
    ]
)
