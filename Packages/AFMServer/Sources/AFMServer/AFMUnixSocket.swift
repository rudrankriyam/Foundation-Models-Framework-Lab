import Darwin
import Foundation

enum AFMUnixSocketPath {
    static let maximumUTF8ByteCount: Int = {
        var address = sockaddr_un()
        return withUnsafeBytes(of: &address.sun_path) { bytes in
            bytes.count - 1
        }
    }()

    static func fits(_ path: String) -> Bool {
        path.utf8.count <= maximumUTF8ByteCount
    }
}

enum AFMUnixSocketManager {
    static func prepare(path: String) throws {
        guard AFMUnixSocketPath.fits(path) else {
            throw AFMUnixSocketError.pathTooLong
        }
        try validateParentDirectory(of: path)
        guard let status = try fileStatus(at: path) else { return }
        guard isSocket(status) else {
            throw AFMUnixSocketError.pathExists(kind: fileKind(status))
        }
        guard status.st_uid == geteuid() else {
            throw AFMUnixSocketError.socketOwnedByAnotherUser
        }

        switch try socketActivity(at: path) {
        case .active:
            throw AFMUnixSocketError.socketInUse
        case .missing:
            return
        case .stale:
            guard let currentStatus = try fileStatus(at: path),
                  sameFile(status, currentStatus),
                  isSocket(currentStatus),
                  currentStatus.st_uid == geteuid() else {
                throw AFMUnixSocketError.pathChanged
            }
            guard Darwin.unlink(path) == 0 else {
                throw posixError(operation: "remove stale socket")
            }
        }
    }

    static func secureBoundSocket(path: String) throws -> AFMUnixSocketLease {
        guard let status = try fileStatus(at: path), isSocket(status) else {
            throw AFMUnixSocketError.boundPathIsNotSocket
        }
        guard status.st_uid == geteuid() else {
            throw AFMUnixSocketError.socketOwnedByAnotherUser
        }

        let lease = AFMUnixSocketLease(path: path, device: status.st_dev, inode: status.st_ino)
        guard Darwin.chmod(path, S_IRUSR | S_IWUSR) == 0 else {
            try? lease.cleanup()
            throw posixError(operation: "set socket permissions")
        }
        guard let securedStatus = try fileStatus(at: path),
              sameFile(status, securedStatus),
              isSocket(securedStatus) else {
            throw AFMUnixSocketError.pathChanged
        }
        return lease
    }

