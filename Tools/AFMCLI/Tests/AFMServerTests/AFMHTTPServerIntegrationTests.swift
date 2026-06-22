import Darwin
import Foundation
import Testing
@testable import AFMServer

@Test("TCP transport serves health and enforces parser and body limits")
func tcpTransportAndLimits() async throws {
    let limits = AFMServerLimits(
        maximumBodyBytes: 4,
        maximumHeaderBytes: 128,
        maximumHeaderFieldBytes: 128,
        maximumHeaderCount: 12
    )
    let server = try testServer(configuration: .init(endpoint: .tcp(host: "127.0.0.1", port: 0), limits: limits))

    do {
        let address = try await server.start()
        guard case .tcp(_, let port) = address else {
            Issue.record("Expected a TCP address")
            try await server.stop()
            return
        }

        let health = try sendRawHTTPRequest(
            "GET /health HTTP/1.1\r\nHost: 127.0.0.1:\(port)\r\nConnection: close\r\n\r\n",
            port: port
        )
        #expect(health.hasPrefix("HTTP/1.1 200 OK"))
        #expect(health.contains("\"status\":\"afm serve is running\""))

        let oversizedHeader = try sendRawHTTPRequest(
            "GET /health HTTP/1.1\r\nHost: 127.0.0.1:\(port)\r\nX-Large: \(String(repeating: "a", count: 200))\r\n\r\n",
            port: port
        )
        #expect(oversizedHeader.hasPrefix("HTTP/1.1 431 Request Header Fields Too Large"))
        #expect(oversizedHeader.contains("\"code\":\"headers_too_large\""))

        let oversizedBody = try sendRawHTTPRequest(
            "GET /health HTTP/1.1\r\nHost: 127.0.0.1:\(port)\r\nContent-Type: application/json\r\nContent-Length: 5\r\n\r\n12345",
            port: port
        )
        #expect(oversizedBody.hasPrefix("HTTP/1.1 413 Payload Too Large"))
        #expect(oversizedBody.contains("\"code\":\"request_too_large\""))

        try await server.stop()
    } catch {
        try? await server.stop()
        throw error
    }
}

@Test("Unix socket is private and removed during graceful shutdown")
func unixSocketPermissionsAndCleanup() async throws {
    let directory = try makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let path = directory.appending(path: "afm.sock").path()
    let server = try testServer(configuration: .init(endpoint: .unixSocket(path: path)))

    do {
        _ = try await server.start()
        var status = stat()
        #expect(Darwin.lstat(path, &status) == 0)
        #expect((status.st_mode & S_IFMT) == S_IFSOCK)
        #expect((status.st_mode & 0o777) == 0o600)

        try await server.stop()
        #expect(Darwin.lstat(path, &status) == -1)
        #expect(errno == ENOENT)
    } catch {
        try? await server.stop()
        throw error
    }
}

@Test("Failed Unix channel adoption closes the descriptor and removes its socket")
func failedUnixChannelAdoptionCleanup() throws {
    let directory = try makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let path = directory.appending(path: "afm.sock").path()
    let boundSocket = try AFMUnixSocketManager.makeBoundSocket(path: path)
    let socketIdentity = try fileIdentity(of: boundSocket.descriptor)
    defer {
        if descriptor(boundSocket.descriptor, stillRefersTo: socketIdentity) {
            Darwin.close(boundSocket.descriptor)
        }
        Darwin.unlink(path)
    }

    try AFMUnixSocketManager.cleanupAfterFailedAdoption(boundSocket)

    #expect(!descriptor(boundSocket.descriptor, stillRefersTo: socketIdentity))
    var status = stat()
    #expect(Darwin.lstat(path, &status) == -1)
    #expect(errno == ENOENT)
}

