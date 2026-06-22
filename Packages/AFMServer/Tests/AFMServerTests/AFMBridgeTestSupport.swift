import Darwin
import Foundation
@testable import AFMServer

func withAFMBridgeTemporaryDirectory<Result>(
    _ body: (String) throws -> Result
) throws -> Result {
    let path = (NSTemporaryDirectory() as NSString)
        .appendingPathComponent("AFMBridgeTests-\(UUID().uuidString)")
    guard Darwin.mkdir(path, mode_t(0o700)) == 0 else {
        throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
    }
    defer { try? FileManager.default.removeItem(atPath: path) }
    return try body(path)
}

func makeAFMBridgeTestDescriptor(
    endpoint: AFMBridgeEndpoint = .unixSocket(path: "/tmp/foundation-lab.sock"),
    token: String? = nil,
    processIdentifier: Int32 = 42,
    launchIdentifier: UUID = UUID(),
    modelIdentifiers: [String] = ["system"],
    startedAt: Date = Date(timeIntervalSinceReferenceDate: 123_456)
) throws -> AFMBridgeConnectionDescriptor {
    AFMBridgeConnectionDescriptor(
        endpoint: endpoint,
        bearerToken: try token ?? AFMBridgeBearerTokenGenerator.generate(),
        processIdentifier: processIdentifier,
        launchIdentifier: launchIdentifier,
        modelIdentifiers: modelIdentifiers,
        startedAt: startedAt
    )
}

func afmBridgeStatus(at path: String) throws -> stat {
    var status = stat()
    guard Darwin.lstat(path, &status) == 0 else {
        throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
    }
    return status
}

func afmBridgePermissions(_ status: stat) -> mode_t {
    status.st_mode & mode_t(0o7777)
}
