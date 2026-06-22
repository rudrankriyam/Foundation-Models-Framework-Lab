import Foundation
import NIOHTTP1

enum AFMRequestRoute {
    case immediate(AFMHTTPResponse)
    case chatCompletion(origin: String?)
}

struct AFMRequestRouter: Sendable {
    private let configuration: AFMServerConfiguration
    private let catalog: any AFMModelCatalog
    private let clock: any AFMServerClock
    private let chatCompletions: AFMChatCompletionService?

    init(
        configuration: AFMServerConfiguration,
        catalog: any AFMModelCatalog,
        clock: any AFMServerClock,
        chatCompletions: AFMChatCompletionService? = nil
    ) {
        self.configuration = configuration
        self.catalog = catalog
        self.clock = clock
        self.chatCompletions = chatCompletions
    }

    func response(for request: HTTPRequestHead) -> AFMHTTPResponse {
        switch route(for: request) {
        case .immediate(let response):
            return response
        case .chatCompletion:
            return .apiError(
                status: .internalServerError,
                message: "This route requires asynchronous request handling.",
                code: "internal_error",
                type: "server_error"
            )
        }
    }

    func route(for request: HTTPRequestHead) -> AFMRequestRoute {
        if case .tcp(let host, _) = configuration.endpoint,
           AFMHostPolicy.isLoopbackBinding(host),
           !AFMHostPolicy.validatesLoopbackHostHeader(request.headers, bindingHost: host) {
            return .immediate(.apiError(
                status: .forbidden,
                message: "The Host header is not allowed for this loopback server.",
                code: "forbidden_host"
            ))
        }

        let originResult = validateOrigin(request.headers)
        guard originResult.isAllowed else {
            return .immediate(.apiError(
                status: .forbidden,
                message: "Cross-site requests are not allowed.",
                code: "origin_not_allowed"
            ))
        }

        guard validatesAuthorization(request.headers) else {
            var headers = HTTPHeaders()
            headers.add(name: "www-authenticate", value: "Bearer")
            return .immediate(AFMHTTPResponse.apiError(
                status: .unauthorized,
                message: "A valid bearer token is required.",
                code: "invalid_api_key",
                type: "authentication_error",
                headers: headers
            ).addingOrigin(originResult.origin))
        }

        let path = request.uri.split(separator: "?", maxSplits: 1).first.map(String.init) ?? request.uri
        let route: AFMRequestRoute
        switch path {
        case "/health":
            route = .immediate(responseForKnownRoute(request, body: healthResponse))
        case "/v1/models":
            route = .immediate(responseForKnownRoute(request, body: modelsResponse))
        case "/v1/chat/completions":
            route = routeChatCompletion(request, origin: originResult.origin)
        default:
            route = .immediate(.apiError(
                status: .notFound,
                message: "The requested endpoint was not found.",
                code: "not_found"
            ))
        }
        return route.addingOrigin(originResult.origin)
    }

    func chatCompletionResponse(body: Data, origin: String?) async throws -> AFMHTTPResponse {
        guard let chatCompletions else {
            return AFMHTTPResponse.apiError(
                status: .notImplemented,
                message: "Chat completions are not configured for this server.",
                code: "not_implemented",
                type: "server_error"
            ).addingOrigin(origin)
        }
        return try await chatCompletions.response(for: body).addingOrigin(origin)
    }

    func requiresJSONBody(_ request: HTTPRequestHead) -> Bool {
        request.method == .POST && normalizedPath(request.uri) == "/v1/chat/completions"
    }

    private func routeChatCompletion(_ request: HTTPRequestHead, origin: String?) -> AFMRequestRoute {
        guard request.method == .POST else {
            var headers = HTTPHeaders()
            headers.add(name: "allow", value: "POST")
            return .immediate(
                .apiError(
                    status: .methodNotAllowed,
                    message: "This endpoint only accepts POST requests.",
                    code: "method_not_allowed",
                    headers: headers
                )
            )
        }
        return .chatCompletion(origin: origin)
    }

    private func responseForKnownRoute<T: Encodable>(
        _ request: HTTPRequestHead,
        body: () -> T
    ) -> AFMHTTPResponse {
        guard request.method == .GET else {
            var headers = HTTPHeaders()
            headers.add(name: "allow", value: "GET")
            return .apiError(
                status: .methodNotAllowed,
                message: "This endpoint only accepts GET requests.",
                code: "method_not_allowed",
                headers: headers
            )
        }
        return .json(body: body())
    }

    private func healthResponse() -> AFMHealthPayload {
        let models = catalog.models().sorted { $0.id < $1.id }
        return AFMHealthPayload(
            status: "afm serve is running",
            models: models.map { .init(name: $0.id, available: $0.isAvailable) }
        )
    }

    private func modelsResponse() -> AFMModelsPayload {
        let created = clock.unixTime()
        let models = catalog.models().sorted { $0.id < $1.id }
        return AFMModelsPayload(
            object: "list",
            data: models.map {
                .init(id: $0.id, object: "model", created: created, owner: $0.owner)
            }
        )
    }

    private func validateOrigin(_ headers: HTTPHeaders) -> (isAllowed: Bool, origin: String?) {
        let origins = headers["origin"]
        guard !origins.isEmpty else { return (true, nil) }
        guard origins.count == 1, configuration.security.allowedOrigins.contains(origins[0]) else {
            return (false, nil)
        }
        return (true, origins[0])
    }

    private func validatesAuthorization(_ headers: HTTPHeaders) -> Bool {
        guard let expectedToken = configuration.security.bearerToken else { return true }
        let values = headers["authorization"]
        guard values.count == 1 else { return false }

        let parts = values[0].split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        guard parts.count == 2, parts[0].lowercased() == "bearer" else { return false }
        return constantTimeEquals(String(parts[1]), expectedToken)
    }

    private func constantTimeEquals(_ provided: String, _ expected: String) -> Bool {
        let lhs = Array(provided.utf8)
        let rhs = Array(expected.utf8)
        var difference = UInt(lhs.count ^ rhs.count)
        for index in 0..<max(lhs.count, rhs.count) {
            let lhsByte = index < lhs.count ? lhs[index] : 0
            let rhsByte = index < rhs.count ? rhs[index] : 0
            difference |= UInt(lhsByte ^ rhsByte)
        }
        return difference == 0
    }

    private func normalizedPath(_ uri: String) -> String {
        uri.split(separator: "?", maxSplits: 1).first.map(String.init) ?? uri
    }
}

private extension AFMRequestRoute {
    func addingOrigin(_ origin: String?) -> Self {
        switch self {
        case .immediate(let response):
            return .immediate(response.addingOrigin(origin))
        case .chatCompletion:
            return self
        }
    }
}

private extension AFMHTTPResponse {
    func addingOrigin(_ origin: String?) -> Self {
        guard let origin else { return self }
        var updatedHeaders = headers
        updatedHeaders.add(name: "access-control-allow-origin", value: origin)
        updatedHeaders.add(name: "vary", value: "Origin")
        return .init(status: status, headers: updatedHeaders, body: body)
    }
}

private struct AFMHealthPayload: Encodable {
    struct Model: Encodable {
        let name: String
        let available: Bool
    }

    let status: String
    let models: [Model]
}

private struct AFMModelsPayload: Encodable {
    struct Model: Encodable {
        let id: String
        let object: String
        let created: Int64
        let owner: String

        enum CodingKeys: String, CodingKey {
            case id
            case object
            case created
            case owner = "owned_by"
        }
    }

    let object: String
    let data: [Model]
}