@Test("A server can retry after its first TCP bind fails")
func failedTCPBindCanRetrySameServer() async throws {
    let blocker = try testServer(configuration: .init(endpoint: .tcp(host: "127.0.0.1", port: 0)))
    var retryingServer: AFMHTTPServer?

    do {
        let blockerAddress = try await blocker.start()
        guard case .tcp(_, let port) = blockerAddress else {
            Issue.record("Expected a TCP address")
            try await blocker.stop()
            return
        }
        let server = try testServer(configuration: .init(endpoint: .tcp(host: "127.0.0.1", port: port)))
        retryingServer = server

        do {
            _ = try await server.start()
            Issue.record("Expected the occupied port bind to fail")
        } catch {
            #expect(!(error is AFMHTTPServerStateError))
        }

        try await blocker.stop()
        let retryAddress = try await server.start()
        #expect(retryAddress == .tcp(host: "127.0.0.1", port: port))
        try await server.stop()
    } catch {
        try? await blocker.stop()
        if let retryingServer {
            try? await retryingServer.stop()
        }
        throw error
    }
}

@Test("Failed shutdown retains its socket lease until a retry succeeds")
func failedShutdownCanRetryAndRestart() async throws {
    let directory = try makeTemporaryDirectory()
    defer {
        Darwin.chmod(directory.path(), 0o700)
        try? FileManager.default.removeItem(at: directory)
    }
    let path = directory.appending(path: "afm.sock").path()
    let server = try testServer(configuration: .init(endpoint: .unixSocket(path: path)))

    do {
        _ = try await server.start()
        #expect(Darwin.chmod(directory.path(), 0o500) == 0)

        do {
            try await server.stop()
            Issue.record("Expected socket cleanup to fail in a read-only directory")
        } catch {
            #expect(error is AFMUnixSocketError)
        }

        var status = stat()
        #expect(Darwin.lstat(path, &status) == 0)
        #expect((status.st_mode & S_IFMT) == S_IFSOCK)

        #expect(Darwin.chmod(directory.path(), 0o700) == 0)
        try await server.stop()
        #expect(Darwin.lstat(path, &status) == -1)
        #expect(errno == ENOENT)

        _ = try await server.start()
        try await server.stop()
    } catch {
        Darwin.chmod(directory.path(), 0o700)
        try? await server.stop()
        throw error
    }
}

@Test("Graceful shutdown closes accepted keep-alive connections")
func gracefulShutdownClosesChildChannels() async throws {
    let server = try testServer(configuration: .init(endpoint: .tcp(host: "127.0.0.1", port: 0)))

    do {
        let address = try await server.start()
        guard case .tcp(_, let port) = address else {
            Issue.record("Expected a TCP address")
            try await server.stop()
            return
        }
        let descriptor = try connectTCPSocket(port: port)
        defer { Darwin.close(descriptor) }
        usleep(20_000)

        try await server.stop()

        var byte: UInt8 = 0
        #expect(Darwin.read(descriptor, &byte, 1) == 0)
    } catch {
        try? await server.stop()
        throw error
    }
}

@Test("Unix socket cleanup never removes a replacement path")
func unixSocketInodeSafeCleanup() async throws {
    let directory = try makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let socketURL = directory.appending(path: "afm.sock")
    let movedSocketURL = directory.appending(path: "original.sock")
    let server = try testServer(configuration: .init(endpoint: .unixSocket(path: socketURL.path())))

    do {
        _ = try await server.start()
        try FileManager.default.moveItem(at: socketURL, to: movedSocketURL)
        try createStaleUnixSocket(path: socketURL.path())
        var replacementStatus = stat()
        #expect(Darwin.lstat(socketURL.path(), &replacementStatus) == 0)

        try await server.stop()

        var statusAfterShutdown = stat()
        #expect(Darwin.lstat(socketURL.path(), &statusAfterShutdown) == 0)
        #expect(statusAfterShutdown.st_dev == replacementStatus.st_dev)
        #expect(statusAfterShutdown.st_ino == replacementStatus.st_ino)
        var movedStatus = stat()
        #expect(Darwin.lstat(movedSocketURL.path(), &movedStatus) == 0)
        #expect((movedStatus.st_mode & S_IFMT) == S_IFSOCK)
    } catch {
        try? await server.stop()
        throw error
    }
}

