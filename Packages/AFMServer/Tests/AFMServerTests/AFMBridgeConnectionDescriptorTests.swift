import Foundation
import Testing
@testable import AFMServer

@Test("Bridge descriptors round-trip without exposing their bearer token in descriptions")
func bridgeDescriptorCodableRoundTripAndRedaction() throws {
    let token = try AFMBridgeBearerTokenGenerator.generate()
    let descriptor = try makeAFMBridgeTestDescriptor(
        token: token,
        launchIdentifier: UUID(uuidString: "7C34288D-32AF-43B3-BB42-8AE094776ACC")!,
        modelIdentifiers: ["system", "pcc"]
    )

    let encoded = try JSONEncoder().encode(descriptor)
    let decoded = try JSONDecoder().decode(AFMBridgeConnectionDescriptor.self, from: encoded)

    #expect(decoded == descriptor)
    #expect(try decoded.validated() == descriptor)
    #expect(!descriptor.description.contains(token))
    #expect(!descriptor.debugDescription.contains(token))
    #expect(!String(reflecting: descriptor).contains(token))
    #expect(descriptor.customMirror.children.allSatisfy { String(describing: $0.value) != token })
    #expect(descriptor.description.contains("<redacted>"))
}

@Test("Bridge descriptors preserve loopback TCP endpoints")
func bridgeDescriptorLoopbackTCPRoundTrip() throws {
    let descriptor = try makeAFMBridgeTestDescriptor(
        endpoint: .loopbackTCP(host: "127.0.0.1", port: 19_760)
    )
    let encoded = try JSONEncoder().encode(descriptor)
    let decoded = try JSONDecoder().decode(AFMBridgeConnectionDescriptor.self, from: encoded)

    #expect(try decoded.validated() == descriptor)
    #expect(decoded.endpoint == .loopbackTCP(host: "127.0.0.1", port: 19_760))
}

@Test("Bridge descriptors reject invalid connection fields")
func bridgeDescriptorValidation() throws {
    let token = try AFMBridgeBearerTokenGenerator.generate()

    #expect(throws: AFMBridgeDescriptorError.unsupportedVersion(2)) {
        try AFMBridgeConnectionDescriptor(
            version: 2,
            endpoint: .unixSocket(path: "/tmp/bridge.sock"),
            bearerToken: token,
            processIdentifier: 1,
            launchIdentifier: UUID(),
            modelIdentifiers: ["system"],
            startedAt: .now
        ).validated()
    }
    #expect(throws: AFMBridgeDescriptorError.invalidField("endpoint.unixSocket.path")) {
        try makeAFMBridgeTestDescriptor(endpoint: .unixSocket(path: "relative.sock"), token: token).validated()
    }
    #expect(throws: AFMBridgeDescriptorError.invalidField("bearerToken")) {
        try makeAFMBridgeTestDescriptor(token: "not-a-32-byte-token").validated()
    }
    #expect(throws: AFMBridgeDescriptorError.invalidField("processIdentifier")) {
        try makeAFMBridgeTestDescriptor(token: token, processIdentifier: 0).validated()
    }
    #expect(throws: AFMBridgeDescriptorError.invalidField("modelIdentifiers")) {
        try makeAFMBridgeTestDescriptor(token: token, modelIdentifiers: ["system", "system"]).validated()
    }
    #expect(throws: AFMBridgeDescriptorError.invalidField("modelIdentifiers")) {
        try makeAFMBridgeTestDescriptor(token: token, modelIdentifiers: [" pcc"]).validated()
    }
}
