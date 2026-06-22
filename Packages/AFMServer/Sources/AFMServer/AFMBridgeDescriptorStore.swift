import Darwin
import Foundation

public struct AFMBridgeDescriptorStore: Sendable {
    public static let defaultFileName = "connection.json"
    public static let maximumDescriptorByteCount = 65_536

    public let directoryPath: String
    public let fileName: String

    public var descriptorPath: String {
        (directoryPath as NSString).appendingPathComponent(fileName)
    }

    public init(directoryPath: String, fileName: String = Self.defaultFileName) throws {
        try AFMBridgePOSIX.validateAbsolutePath(directoryPath)
        try AFMBridgePOSIX.validateFileName(fileName)
        self.directoryPath = directoryPath
        self.fileName = fileName
    }

    @discardableResult
    public func publish(_ descriptor: AFMBridgeConnectionDescriptor) throws -> AFMBridgeDescriptorLease {
        let data = try encodedData(for: descriptor)
        try AFMBridgeDirectory.prepare(at: directoryPath)
        let directoryDescriptor = try AFMBridgePOSIX.openDirectory(at: directoryPath, repairPermissions: false)
        defer { Darwin.close(directoryDescriptor) }
        return try publish(data, in: directoryDescriptor)
    }

    public func read() throws -> AFMBridgeConnectionDescriptor {
        let directoryDescriptor = try AFMBridgePOSIX.openDirectory(at: directoryPath, repairPermissions: false)
        defer { Darwin.close(directoryDescriptor) }
        let descriptor = Darwin.openat(
            directoryDescriptor,
            fileName,
            O_RDONLY | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC
        )
        guard descriptor >= 0 else {
            if errno == ENOENT {
                throw AFMBridgeDescriptorError.descriptorMissing
            }
            if errno == ELOOP {
                throw AFMBridgeDescriptorError.unexpectedObject(expected: "regular file", actual: "symbolic link")
            }
            throw AFMBridgePOSIX.posixError(operation: "open the bridge descriptor")
        }
        defer { Darwin.close(descriptor) }

        var status = stat()
        guard Darwin.fstat(descriptor, &status) == 0 else {
            throw AFMBridgePOSIX.posixError(operation: "inspect the bridge descriptor")
        }
        try AFMBridgePOSIX.requireSafeDescriptor(status)
        guard status.st_size > 0, status.st_size <= Self.maximumDescriptorByteCount else {
            throw AFMBridgeDescriptorError.descriptorTooLarge
        }
        let data = try AFMBridgePOSIX.readAll(from: descriptor, byteCount: Int(status.st_size))
        let decoded: AFMBridgeConnectionDescriptor
        do {
            decoded = try JSONDecoder().decode(AFMBridgeConnectionDescriptor.self, from: data)
        } catch {
            throw AFMBridgeDescriptorError.decodingFailed
        }
        return try decoded.validated()
    }
}

