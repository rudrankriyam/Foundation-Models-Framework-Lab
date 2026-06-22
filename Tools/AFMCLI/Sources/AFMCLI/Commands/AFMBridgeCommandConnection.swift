import AFMServer
import Darwin
import Foundation

struct AFMBridgeCommandConnection: Sendable {
    let paths: ResolvedBridgePaths
    let descriptor: AFMBridgeConnectionDescriptor
    let client: AFMBridgeClient

    static func connect(paths: ResolvedBridgePaths) throws -> Self {
        let descriptor = try paths.readDescriptor()
        return try connect(paths: paths, descriptor: descriptor)
    }

    static func connect(
        paths: ResolvedBridgePaths,
        descriptor: AFMBridgeConnectionDescriptor
    ) throws -> Self {
        do {
            return try Self(
                paths: paths,
                descriptor: descriptor,
                client: AFMBridgeClient(descriptor: descriptor)
            )
        } catch {
            throw AFMBridgeCommandError.invalidDescriptor(
                descriptorPath: paths.descriptorPath,
                reason: error.localizedDescription
            )
        }
    }

    var endpointDescription: String {
        switch descriptor.endpoint {
        case .unixSocket(let path):
            return "unix://\(path)"
        case .loopbackTCP(let host, let port):
            let renderedHost = host.contains(":") ? "[\(host)]" : host
            return "http://\(renderedHost):\(port)"
        }
    }

    func health() async throws -> AFMBridgeHealthResponse {
        try await decodeResponse({ try await client.health() }, as: AFMBridgeHealthResponse.self)
    }

    func models() async throws -> AFMBridgeModelsResponse {
        try await decodeResponse({ try await client.models() }, as: AFMBridgeModelsResponse.self)
    }

    func chat(body: Data) async throws -> AFMBridgeChatResponse {
        try await decodeResponse(
            { try await client.chatCompletions(body: body) },
            as: AFMBridgeChatResponse.self
        )
    }

    private func decodeResponse<Response: Decodable>(
        _ operation: () async throws -> AFMBridgeClientResponse,
        as type: Response.Type
    ) async throws -> Response {
        let response: AFMBridgeClientResponse
        do {
            response = try await operation()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if !bridgeProcessIsRunning(descriptor.processIdentifier) {
                throw AFMBridgeCommandError.hostStopped(descriptorPath: paths.descriptorPath)
            }
            throw AFMBridgeCommandError.hostUnreachable(
                endpoint: endpointDescription,
                reason: error.localizedDescription
            )
        }

        guard (200..<300).contains(response.statusCode) else {
            let envelope = try? JSONDecoder().decode(AFMBridgeAPIErrorEnvelope.self, from: response.body)
            throw AFMBridgeCommandError.apiFailure(
                statusCode: response.statusCode,
                message: envelope?.error.message ?? "The host rejected the request.",
                code: envelope?.error.code
            )
        }

        do {
            return try JSONDecoder().decode(type, from: response.body)
        } catch {
            throw AFMBridgeCommandError.invalidResponse(endpoint: endpointDescription)
        }
    }
}

private struct AFMBridgeAPIErrorEnvelope: Decodable {
    struct Detail: Decodable {
        let message: String
        let code: String?
    }

    let error: Detail
}

private func bridgeProcessIsRunning(_ processIdentifier: Int32) -> Bool {
    if Darwin.kill(processIdentifier, 0) == 0 {
        return true
    }
    return errno == EPERM
}
