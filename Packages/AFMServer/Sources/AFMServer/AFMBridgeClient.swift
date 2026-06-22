import Foundation

public struct AFMBridgeClient: Sendable {
    private let endpoint: AFMBridgeEndpoint
    private let baseURL: URL
    private let bearerToken: String
    private let configuration: AFMBridgeClientConfiguration

    public init(
        descriptor: AFMBridgeConnectionDescriptor,
        configuration: AFMBridgeClientConfiguration = .init()
    ) throws {
        let descriptor = try descriptor.validated()
        let configuration = try configuration.validated()
        guard case .loopbackTCP(let host, let port) = descriptor.endpoint else {
            throw AFMBridgeClientError.unsupportedTransport
        }

        endpoint = descriptor.endpoint
        baseURL = try Self.makeBaseURL(host: host, port: port)
        bearerToken = descriptor.bearerToken
        self.configuration = configuration
    }

    public init(
        descriptorStore: AFMBridgeDescriptorStore,
        configuration: AFMBridgeClientConfiguration = .init()
    ) throws {
        try self.init(descriptor: descriptorStore.read(), configuration: configuration)
    }

    public func health() async throws -> AFMBridgeClientResponse {
        try await perform(method: "GET", path: "/health")
    }

    public func models() async throws -> AFMBridgeClientResponse {
        try await perform(method: "GET", path: "/v1/models")
    }

    public func chatCompletions(body: Data) async throws -> AFMBridgeClientResponse {
        try await perform(method: "POST", path: "/v1/chat/completions", body: body)
    }
}

extension AFMBridgeClient: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public var description: String {
        "AFMBridgeClient(endpoint: \(endpoint), bearerToken: <redacted>, configuration: \(configuration))"
    }

    public var debugDescription: String { description }

    public var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "endpoint": endpoint,
                "bearerToken": "<redacted>",
                "configuration": configuration
            ],
            displayStyle: .struct
        )
    }
}

private extension AFMBridgeClient {
    static func makeBaseURL(host: String, port: Int) throws -> URL {
        var components = URLComponents()
        components.scheme = "http"
        components.host = host
        components.port = port
        guard let url = components.url else {
            throw AFMBridgeClientError.invalidResponse
        }
        return url
    }

    func perform(
        method: String,
        path: String,
        body: Data? = nil
    ) async throws -> AFMBridgeClientResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.timeoutInterval = configuration.requestTimeout
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let session = makeURLSession()
        defer { session.invalidateAndCancel() }

        do {
            let (bytes, response) = try await session.bytes(for: request)
            guard let response = response as? HTTPURLResponse else {
                throw AFMBridgeClientError.invalidResponse
            }
            if response.expectedContentLength > Int64(configuration.maximumResponseByteCount) {
                throw AFMBridgeClientError.responseTooLarge(
                    maximumByteCount: configuration.maximumResponseByteCount
                )
            }
            let body = try await AFMBridgeResponseAccumulator.data(
                from: bytes,
                maximumByteCount: configuration.maximumResponseByteCount
            )
            return AFMBridgeClientResponse(statusCode: response.statusCode, body: body)
        } catch let error as AFMBridgeClientError {
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError {
            if Task.isCancelled { throw CancellationError() }
            throw AFMBridgeClientError.transportFailure(code: error.code)
        } catch {
            if Task.isCancelled { throw CancellationError() }
            throw AFMBridgeClientError.transportFailure(code: .unknown)
        }
    }

    func makeURLSession() -> URLSession {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.timeoutIntervalForRequest = configuration.requestTimeout
        sessionConfiguration.timeoutIntervalForResource = configuration.requestTimeout
        sessionConfiguration.waitsForConnectivity = false
        sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalCacheData
        sessionConfiguration.urlCache = nil
        sessionConfiguration.httpCookieStorage = nil
        sessionConfiguration.httpShouldSetCookies = false
        sessionConfiguration.urlCredentialStorage = nil
        sessionConfiguration.connectionProxyDictionary = [:]
        return URLSession(
            configuration: sessionConfiguration,
            delegate: AFMBridgeURLSessionDelegate(),
            delegateQueue: nil
        )
    }

}
