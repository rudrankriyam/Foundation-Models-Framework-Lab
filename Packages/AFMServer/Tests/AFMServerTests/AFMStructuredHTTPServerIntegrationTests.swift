import FoundationModelsKit
import Testing
@testable import AFMServer

@Test("TCP transport preserves structured JSON as message content")
func tcpStructuredChatCompletion() async throws {
    let server = try testServer(
        configuration: .init(endpoint: .tcp(host: "127.0.0.1", port: 0)),
        generator: IntegrationStructuredGenerator()
    )

    do {
        let address = try await server.start()
        guard case .tcp(_, let port) = address else {
            Issue.record("Expected a TCP address")
            try await server.stop()
            return
        }
        let body = #"""
        {
          "messages": [{"role": "user", "content": "Ada"}],
          "response_format": {
            "type": "json_schema",
            "json_schema": {
              "name": "person",
              "strict": true,
              "schema": {
                "type": "object",
                "properties": {"name": {"type": "string"}},
                "required": ["name"],
                "additionalProperties": false
              }
            }
          }
        }
        """#
        let response = try sendRawHTTPRequest(
            chatHTTPRequest(body: body, port: port, close: true),
            port: port
        )
        #expect(response.hasPrefix("HTTP/1.1 200 OK"))
        #expect(response.contains(#""content":"{\"name\":\"Ada\"}""#))
        #expect(response.contains(#""finish_reason":"stop""#))
        try await server.stop()
    } catch {
        try? await server.stop()
        throw error
    }
}

private struct IntegrationStructuredGenerator: AFMChatCompletionGenerating {
    func generate(_ request: AFMChatGenerationRequest) async throws -> AFMChatGenerationResult {
        .init(
            content: #"{"name":"Ada"}"#,
            usage: .init(
                input: .init(totalTokenCount: 4),
                output: .init(totalTokenCount: 3),
                measurement: .estimated,
                scope: .response
            )
        )
    }
}
