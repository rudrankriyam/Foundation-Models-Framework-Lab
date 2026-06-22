import Foundation
import Testing
@testable import AFMServer

@Test("Bridge endpoints round-trip and accept only supported local transports")
func bridgeEndpointCodableRoundTrip() throws {
    let endpoints: [AFMBridgeEndpoint] = [
        .unixSocket(path: "/tmp/foundation-lab.sock"),
        .loopbackTCP(host: "127.0.0.1", port: 19_760),
        .loopbackTCP(host: "::1", port: 65_535)
    ]

    for endpoint in endpoints {
        #expect(try endpoint.validated() == endpoint)
        let encoded = try JSONEncoder().encode(endpoint)
        #expect(try JSONDecoder().decode(AFMBridgeEndpoint.self, from: encoded) == endpoint)
    }
}

@Test("Unix bridge endpoints require absolute null-free paths")
func bridgeUnixEndpointValidation() {
    #expect(throws: AFMBridgeDescriptorError.invalidField("endpoint.unixSocket.path")) {
        try AFMBridgeEndpoint.unixSocket(path: "relative.sock").validated()
    }
    #expect(throws: AFMBridgeDescriptorError.invalidField("endpoint.unixSocket.path")) {
        try AFMBridgeEndpoint.unixSocket(path: "/tmp/bridge\0shadow.sock").validated()
    }
}

@Test("TCP bridge endpoints require exact numeric loopback hosts and valid ports")
func bridgeLoopbackTCPEndpointValidation() {
    for host in ["localhost", "0.0.0.0", "127.0.0.2", "[::1]", "::"] {
        #expect(throws: AFMBridgeDescriptorError.invalidField("endpoint.loopbackTCP.host")) {
            try AFMBridgeEndpoint.loopbackTCP(host: host, port: 19_760).validated()
        }
    }
    for port in [-1, 0, 65_536] {
        #expect(throws: AFMBridgeDescriptorError.invalidField("endpoint.loopbackTCP.port")) {
            try AFMBridgeEndpoint.loopbackTCP(host: "127.0.0.1", port: port).validated()
        }
    }
}
