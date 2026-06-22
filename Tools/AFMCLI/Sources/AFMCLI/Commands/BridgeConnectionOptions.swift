import AFMServer
import ArgumentParser
import Foundation

struct BridgeConnectionOptions: ParsableArguments {
    @Option(
        name: .customLong("base"),
        help: "Base directory shared with Foundation Lab. Defaults to ~/.afm."
    )
    var baseDirectory: String?

    @Option(
        name: .customLong("descriptor"),
        help: "Read a connection descriptor from this absolute path instead of <base>/bridge/connection.json."
    )
    var descriptorPath: String?

    func resolveForPrepare() throws -> ResolvedBridgePaths {
        guard descriptorPath == nil else {
            throw ValidationError(
                "--descriptor is read-only and cannot be used with bridge prepare. Use --base to create a private bridge directory."
            )
        }
        return try resolve()
    }

    func resolve() throws -> ResolvedBridgePaths {
        if baseDirectory != nil, descriptorPath != nil {
            throw ValidationError("Use either --base or --descriptor, not both.")
        }

        if let descriptorPath {
            let resolvedDescriptor = try resolveAbsoluteBridgePath(descriptorPath, optionName: "--descriptor")
            let descriptorURL = URL(fileURLWithPath: resolvedDescriptor)
            let fileName = descriptorURL.lastPathComponent
            guard !fileName.isEmpty, fileName != ".", fileName != ".." else {
                throw ValidationError("--descriptor must include a file name.")
            }
            return ResolvedBridgePaths(
                baseDirectory: nil,
                bridgeDirectory: descriptorURL.deletingLastPathComponent().path(),
                descriptorPath: resolvedDescriptor,
                descriptorFileName: fileName
            )
        }

        let resolvedBase = try resolveAbsoluteBridgePath(baseDirectory ?? "~/.afm", optionName: "--base")
        let bridgeDirectory = URL(fileURLWithPath: resolvedBase)
            .appending(path: "bridge")
            .standardizedFileURL
            .path()
        return ResolvedBridgePaths(
            baseDirectory: resolvedBase,
            bridgeDirectory: bridgeDirectory,
            descriptorPath: URL(fileURLWithPath: bridgeDirectory)
                .appending(path: AFMBridgeDescriptorStore.defaultFileName)
                .path(),
            descriptorFileName: AFMBridgeDescriptorStore.defaultFileName
        )
    }
}

private func resolveAbsoluteBridgePath(_ path: String, optionName: String) throws -> String {
    let trimmed = try validatedResolvedText(path, optionName: optionName)
    let expanded = expandedPathString(trimmed)
    guard NSString(string: expanded).isAbsolutePath else {
        throw ValidationError("\(optionName) must be an absolute path.")
    }
    return URL(fileURLWithPath: expanded).standardizedFileURL.path()
}
