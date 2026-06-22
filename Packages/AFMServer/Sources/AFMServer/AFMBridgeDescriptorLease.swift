import Darwin
import Foundation

public struct AFMBridgeDescriptorLease: Sendable {
    public let descriptorPath: String

    private let directoryPath: String
    private let fileName: String
    private let directoryDevice: dev_t
    private let directoryInode: ino_t
    private let descriptorDevice: dev_t
    private let descriptorInode: ino_t

    init(
        descriptorPath: String,
        directoryPath: String,
        fileName: String,
        directoryStatus: stat,
        descriptorStatus: stat
    ) {
        self.descriptorPath = descriptorPath
        self.directoryPath = directoryPath
        self.fileName = fileName
        directoryDevice = directoryStatus.st_dev
        directoryInode = directoryStatus.st_ino
        descriptorDevice = descriptorStatus.st_dev
        descriptorInode = descriptorStatus.st_ino
    }

    public func cleanup() throws {
        let directoryDescriptor: CInt
        do {
            directoryDescriptor = try AFMBridgePOSIX.openDirectory(at: directoryPath, repairPermissions: false)
        } catch AFMBridgeDescriptorError.directoryMissing {
            return
        } catch AFMBridgeDescriptorError.pathChanged {
            return
        } catch AFMBridgeDescriptorError.unexpectedObject {
            return
        }
        defer { Darwin.close(directoryDescriptor) }

        var directoryStatus = stat()
        guard Darwin.fstat(directoryDescriptor, &directoryStatus) == 0 else {
            throw AFMBridgePOSIX.posixError(operation: "inspect the bridge directory during cleanup")
        }
        guard directoryStatus.st_dev == directoryDevice,
              directoryStatus.st_ino == directoryInode else {
            return
        }
        guard let descriptorStatus = try AFMBridgePOSIX.status(at: directoryDescriptor, name: fileName),
              descriptorStatus.st_dev == descriptorDevice,
              descriptorStatus.st_ino == descriptorInode else {
            return
        }
        try AFMBridgePOSIX.requireSafeDescriptor(descriptorStatus)
        guard Darwin.unlinkat(directoryDescriptor, fileName, 0) == 0 else {
            if errno == ENOENT { return }
            throw AFMBridgePOSIX.posixError(operation: "remove the bridge descriptor")
        }
        guard Darwin.fsync(directoryDescriptor) == 0 else {
            throw AFMBridgePOSIX.posixError(operation: "synchronize bridge descriptor cleanup")
        }
    }
}