    static func makeBoundSocket(path: String, backlog: Int32 = 256) throws -> AFMBoundUnixSocket {
        let descriptor = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else { throw posixError(operation: "create Unix socket") }
        var transfersOwnership = false
        defer {
            if !transfersOwnership {
                Darwin.close(descriptor)
            }
        }

        guard Darwin.fcntl(descriptor, F_SETFD, FD_CLOEXEC) == 0 else {
            throw posixError(operation: "configure Unix socket")
        }

        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        let bytes = path.utf8CString
        withUnsafeMutableBytes(of: &address.sun_path) { destination in
            bytes.withUnsafeBytes { source in
                destination.copyBytes(from: source)
            }
        }
        let addressLength = socklen_t(MemoryLayout<sa_family_t>.size + bytes.count)
        address.sun_len = UInt8(addressLength)
        let bindResult = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(descriptor, $0, addressLength)
            }
        }
        guard bindResult == 0 else { throw posixError(operation: "bind Unix socket") }

        let lease = try secureBoundSocket(path: path)
        do {
            guard Darwin.listen(descriptor, backlog) == 0 else {
                throw posixError(operation: "listen on Unix socket")
            }
        } catch {
            try? lease.cleanup()
            throw error
        }

        transfersOwnership = true
        return AFMBoundUnixSocket(descriptor: descriptor, lease: lease)
    }

    static func cleanupAfterFailedAdoption(_ socket: AFMBoundUnixSocket) throws {
        let closeResult = Darwin.close(socket.descriptor)
        let closeError = errno

        try socket.lease.cleanup()

        guard closeResult == 0 || closeError == EBADF else {
            throw AFMUnixSocketError.posix(
                operation: "close unadopted Unix socket",
                code: closeError
            )
        }
    }

    private static func validateParentDirectory(of path: String) throws {
        let parentPath = (path as NSString).deletingLastPathComponent
        var status = stat()
        let result = parentPath.withCString { pointer in
            stat(pointer, &status)
        }
        guard result == 0, (status.st_mode & S_IFMT) == S_IFDIR else {
            throw AFMUnixSocketError.invalidParentDirectory
        }

        let isSticky = (status.st_mode & S_ISVTX) != 0
        let isWritableByOthers = (status.st_mode & (S_IWGRP | S_IWOTH)) != 0
        guard !isWritableByOthers || isSticky else {
            throw AFMUnixSocketError.insecureParentDirectory
        }
        guard Darwin.access(parentPath, W_OK | X_OK) == 0 else {
            throw AFMUnixSocketError.parentDirectoryNotWritable
        }
    }

    private static func fileStatus(at path: String) throws -> stat? {
        var status = stat()
        if Darwin.lstat(path, &status) == 0 {
            return status
        }
        if errno == ENOENT {
            return nil
        }
        throw posixError(operation: "inspect socket path")
    }

    private static func socketActivity(at path: String) throws -> AFMSocketActivity {
        let descriptor = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else { throw posixError(operation: "create socket probe") }
        defer { Darwin.close(descriptor) }

        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        let bytes = path.utf8CString
        withUnsafeMutableBytes(of: &address.sun_path) { destination in
            bytes.withUnsafeBytes { source in
                destination.copyBytes(from: source)
            }
        }
        let addressLength = socklen_t(MemoryLayout<sa_family_t>.size + bytes.count)
        address.sun_len = UInt8(addressLength)
        let result = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(descriptor, $0, addressLength)
            }
        }
        if result == 0 {
            return .active
        }

        switch errno {
        case ENOENT:
            return .missing
        case ECONNREFUSED:
            return .stale
        default:
            throw posixError(operation: "probe existing socket")
        }
    }

    private static func isSocket(_ status: stat) -> Bool {
        (status.st_mode & S_IFMT) == S_IFSOCK
    }

    private static func sameFile(_ lhs: stat, _ rhs: stat) -> Bool {
        lhs.st_dev == rhs.st_dev && lhs.st_ino == rhs.st_ino
    }

    private static func fileKind(_ status: stat) -> String {
        switch status.st_mode & S_IFMT {
        case S_IFLNK: "symbolic link"
        case S_IFDIR: "directory"
        case S_IFREG: "regular file"
        default: "non-socket file"
        }
    }

    private static func posixError(operation: String) -> AFMUnixSocketError {
        .posix(operation: operation, code: errno)
    }
}

struct AFMUnixSocketLease: Sendable {
    let path: String
    let device: dev_t
    let inode: ino_t

    func cleanup() throws {
        var status = stat()
        if Darwin.lstat(path, &status) != 0 {
            if errno == ENOENT { return }
            throw AFMUnixSocketError.posix(operation: "inspect socket during cleanup", code: errno)
        }
        guard status.st_dev == device,
              status.st_ino == inode,
              (status.st_mode & S_IFMT) == S_IFSOCK,
              status.st_uid == geteuid() else {
            return
        }
        guard Darwin.unlink(path) == 0 else {
            throw AFMUnixSocketError.posix(operation: "remove socket", code: errno)
        }
    }
}

struct AFMBoundUnixSocket: Sendable {
    let descriptor: CInt
    let lease: AFMUnixSocketLease
}

private enum AFMSocketActivity {
    case active
    case stale
    case missing
}

enum AFMUnixSocketError: Error, Equatable, LocalizedError {
    case invalidParentDirectory
    case insecureParentDirectory
    case parentDirectoryNotWritable
    case pathTooLong
    case pathExists(kind: String)
    case socketOwnedByAnotherUser
    case socketInUse
    case pathChanged
    case boundPathIsNotSocket
    case posix(operation: String, code: Int32)

    var errorDescription: String? {
        switch self {
        case .invalidParentDirectory:
            "The Unix-domain socket parent must be an existing directory."
        case .insecureParentDirectory:
            "The Unix-domain socket parent is writable by other users and does not use the sticky bit."
        case .parentDirectoryNotWritable:
            "The Unix-domain socket parent is not writable."
        case .pathTooLong:
            "The Unix-domain socket path is too long."
        case .pathExists(let kind):
            "Refusing to replace the \(kind) at the Unix-domain socket path."
        case .socketOwnedByAnotherUser:
            "Refusing to replace a Unix-domain socket owned by another user."
        case .socketInUse:
            "Another server is already listening on the Unix-domain socket."
        case .pathChanged:
            "The Unix-domain socket path changed during a safety check."
        case .boundPathIsNotSocket:
            "The bound Unix-domain socket path is not a socket."
        case .posix(let operation, let code):
            "Could not \(operation): \(String(cString: strerror(code)))."
        }
    }
}
