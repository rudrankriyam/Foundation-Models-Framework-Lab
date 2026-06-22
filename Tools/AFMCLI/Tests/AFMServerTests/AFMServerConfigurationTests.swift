import Testing
@testable import AFMServer

@Test("Loopback bindings do not require network opt-in")
func loopbackBindings() throws {
    for host in ["localhost", "127.0.0.1", "127.2.3.4", "::1", "[::1]"] {
        let configuration = AFMServerConfiguration(endpoint: .tcp(host: host, port: 1976))
        let validated = try configuration.validated()
        let expectedHost = host == "[::1]" ? "::1" : host
        #expect(validated.endpoint == .tcp(host: expectedHost, port: 1976))
    }
}

@Test("Non-loopback bindings require explicit opt-in and authentication")
func networkBindingSecurity() throws {
    let implicit = AFMServerConfiguration(endpoint: .tcp(host: "0.0.0.0", port: 1976))
    #expect(throws: AFMServerConfigurationError.networkOptInRequired("0.0.0.0")) {
        _ = try implicit.validated()
    }

    let unauthenticated = AFMServerConfiguration(
        endpoint: .tcp(host: "0.0.0.0", port: 1976),
        security: .init(allowNetwork: true)
    )
    #expect(throws: AFMServerConfigurationError.networkAuthenticationRequired("0.0.0.0")) {
        _ = try unauthenticated.validated()
    }

    let authenticated = AFMServerConfiguration(
        endpoint: .tcp(host: "0.0.0.0", port: 1976),
        security: .init(allowNetwork: true, bearerToken: "secret")
    )
    #expect(throws: Never.self) {
        _ = try authenticated.validated()
    }
}

@Test("Origin allowlists accept exact web origins only")
func allowedOriginValidation() throws {
    for origin in ["", "*", "null", "https://example.com/", "https://example.com/path", "file://local"] {
        let configuration = AFMServerConfiguration(
            security: .init(allowedOrigins: [origin])
        )
        #expect(throws: AFMServerConfigurationError.invalidAllowedOrigin) {
            _ = try configuration.validated()
        }
    }

    let configuration = AFMServerConfiguration(
        security: .init(allowedOrigins: ["https://example.com", "http://localhost:8080"])
    )
    #expect(throws: Never.self) {
        _ = try configuration.validated()
    }
}

@Test("Transport and parser limits validate before the server starts")
func transportLimitValidation() throws {
    let invalidPort = AFMServerConfiguration(endpoint: .tcp(host: "127.0.0.1", port: 65_536))
    #expect(throws: AFMServerConfigurationError.invalidPort(65_536)) {
        _ = try invalidPort.validated()
    }

    let invalidLimits = AFMServerConfiguration(
        limits: .init(maximumHeaderBytes: 10, maximumHeaderFieldBytes: 11)
    )
    #expect(throws: AFMServerConfigurationError.invalidLimits) {
        _ = try invalidLimits.validated()
    }

    let relativeSocket = AFMServerConfiguration(endpoint: .unixSocket(path: "afm.sock"))
    #expect(throws: AFMServerConfigurationError.invalidSocketPath) {
        _ = try relativeSocket.validated()
    }

    let nullSocket = AFMServerConfiguration(endpoint: .unixSocket(path: "/tmp/afm\0shadow.sock"))
    #expect(throws: AFMServerConfigurationError.invalidSocketPath) {
        _ = try nullSocket.validated()
    }
}
