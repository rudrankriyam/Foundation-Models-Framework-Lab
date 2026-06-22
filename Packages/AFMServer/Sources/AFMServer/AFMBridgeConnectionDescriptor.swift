import Foundation

public struct AFMBridgeConnectionDescriptor: Sendable, Codable, Equatable {
    public static let currentVersion = 1

    public let version: Int
    public let endpoint: AFMBridgeEndpoint
    public let bearerToken: String
    public let processIdentifier: Int32
    public let launchIdentifier: UUID
    public let modelIdentifiers: [String]
    public let startedAt: Date

    public init(
        version: Int = Self.currentVersion,
        endpoint: AFMBridgeEndpoint,
        bearerToken: String,
        processIdentifier: Int32,
        launchIdentifier: UUID,
        modelIdentifiers: [String],
        startedAt: Date
    ) {
        self.version = version
        self.endpoint = endpoint
        self.bearerToken = bearerToken
        self.processIdentifier = processIdentifier
        self.launchIdentifier = launchIdentifier
        self.modelIdentifiers = modelIdentifiers
        self.startedAt = startedAt
    }

    public func validated() throws -> Self {
        guard version == Self.currentVersion else {
            throw AFMBridgeDescriptorError.unsupportedVersion(version)
        }
        _ = try endpoint.validated()
        guard Self.isValidBearerToken(bearerToken) else {
            throw AFMBridgeDescriptorError.invalidField("bearerToken")
        }
        guard processIdentifier > 0 else {
            throw AFMBridgeDescriptorError.invalidField("processIdentifier")
        }
        guard !modelIdentifiers.isEmpty,
              modelIdentifiers.allSatisfy(Self.isValidModelIdentifier),
              Set(modelIdentifiers).count == modelIdentifiers.count else {
            throw AFMBridgeDescriptorError.invalidField("modelIdentifiers")
        }
        guard startedAt.timeIntervalSinceReferenceDate.isFinite else {
            throw AFMBridgeDescriptorError.invalidField("startedAt")
        }
        return self
    }

    private static func isValidBearerToken(_ token: String) -> Bool {
        token.utf8.count == AFMBridgeBearerTokenGenerator.encodedByteCount
            && token.utf8.allSatisfy { byte in
                switch byte {
                case 45, 48...57, 65...90, 95, 97...122:
                    true
                default:
                    false
                }
            }
    }

    private static func isValidModelIdentifier(_ identifier: String) -> Bool {
        !identifier.isEmpty
            && identifier == identifier.trimmingCharacters(in: .whitespacesAndNewlines)
            && !identifier.contains("\0")
    }
}

extension AFMBridgeConnectionDescriptor: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public var description: String {
        "AFMBridgeConnectionDescriptor(version: \(version), endpoint: \(endpoint), "
            + "bearerToken: <redacted>, processIdentifier: \(processIdentifier), "
            + "launchIdentifier: \(launchIdentifier), modelIdentifiers: \(modelIdentifiers), "
            + "startedAt: \(startedAt))"
    }

    public var debugDescription: String { description }

    public var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "version": version,
                "endpoint": endpoint,
                "bearerToken": "<redacted>",
                "processIdentifier": processIdentifier,
                "launchIdentifier": launchIdentifier,
                "modelIdentifiers": modelIdentifiers,
                "startedAt": startedAt
            ],
            displayStyle: .struct
        )
    }
}