@Test("Unix socket refuses regular files, symlinks, and active listeners")
func unixSocketRefusesUnsafePaths() async throws {
    let directory = try makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let regularFile = directory.appending(path: "regular.sock")
    try Data("keep".utf8).write(to: regularFile)
    let regularServer = try testServer(configuration: .init(endpoint: .unixSocket(path: regularFile.path())))
    await expectStartFailure(regularServer, matching: .pathExists(kind: "regular file"))
    #expect(try Data(contentsOf: regularFile) == Data("keep".utf8))

    let symlink = directory.appending(path: "link.sock")
    try FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: regularFile)
    let symlinkServer = try testServer(configuration: .init(endpoint: .unixSocket(path: symlink.path())))
    await expectStartFailure(symlinkServer, matching: .pathExists(kind: "symbolic link"))

    let activePath = directory.appending(path: "active.sock").path()
    let firstServer = try testServer(configuration: .init(endpoint: .unixSocket(path: activePath)))
    let secondServer = try testServer(configuration: .init(endpoint: .unixSocket(path: activePath)))
    do {
        _ = try await firstServer.start()
        await expectStartFailure(secondServer, matching: .socketInUse)
        try await firstServer.stop()
    } catch {
        try? await firstServer.stop()
        try? await secondServer.stop()
        throw error
    }
}

@Test("Owned stale Unix sockets are replaced safely")
func staleUnixSocketRecovery() async throws {
    let directory = try makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let path = directory.appending(path: "stale.sock").path()
    try createStaleUnixSocket(path: path)

    let server = try testServer(configuration: .init(endpoint: .unixSocket(path: path)))
    do {
        _ = try await server.start()
        var status = stat()
        #expect(Darwin.lstat(path, &status) == 0)
        #expect((status.st_mode & 0o777) == 0o600)
        try await server.stop()
    } catch {
        try? await server.stop()
        throw error
    }
}

@Test("Unix sockets reject non-sticky shared parent directories")
func unixSocketRejectsInsecureParent() async throws {
    let directory = try makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    #expect(Darwin.chmod(directory.path(), 0o777) == 0)

    let path = directory.appending(path: "afm.sock").path()
    let server = try testServer(configuration: .init(endpoint: .unixSocket(path: path)))
    await expectStartFailure(server, matching: .insecureParentDirectory)
}

private func testServer(configuration: AFMServerConfiguration) throws -> AFMHTTPServer {
    try AFMHTTPServer(
        configuration: configuration,
        catalog: AFMStaticModelCatalog(models: [.init(id: "system", isAvailable: true)]),
        clock: IntegrationTestClock()
    )
}

private struct IntegrationTestClock: AFMServerClock {
    func unixTime() -> Int64 { 123 }
}

private struct FileIdentity: Equatable {
    let device: dev_t
    let inode: ino_t
}

private func fileIdentity(of descriptor: CInt) throws -> FileIdentity {
    var status = stat()
    guard Darwin.fstat(descriptor, &status) == 0 else {
        throw POSIXTestError(operation: "inspect Unix socket", code: errno)
    }
    return FileIdentity(device: status.st_dev, inode: status.st_ino)
}

private func descriptor(_ descriptor: CInt, stillRefersTo identity: FileIdentity) -> Bool {
    var status = stat()
    guard Darwin.fstat(descriptor, &status) == 0 else { return false }
    return status.st_dev == identity.device && status.st_ino == identity.inode
}

