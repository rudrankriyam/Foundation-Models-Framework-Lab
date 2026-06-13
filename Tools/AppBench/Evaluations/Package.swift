// swift-tools-version: 6.2

import Foundation
import PackageDescription

let fileManager = FileManager.default
let environment = ProcessInfo.processInfo.environment
let explicitDeveloperDirectory = environment["DEVELOPER_DIR"].map {
  URL(fileURLWithPath: $0).standardizedFileURL
}

func discoveredDeveloperDirectories(in directory: URL) -> [URL] {
  let applications =
    (try? FileManager.default.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: nil
    )) ?? []
  return
    applications
    .filter {
      $0.pathExtension == "app"
        && $0.lastPathComponent.localizedCaseInsensitiveContains("xcode")
    }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }
    .map { $0.appending(path: "Contents/Developer") }
}

let developerDirectoryCandidates: [URL]
if let explicitDeveloperDirectory {
  developerDirectoryCandidates = [explicitDeveloperDirectory]
} else {
  let homeDirectory = fileManager.homeDirectoryForCurrentUser
  developerDirectoryCandidates =
    [
      URL(fileURLWithPath: "/Applications/Xcode-beta.app/Contents/Developer"),
      URL(fileURLWithPath: "/Applications/Xcode.app/Contents/Developer")
    ]
    + discoveredDeveloperDirectories(in: URL(fileURLWithPath: "/Applications"))
    + discoveredDeveloperDirectories(in: homeDirectory.appending(path: "Applications"))
    + discoveredDeveloperDirectories(in: homeDirectory.appending(path: "Downloads"))
}

let developerDirectory = developerDirectoryCandidates.first { candidate in
  fileManager.fileExists(
    atPath:
      candidate
      .appending(path: "Platforms/MacOSX.platform/Developer/Library/Frameworks")
      .appending(path: "Evaluations.framework/Evaluations")
      .path
  )
}

guard let developerDirectory else {
  fatalError(
    """
    Xcode 27 with Evaluations.framework was not found. Run ../appbench-evaluate,
    or set DEVELOPER_DIR to Xcode 27's Contents/Developer directory.
    """
  )
}

let xcodeContents = developerDirectory.deletingLastPathComponent().path
let developerFrameworks =
  developerDirectory
  .appending(path: "Platforms/MacOSX.platform/Developer/Library/Frameworks")
  .path

let evaluationSwiftSettings: [SwiftSetting] = [
  .unsafeFlags(["-F", developerFrameworks])
]

let evaluationLinkerSettings: [LinkerSetting] = [
  .unsafeFlags([
    "-F", developerFrameworks,
    "-Xlinker", "-rpath",
    "-Xlinker", xcodeContents
  ]),
  .linkedFramework("Evaluations")
]

let package = Package(
  name: "AppBenchEvaluations",
  platforms: [
    .macOS("27.0")
  ],
  products: [
    .library(
      name: "AppBenchEvaluations",
      targets: ["AppBenchEvaluations"]
    ),
    .executable(
      name: "appbench-evaluate",
      targets: ["AppBenchEvaluateCLI"]
    )
  ],
  dependencies: [
    .package(path: "../BenchmarkCore")
  ],
  targets: [
    .target(
      name: "AppBenchEvaluations",
      dependencies: [
        .product(name: "AppBenchCore", package: "BenchmarkCore")
      ],
      swiftSettings: evaluationSwiftSettings,
      linkerSettings: evaluationLinkerSettings
    ),
    .executableTarget(
      name: "AppBenchEvaluateCLI",
      dependencies: ["AppBenchEvaluations"],
      swiftSettings: evaluationSwiftSettings
    ),
    .testTarget(
      name: "AppBenchEvaluationsTests",
      dependencies: [
        "AppBenchEvaluations",
        .product(name: "AppBenchCore", package: "BenchmarkCore")
      ],
      swiftSettings: evaluationSwiftSettings
    )
  ]
)