private extension AFMBridgeDescriptorStore {
    func encodedData(for descriptor: AFMBridgeConnectionDescriptor) throws -> Data {
        let data: Data
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            data = try encoder.encode(descriptor.validated())
        } catch let error as AFMBridgeDescriptorError {
            throw error
        } catch {
            throw AFMBridgeDescriptorError.encodingFailed
        }
        guard !data.isEmpty, data.count <= Self.maximumDescriptorByteCount else {
            throw AFMBridgeDescriptorError.descriptorTooLarge
        }
        return data
    }

    func publish(_ data: Data, in directoryDescriptor: CInt) throws -> AFMBridgeDescriptorLease {
        let temporary = try makeTemporaryDescriptor(data, in: directoryDescriptor)
        var shouldRemoveTemporary = true
        defer {
            Darwin.close(temporary.fileDescriptor)
            if shouldRemoveTemporary {
                removeTemporaryIfUnchanged(
                    directoryDescriptor: directoryDescriptor,
                    name: temporary.name,
                    expectedStatus: temporary.status
                )
            }
        }

        try install(temporary, in: directoryDescriptor)
        shouldRemoveTemporary = false
        return try makeLease(for: temporary.status, in: directoryDescriptor)
    }

    func makeTemporaryDescriptor(_ data: Data, in directoryDescriptor: CInt) throws -> AFMBridgeTemporaryDescriptor {
        let name = ".\(fileName).\(UUID().uuidString).tmp"
        let fileDescriptor = Darwin.openat(
            directoryDescriptor,
            name,
            O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC,
            AFMBridgePOSIX.descriptorMode
        )
        guard fileDescriptor >= 0 else {
            throw AFMBridgePOSIX.posixError(operation: "create the temporary bridge descriptor")
        }

        var status = stat()
        do {
            guard Darwin.fstat(fileDescriptor, &status) == 0 else {
                throw AFMBridgePOSIX.posixError(operation: "inspect the temporary bridge descriptor")
            }
            guard Darwin.fchmod(fileDescriptor, AFMBridgePOSIX.descriptorMode) == 0 else {
                throw AFMBridgePOSIX.posixError(operation: "set bridge descriptor permissions")
            }
            try AFMBridgePOSIX.writeAll(data, to: fileDescriptor)
            guard Darwin.fsync(fileDescriptor) == 0 else {
                throw AFMBridgePOSIX.posixError(operation: "synchronize the temporary bridge descriptor")
            }
            guard Darwin.fstat(fileDescriptor, &status) == 0 else {
                throw AFMBridgePOSIX.posixError(operation: "verify the temporary bridge descriptor")
            }
            try AFMBridgePOSIX.requireSafeDescriptor(status)
            return AFMBridgeTemporaryDescriptor(name: name, fileDescriptor: fileDescriptor, status: status)
        } catch {
            Darwin.close(fileDescriptor)
            removeTemporaryIfUnchanged(
                directoryDescriptor: directoryDescriptor,
                name: name,
                expectedStatus: status
            )
            throw error
        }
    }

    func install(_ temporary: AFMBridgeTemporaryDescriptor, in directoryDescriptor: CInt) throws {
        if let existingStatus = try AFMBridgePOSIX.status(at: directoryDescriptor, name: fileName) {
            try AFMBridgePOSIX.requireSafeDescriptor(existingStatus)
            try replaceExisting(
                directoryDescriptor: directoryDescriptor,
                temporaryName: temporary.name,
                temporaryStatus: temporary.status
            )
        } else {
            try installWhenMissing(
                directoryDescriptor: directoryDescriptor,
                temporaryName: temporary.name
            )
        }
    }

    func makeLease(for temporaryStatus: stat, in directoryDescriptor: CInt) throws -> AFMBridgeDescriptorLease {
        guard Darwin.fsync(directoryDescriptor) == 0 else {
            throw AFMBridgePOSIX.posixError(operation: "synchronize the bridge descriptor directory")
        }
        guard let installedStatus = try AFMBridgePOSIX.status(at: directoryDescriptor, name: fileName),
              AFMBridgePOSIX.sameFile(installedStatus, temporaryStatus) else {
            throw AFMBridgeDescriptorError.pathChanged
        }
        try AFMBridgePOSIX.requireSafeDescriptor(installedStatus)

        var directoryStatus = stat()
        guard Darwin.fstat(directoryDescriptor, &directoryStatus) == 0 else {
            throw AFMBridgePOSIX.posixError(operation: "inspect the bridge descriptor directory")
        }
        return AFMBridgeDescriptorLease(
            descriptorPath: descriptorPath,
            directoryPath: directoryPath,
            fileName: fileName,
            directoryStatus: directoryStatus,
            descriptorStatus: installedStatus
        )
    }

    func installWhenMissing(directoryDescriptor: CInt, temporaryName: String) throws {
        guard Darwin.renameatx_np(
            directoryDescriptor,
            temporaryName,
            directoryDescriptor,
            fileName,
            UInt32(RENAME_EXCL)
        ) == 0 else {
            if errno == EEXIST {
                if let appearedStatus = try AFMBridgePOSIX.status(at: directoryDescriptor, name: fileName) {
                    try AFMBridgePOSIX.requireSafeDescriptor(appearedStatus)
                }
                throw AFMBridgeDescriptorError.pathChanged
            }
            throw AFMBridgePOSIX.posixError(operation: "install the bridge descriptor")
        }
    }

    func replaceExisting(
        directoryDescriptor: CInt,
        temporaryName: String,
        temporaryStatus: stat
    ) throws {
        guard Darwin.renameatx_np(
            directoryDescriptor,
            temporaryName,
            directoryDescriptor,
            fileName,
            UInt32(RENAME_SWAP)
        ) == 0 else {
            if errno == ENOENT {
                throw AFMBridgeDescriptorError.pathChanged
            }
            throw AFMBridgePOSIX.posixError(operation: "rotate the bridge descriptor")
        }

        do {
            guard let installedStatus = try AFMBridgePOSIX.status(at: directoryDescriptor, name: fileName),
                  AFMBridgePOSIX.sameFile(installedStatus, temporaryStatus) else {
                throw AFMBridgeDescriptorError.pathChanged
            }
            guard let displacedStatus = try AFMBridgePOSIX.status(at: directoryDescriptor, name: temporaryName) else {
                throw AFMBridgeDescriptorError.pathChanged
            }
            try AFMBridgePOSIX.requireSafeDescriptor(displacedStatus)
            guard Darwin.unlinkat(directoryDescriptor, temporaryName, 0) == 0 else {
                throw AFMBridgePOSIX.posixError(operation: "remove the previous bridge descriptor")
            }
        } catch {
            rollbackSwapIfPossible(
                directoryDescriptor: directoryDescriptor,
                temporaryName: temporaryName,
                temporaryStatus: temporaryStatus
            )
            throw error
        }
    }

    func rollbackSwapIfPossible(
        directoryDescriptor: CInt,
        temporaryName: String,
        temporaryStatus: stat
    ) {
        guard let installedStatus = try? AFMBridgePOSIX.status(at: directoryDescriptor, name: fileName),
              AFMBridgePOSIX.sameFile(installedStatus, temporaryStatus),
              (try? AFMBridgePOSIX.status(at: directoryDescriptor, name: temporaryName)) != nil else {
            return
        }
        _ = Darwin.renameatx_np(
            directoryDescriptor,
            temporaryName,
            directoryDescriptor,
            fileName,
            UInt32(RENAME_SWAP)
        )
    }

    func removeTemporaryIfUnchanged(
        directoryDescriptor: CInt,
        name: String,
        expectedStatus: stat
    ) {
        guard expectedStatus.st_ino != 0,
              let status = try? AFMBridgePOSIX.status(at: directoryDescriptor, name: name),
              AFMBridgePOSIX.sameFile(status, expectedStatus),
              status.st_uid == geteuid() else {
            return
        }
        _ = Darwin.unlinkat(directoryDescriptor, name, 0)
    }
}
