import Darwin
import Foundation

enum AFMBridgePOSIX {
    static let directoryMode = mode_t(0o700)
    static let descriptorMode = mode_t(0o600)

    static func validateAbsolutePath(_ path: String) throws {
        guard path.hasPrefix("/"), !path.contains("\0") else {
            throw AFMBridgeDescriptorError.invalidPath
        }
    }

    static func validateFileName(_ name: String) throws {
        guard !name.isEmpty,
              name != ".",
              name != "..",
              !name.contains("/"),
              !name.contains("\0") else {
            throw AFMBridgeDescriptorError.invalidFileName
        }
    }

    static func openDirectory(at path: String, repairPermissions: Bool) throws -> CInt {
        try validateAbsolutePath(path)
        let descriptor = Darwin.open(path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard descriptor >= 0 else {
            if errno == ENOENT {
                throw AFMBridgeDescriptorError.directoryMissing
            }
            if errno == ELOOP || errno == ENOTDIR {
                throw AFMBridgeDescriptorError.unexpectedObject(expected: "directory", actual: objectKind(at: path))
            }
            throw posixError(operation: "open the bridge directory")
        }

        do {
            var status = stat()
            guard Darwin.fstat(descriptor, &status) == 0 else {
                throw posixError(operation: "inspect the bridge directory")
            }
            guard objectType(status) == S_IFDIR else {
                throw AFMBridgeDescriptorError.unexpectedObject(expected: "directory", actual: objectKind(status))
            }
            guard status.st_uid == geteuid() else {
                throw AFMBridgeDescriptorError.ownerMismatch
            }

            if repairPermissions, permissions(status) != directoryMode {
                guard Darwin.fchmod(descriptor, directoryMode) == 0 else {
                    throw posixError(operation: "set bridge directory permissions")
                }
                guard Darwin.fstat(descriptor, &status) == 0 else {
                    throw posixError(operation: "verify bridge directory permissions")
                }
            }
            try requirePermissions(status, expected: directoryMode)
            try requirePath(path, matches: status, expectedType: S_IFDIR)
            return descriptor
        } catch {
            Darwin.close(descriptor)
            throw error
        }
    }

    static func status(at descriptor: CInt, name: String) throws -> stat? {
        var status = stat()
        if Darwin.fstatat(descriptor, name, &status, AT_SYMLINK_NOFOLLOW) == 0 {
            return status
        }
        if errno == ENOENT { return nil }
        throw posixError(operation: "inspect the bridge descriptor path")
    }

    static func requireSafeDescriptor(_ status: stat) throws {
        guard objectType(status) == S_IFREG else {
            throw AFMBridgeDescriptorError.unexpectedObject(expected: "regular file", actual: objectKind(status))
        }
        guard status.st_uid == geteuid() else {
            throw AFMBridgeDescriptorError.ownerMismatch
        }
        try requirePermissions(status, expected: descriptorMode)
        guard status.st_nlink == 1 else {
            throw AFMBridgeDescriptorError.tooManyLinks
        }
    }

    static func writeAll(_ data: Data, to descriptor: CInt) throws {
        try data.withUnsafeBytes { buffer in
            guard var baseAddress = buffer.baseAddress else { return }
            var remaining = buffer.count
            while remaining > 0 {
                let count = Darwin.write(descriptor, baseAddress, remaining)
                if count < 0, errno == EINTR { continue }
                guard count > 0 else {
                    throw posixError(operation: "write the bridge descriptor")
                }
                remaining -= count
                baseAddress = baseAddress.advanced(by: count)
            }
        }
    }

    static func readAll(from descriptor: CInt, byteCount: Int) throws -> Data {
        var data = Data(count: byteCount)
        let bytesRead = try data.withUnsafeMutableBytes { buffer -> Int in
            guard var baseAddress = buffer.baseAddress else { return 0 }
            var total = 0
            while total < buffer.count {
                let count = Darwin.read(descriptor, baseAddress, buffer.count - total)
                if count < 0, errno == EINTR { continue }
                guard count >= 0 else {
                    throw posixError(operation: "read the bridge descriptor")
                }
                if count == 0 { break }
                total += count
                baseAddress = baseAddress.advanced(by: count)
            }
            return total
        }
        guard bytesRead == byteCount else {
            throw AFMBridgeDescriptorError.pathChanged
        }
        return data
    }

    static func sameFile(_ lhs: stat, _ rhs: stat) -> Bool {
        lhs.st_dev == rhs.st_dev && lhs.st_ino == rhs.st_ino
    }

    static func objectKind(_ status: stat) -> String {
        switch objectType(status) {
        case S_IFDIR: "directory"
        case S_IFLNK: "symbolic link"
        case S_IFREG: "regular file"
        case S_IFSOCK: "socket"
        case S_IFIFO: "FIFO"
        case S_IFCHR: "character device"
        case S_IFBLK: "block device"
        default: "unknown object"
        }
    }

    static func posixError(operation: String) -> AFMBridgeDescriptorError {
        .posix(operation: operation, code: errno)
    }

    private static func requirePermissions(_ status: stat, expected: mode_t) throws {
        let actual = permissions(status)
        guard actual == expected else {
            throw AFMBridgeDescriptorError.permissionsMismatch(
                expected: UInt16(expected),
                actual: UInt16(actual)
            )
        }
    }

    private static func requirePath(_ path: String, matches openedStatus: stat, expectedType: mode_t) throws {
        var pathStatus = stat()
        guard Darwin.lstat(path, &pathStatus) == 0 else {
            throw AFMBridgeDescriptorError.pathChanged
        }
        guard sameFile(openedStatus, pathStatus),
              objectType(pathStatus) == expectedType,
              pathStatus.st_uid == geteuid() else {
            throw AFMBridgeDescriptorError.pathChanged
        }
    }

    private static func permissions(_ status: stat) -> mode_t {
        status.st_mode & mode_t(0o7777)
    }

    private static func objectType(_ status: stat) -> mode_t {
        status.st_mode & S_IFMT
    }

    private static func objectKind(at path: String) -> String {
        var status = stat()
        guard Darwin.lstat(path, &status) == 0 else { return "missing object" }
        return objectKind(status)
    }
}