private func makeTemporaryDirectory() throws -> URL {
    let identifier = UUID().uuidString.prefix(8)
    let directory = URL(fileURLWithPath: "/tmp/afm-tests-\(identifier)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
    return directory
}

private func expectStartFailure(
    _ server: AFMHTTPServer,
    matching expectedError: AFMUnixSocketError
) async {
    do {
        _ = try await server.start()
        Issue.record("Expected server startup to fail with \(expectedError)")
        try? await server.stop()
    } catch let error as AFMUnixSocketError {
        #expect(error == expectedError)
    } catch {
        Issue.record("Unexpected startup error: \(error)")
    }
}

private func sendRawHTTPRequest(_ request: String, port: Int) throws -> String {
    let descriptor = try connectTCPSocket(port: port)
    defer { Darwin.close(descriptor) }

    let requestBytes = Array(request.utf8)
    try requestBytes.withUnsafeBytes { buffer in
        var sent = 0
        while sent < buffer.count {
            let result = Darwin.write(
                descriptor,
                buffer.baseAddress?.advanced(by: sent),
                buffer.count - sent
            )
            guard result > 0 else { throw POSIXTestError(operation: "write TCP request", code: errno) }
            sent += result
        }
    }

    var response = Data()
    var buffer = [UInt8](repeating: 0, count: 4_096)
    while true {
        let count = Darwin.read(descriptor, &buffer, buffer.count)
        if count > 0 {
            response.append(contentsOf: buffer.prefix(count))
        } else if count == 0 {
            break
        } else if errno == EAGAIN || errno == EWOULDBLOCK {
            break
        } else {
            throw POSIXTestError(operation: "read TCP response", code: errno)
        }
    }
    return try #require(String(data: response, encoding: .utf8))
}

private func connectTCPSocket(port: Int) throws -> CInt {
    let descriptor = Darwin.socket(AF_INET, SOCK_STREAM, 0)
    guard descriptor >= 0 else { throw POSIXTestError(operation: "create TCP socket", code: errno) }
    var shouldClose = true
    defer {
        if shouldClose {
            Darwin.close(descriptor)
        }
    }

    var timeout = timeval(tv_sec: 2, tv_usec: 0)
    guard setsockopt(
        descriptor,
        SOL_SOCKET,
        SO_RCVTIMEO,
        &timeout,
        socklen_t(MemoryLayout<timeval>.size)
    ) == 0 else {
        throw POSIXTestError(operation: "set TCP timeout", code: errno)
    }

    var address = sockaddr_in()
    address.sin_family = sa_family_t(AF_INET)
    address.sin_port = in_port_t(port).bigEndian
    let addressResult = "127.0.0.1".withCString {
        inet_pton(AF_INET, $0, &address.sin_addr)
    }
    guard addressResult == 1 else { throw POSIXTestError(operation: "encode TCP address", code: errno) }
    let connectResult = withUnsafePointer(to: &address) { pointer in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            Darwin.connect(descriptor, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
        }
    }
    guard connectResult == 0 else { throw POSIXTestError(operation: "connect TCP socket", code: errno) }
    shouldClose = false
    return descriptor
}

private func createStaleUnixSocket(path: String) throws {
    let descriptor = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
    guard descriptor >= 0 else { throw POSIXTestError(operation: "create Unix socket", code: errno) }
    defer { Darwin.close(descriptor) }

    var address = sockaddr_un()
    address.sun_family = sa_family_t(AF_UNIX)
    let bytes = path.utf8CString
    withUnsafeMutableBytes(of: &address.sun_path) { destination in
        bytes.withUnsafeBytes { source in
            destination.copyBytes(from: source)
        }
    }
    let length = socklen_t(MemoryLayout<sa_family_t>.size + bytes.count)
    address.sun_len = UInt8(length)
    let result = withUnsafePointer(to: &address) { pointer in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            Darwin.bind(descriptor, $0, length)
        }
    }
    guard result == 0 else { throw POSIXTestError(operation: "bind stale Unix socket", code: errno) }
}

private struct POSIXTestError: Error, CustomStringConvertible {
    let operation: String
    let code: Int32

    var description: String {
        "Could not \(operation): \(String(cString: strerror(code)))"
    }
}
