import AFMServer
import Darwin
import Foundation

struct ResolvedBridgePaths: Sendable, Equatable {
    let baseDirectory: String?
    let bridgeDirectory: String
    let descriptorPath: String
    let descriptorFileName: String

    func descriptorStore() throws -> AFMBridgeDescriptorStore {
        try AFMBridgeDescriptorStore(directoryPath: bridgeDirectory, fileName: descriptorFileName)
    }

    func prepare() throws {
        if let baseDirectory {
            try preparePrivateDirectoryWithoutRepair(at: baseDirectory)
        }
        try preparePrivateDirectoryWithoutRepair(at: bridgeDirectory)
    }

    func readDescriptor() throws -> AFMBridgeConnectionDescriptor {
        do {
            return try descriptorStore().read()
        } catch AFMBridgeDescriptorError.descriptorMissing,
                AFMBridgeDescriptorError.directoryMissing {
            throw AFMBridgeCommandError.hostMissing(descriptorPath: descriptorPath)
        } catch {
            throw AFMBridgeCommandError.invalidDescriptor(
                descriptorPath: descriptorPath,
                reason: error.localizedDescription
            )
        }
    }
}

private func preparePrivateDirectoryWithoutRepair(at path: String) throws {
    do {
        try AFMBridgeDirectory.validate(at: path)
        return
    } catch AFMBridgeDescriptorError.directoryMissing {
        // Only a directory created by this invocation may receive new permissions.
    }

    if Darwin.mkdir(path, 0o700) != 0, errno != EEXIST {
        throw AFMBridgeDescriptorError.posix(operation: "create the bridge directory", code: errno)
    }
    try AFMBridgeDirectory.validate(at: path)
}
