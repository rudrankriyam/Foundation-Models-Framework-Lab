import Foundation

public enum AFMServerEndpoint: Sendable, Equatable {
    case tcp(host: String, port: Int)
    case unixSocket(path: String)
}

public struct AFMServerLimits: Sendable, Equatable {
    public var maximumBodyBytes: Int
    public var maximumHeaderBytes: Int
    public var maximumHeaderFieldBytes: Int
    public var maximumHeaderCount: Int

    public init(
        maximumBodyBytes: Int = 1_048_576,
        maximumHeaderBytes: Int = 65_536,
        maximumHeaderFieldBytes: Int = 16_384,
        maximumHeaderCount: Int = 100
    ) {
        self.maximumBodyBytes = maximumBodyBytes
        self.maximumHeaderBytes = maximumHeaderBytes
        self.maximumHeaderFieldBytes = maximumHeaderFieldBytes
        self.maximumHeaderCount = maximumHeaderCount
    }
}

public struct AFMServerSecurity: Sendable, Equatable {
    public var allowNetwork: Bool
    public var bearerToken: String?
    public var allowedOrigins: Set<String>

    public init(
        allowNetwork: Bool = false,
        bearerToken: String? = nil,
        allowedOrigins: Set<String> = []
    ) {
        self.allowNetwork = allowNetwork
        self.bearerToken = bearerToken
        self.allowedOrigins = allowedOrigins
    }
}

public struct AFMServerGenerationPolicy: Sendable, Equatable {
    public var maximumConcurrentGenerations: Int
    public var timeoutSeconds: Double

    public init(
        maximumConcurrentGenerations: Int = 1,
        timeoutSeconds: Double = 120
    ) {
        self.maximumConcurrentGenerations = maximumConcurrentGenerations
        self.timeoutSeconds = timeoutSeconds
    }
}

public struct AFMServerConfiguration: Sendable, Equatable {
    public var endpoint: AFMServerEndpoint
    public var limits: AFMServerLimits
    public var security: AFMServerSecurity
    public var generation: AFMServerGenerationPolicy

    public init(
        endpoint: AFMServerEndpoint = .tcp(host: "127.0.0.1", port: 1976),
        limits: AFMServerLimits = .init(),
        security: AFMServerSecurity = .init(),
        generation: AFMServerGenerationPolicy = .init()
    ) {
        self.endpoint = endpoint
        self.limits = limits
        self.security = security
        self.generation = generation
    }

    public func validated() throws -> Self {
        try validateLimits()
        try validateSecurity()
        try validateGenerationPolicy()

        var validatedConfiguration = self
        validatedConfiguration.endpoint = try validatedEndpoint()
        return validatedConfiguration
    }

    private func validateLimits() throws {
        guard limits.maximumBodyBytes > 0,
              limits.maximumHeaderBytes > 0,
              limits.maximumHeaderFieldBytes > 0,
              limits.maximumHeaderFieldBytes <= limits.maximumHeaderBytes,
              limits.maximumHeaderCount > 0 else {
            throw AFMServerConfigurationError.invalidLimits
        }
    }

    private func validateSecurity() throws {
        if let bearerToken = security.bearerToken, bearerToken.isEmpty {
            throw AFMServerConfigurationError.emptyBearerToken
        }
        if security.allowedOrigins.contains(where: { !Self.isValidOrigin($0) }) {
            throw AFMServerConfigurationError.invalidAllowedOrigin
        }
    }

    private func validateGenerationPolicy() throws {
        guard generation.maximumConcurrentGenerations > 0 else {
            throw AFMServerConfigurationError.invalidGenerationConcurrency
        }
        guard generation.timeoutSeconds.isFinite, generation.timeoutSeconds > 0 else {
            throw AFMServerConfigurationError.invalidGenerationTimeout
        }
    }

    private func validatedEndpoint() throws -> AFMServerEndpoint {
        switch endpoint {
        case .tcp(let host, let port):
            return try validatedTCPEndpoint(host: host, port: port)
        case .unixSocket(let path):
            guard path.hasPrefix("/"), path.count > 1, !path.utf8.contains(0) else {
                throw AFMServerConfigurationError.invalidSocketPath
            }
            return .unixSocket(path: path)
        }
    }

    private func validatedTCPEndpoint(host: String, port: Int) throws -> AFMServerEndpoint {
        let normalizedHost = Self.normalizedBindingHost(host)
        guard !normalizedHost.isEmpty else {
            throw AFMServerConfigurationError.emptyHost
        }
        guard (0...65_535).contains(port) else {
            throw AFMServerConfigurationError.invalidPort(port)
        }
        if !AFMHostPolicy.isLoopbackBinding(normalizedHost) {
            try validateNetworkSecurity(host: normalizedHost)
        }
        return .tcp(host: normalizedHost, port: port)
    }

    private func validateNetworkSecurity(host: String) throws {
        guard security.allowNetwork else {
            throw AFMServerConfigurationError.networkOptInRequired(host)
        }
        guard security.bearerToken != nil else {
            throw AFMServerConfigurationError.networkAuthenticationRequired(host)
        }
    }

    private static func isValidOrigin(_ origin: String) -> Bool {
        guard origin == origin.trimmingCharacters(in: .whitespacesAndNewlines),
              let components = URLComponents(string: origin),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              components.host != nil,
              components.user == nil,
              components.password == nil,
              components.path.isEmpty,
              components.query == nil,
              components.fragment == nil else {
            return false
        }
        return true
    }

    private static func normalizedBindingHost(_ host: String) -> String {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedHost.hasPrefix("["), trimmedHost.hasSuffix("]") else { return trimmedHost }
        return String(trimmedHost.dropFirst().dropLast())
    }
}

public enum AFMServerConfigurationError: Error, Equatable, LocalizedError {
    case emptyHost
    case invalidPort(Int)
    case invalidLimits
    case emptyBearerToken
    case invalidAllowedOrigin
    case invalidSocketPath
    case invalidGenerationConcurrency
    case invalidGenerationTimeout
    case networkOptInRequired(String)
    case networkAuthenticationRequired(String)

    public var errorDescription: String? {
        switch self {
        case .emptyHost:
            "The server host cannot be empty."
        case .invalidPort(let port):
            "Port \(port) is outside the valid range 0...65535."
        case .invalidLimits:
            "Server limits must be positive and internally consistent."
        case .emptyBearerToken:
            "The bearer token cannot be empty."
        case .invalidAllowedOrigin:
            "Allowed origins must be exact, non-empty origins; wildcards are not accepted."
        case .invalidSocketPath:
            "The Unix-domain socket path must be an absolute path."
        case .invalidGenerationConcurrency:
            "The maximum concurrent generation count must be greater than zero."
        case .invalidGenerationTimeout:
            "The model timeout must be a finite number greater than zero."
        case .networkOptInRequired(let host):
            "Binding to non-loopback host '\(host)' requires explicit network opt-in."
        case .networkAuthenticationRequired(let host):
            "Binding to non-loopback host '\(host)' requires a bearer token."
        }
    }
}
