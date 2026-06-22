import Foundation
import NIOHTTP1

struct AFMRequestRouter: Sendable {
    private let configuration: AFMServerConfiguration
    private let catalog: any AFMModelCatalog
    private let clock: any AFMServerClock

    init(
        configuration: AFMServerConfiguration,
        catalog: any AFMModelCatalog,
        clock: any AFMServerClock
    ) {
        self.configuration = configuration
        self.catalog = catalog
        self.clock = clock
    }

    func response(for request: HTTPRequestHead) -> AFMHTTPResponse {
        if case .tcp(let host, _) = configuration.endpoint,
           AFMHostPolicy.isLoopbackBinding(host),
           !AFMHostPolicy.validatesLoopbackHostHeader(request.headers, bindingHost: host) {
            return .apiError(
                status: .forbidden,
                message: "The Host header is not allowed for this loopback server.",
                code: "forbidden_host"
            )
        }

        let originResult = validateOrigin(request.headers)
        guard originResult.isAllowed else {
            return .apiError(
                status: .forbidden,
                message: "Cross-site requests are not allowed.",
                code: "origin_not_allowed"
            )
        }

        guard validatesAuthorization(request.headers) else {
            var headers = HTTPHeaders()
            headers.add(name: "www-authenticate", value: "Bearer")
            return AFMHTTPResponse.apiError(
                status: .unauthorized,
                message: "A valid bearer token is required.",
                code: "invalid_api_key",
                type: "authentication_error",
                headers: headers
            ).addingOrigin(originResult.origin)
        }

        let path = request.uri.split(separator: "?", maxSplits: 1).first.map(String.init) ?? request.uri
        let response: AFMHTTPResponse
        switch path {
        case "/health":
            response = responseForKnownRoute(request, body: healthResponse)
        case "/v1/models":
            response = responseForKnownRoute(request, body: modelsResponse)
        default:
            response = .apiError(
                status: .notFound,
                message: "The requested endpoint was not found.",
                code: "not_found"
            )
        }
        return response.addingOrigin(originResult.origin)
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
