import Foundation
import FoundationModelsKit
import Testing
@testable import AFMServer

@Test("Chat completion responses expose OpenAI fields and truthful token provenance")
func chatCompletionResponseShape() async throws {
    let usage = ModelTokenUsage(
        input: .init(totalTokenCount: 11, cachedTokenCount: 2),
        output: .init(totalTokenCount: 7, reasoningTokenCount: 3),
        measurement: .observed,
        scope: .response
    )
    let generator = RecordingGenerator(result: .init(content: "Hello", usage: usage))
    let service = testChatService(generator: generator)

    let response = try await service.response(for: chatBody())
    #expect(response.status == .ok)
    let json = try serviceJSONObject(response.body)
    #expect(json["object"] as? String == "chat.completion")
    #expect(json["created"] as? Int == 123)
    #expect(json["model"] as? String == "system")
    #expect((json["id"] as? String)?.hasPrefix("chatcmpl-") == true)

    let choices = try #require(json["choices"] as? [[String: Any]])
    let message = try #require(choices.first?["message"] as? [String: Any])
    #expect(message["role"] as? String == "assistant")
    #expect(message["content"] as? String == "Hello")
    #expect(message["refusal"] is NSNull)
    #expect(choices.first?["finish_reason"] as? String == "stop")
    #expect(choices.first?["logprobs"] is NSNull)

    let usageJSON = try #require(json["usage"] as? [String: Any])
    #expect(usageJSON["prompt_tokens"] as? Int == 11)
    #expect(usageJSON["completion_tokens"] as? Int == 7)
    #expect(usageJSON["total_tokens"] as? Int == 18)
    #expect(usageJSON["afm_measurement"] as? String == "observed")
    #expect(usageJSON["afm_scope"] as? String == "response")
    let promptDetails = try #require(usageJSON["prompt_tokens_details"] as? [String: Any])
    let completionDetails = try #require(usageJSON["completion_tokens_details"] as? [String: Any])
    #expect(promptDetails["cached_tokens"] as? Int == 2)
    #expect(completionDetails["reasoning_tokens"] as? Int == 3)
    let recorded = await generator.recordedRequests()
    #expect(recorded.count == 1)
}

@Test("Tool calls use canonical OpenAI message fields and finish reason")
func chatCompletionToolCallShape() async throws {
    let usage = ModelTokenUsage(
        input: .init(totalTokenCount: 14),
        output: .init(totalTokenCount: 9),
        measurement: .tokenized,
        scope: .response
    )
    let generator = RecordingGenerator(
        result: .init(
            content: nil,
            finishReason: .toolCalls,
            usage: usage,
            toolCalls: [
                .init(id: "call_a", name: "weather", arguments: #"{"city":"Paris"}"#),
                .init(id: "call_b", name: "calendar", arguments: #"{"day":"Monday"}"#)
            ]
        )
    )

    let response = try await testChatService(generator: generator).response(for: chatBody())
    let json = try serviceJSONObject(response.body)
    let choices = try #require(json["choices"] as? [[String: Any]])
    let choice = try #require(choices.first)
    let message = try #require(choice["message"] as? [String: Any])
    #expect(message["content"] is NSNull)
    #expect(message["refusal"] is NSNull)
    #expect(choice["finish_reason"] as? String == "tool_calls")
    let calls = try #require(message["tool_calls"] as? [[String: Any]])
    #expect(calls.map { $0["id"] as? String } == ["call_a", "call_b"])
    #expect(calls.allSatisfy { $0["type"] as? String == "function" })
    let firstFunction = try #require(calls[0]["function"] as? [String: Any])
    #expect(firstFunction["name"] as? String == "weather")
    #expect(firstFunction["arguments"] as? String == #"{"city":"Paris"}"#)
    let usageJSON = try #require(json["usage"] as? [String: Any])
    #expect(usageJSON["completion_tokens"] as? Int == 9)
    #expect(usageJSON["afm_measurement"] as? String == "tokenized")
}

@Test("Unsupported forced tool choices produce a precise API error")
func chatCompletionUnsupportedToolChoice() async throws {
    let service = testChatService(generator: FailingGenerator(error: .unsupportedToolChoice))
    let response = try await service.response(for: chatBody())
    #expect(response.status == .badRequest)
    let json = try serviceJSONObject(response.body)
    let error = try #require(json["error"] as? [String: Any])
    #expect(error["code"] as? String == "unsupported_tool_choice")
    #expect(error["param"] as? String == "tool_choice")
}

@Test("Structured completions keep JSON in message content and preserve usage")
func structuredChatCompletionResponse() async throws {
    let usage = ModelTokenUsage(
        input: .init(totalTokenCount: 21, cachedTokenCount: 3),
        output: .init(totalTokenCount: 8, reasoningTokenCount: 2),
        measurement: .observed,
        scope: .response
    )
    let generator = RecordingGenerator(
        result: .init(content: #"{"name":"Ada"}"#, usage: usage)
    )
    let response = try await testChatService(generator: generator).response(
        for: structuredChatBody()
    )

    #expect(response.status == .ok)
    let json = try serviceJSONObject(response.body)
    let choices = try #require(json["choices"] as? [[String: Any]])
    let message = try #require(choices.first?["message"] as? [String: Any])
    let content = try #require(message["content"] as? String)
    let structuredContent = try #require(
        JSONSerialization.jsonObject(with: Data(content.utf8)) as? [String: String]
    )
    #expect(structuredContent == ["name": "Ada"])
    #expect(choices.first?["finish_reason"] as? String == "stop")

    let usageJSON = try #require(json["usage"] as? [String: Any])
    #expect(usageJSON["prompt_tokens"] as? Int == 21)
    #expect(usageJSON["completion_tokens"] as? Int == 8)
    #expect(usageJSON["afm_measurement"] as? String == "observed")

    let recorded = await generator.recordedRequests()
    let responseFormat = try #require(recorded.first?.responseFormat)
    guard case .jsonSchema(let schema) = responseFormat else {
        Issue.record("Expected a JSON schema response format")
        return
    }
    #expect(schema.name == "person")
    #expect(schema.strict)
}

@Test("Refusals remain successful completions with null content")
func chatCompletionRefusal() async throws {
    let usage = ModelTokenUsage(inputTokenCount: 4, measurement: .estimated, scope: .response)
    let generator = RecordingGenerator(
        result: .init(
            content: nil,
            refusal: "Declined",
            finishReason: .contentFilter,
            usage: usage
        )
    )
    let response = try await testChatService(generator: generator).response(for: chatBody())
    let json = try serviceJSONObject(response.body)
    let choices = try #require(json["choices"] as? [[String: Any]])
    let message = try #require(choices.first?["message"] as? [String: Any])
    #expect(message["content"] is NSNull)
    #expect(message["refusal"] as? String == "Declined")
    #expect(choices.first?["finish_reason"] as? String == "content_filter")
}

@Test("Model validation happens before the generator is called")
func chatCompletionModelValidation() async throws {
    let generator = RecordingGenerator(result: standardResult())
    let catalog = AFMStaticModelCatalog(
        models: [.init(id: "system", isAvailable: false)]
    )
    let service = testChatService(generator: generator, catalog: catalog)

    let unavailable = try await service.response(for: chatBody())
    #expect(unavailable.status == .serviceUnavailable)
    #expect(try serviceErrorCode(unavailable.body) == "model_unavailable")

    let unknown = try await service.response(for: chatBody(model: "missing"))
    #expect(unknown.status == .notFound)
    #expect(try serviceErrorCode(unknown.body) == "model_not_found")
    #expect((await generator.recordedRequests()).isEmpty)
}

@Test("Generation concurrency is bounded without an implicit queue")
func chatCompletionConcurrencyLimit() async throws {
    let probe = GenerationProbe()
    let service = testChatService(
        generator: PausingGenerator(probe: probe),
        policy: .init(maximumConcurrentGenerations: 1, timeoutSeconds: 30)
    )
    let first = Task { try await service.response(for: chatBody()) }
    await probe.waitUntilStarted()

    let overloaded = try await service.response(for: chatBody())
    #expect(overloaded.status == .tooManyRequests)
    #expect(try serviceErrorCode(overloaded.body) == "server_busy")
    first.cancel()
    _ = try? await first.value
}

@Test("Generation timeout cancels model work and returns a structured 504")
func chatCompletionTimeout() async throws {
    let probe = GenerationProbe()
    let service = testChatService(
        generator: PausingGenerator(probe: probe),
        policy: .init(maximumConcurrentGenerations: 1, timeoutSeconds: 0.01)
    )

    let response = try await service.response(for: chatBody())
    #expect(response.status == .gatewayTimeout)
    #expect(try serviceErrorCode(response.body) == "model_timeout")
    await probe.waitUntilCancelled()
}

private actor RecordingGenerator: AFMChatCompletionGenerating {
    private let result: AFMChatGenerationResult
    private var requests: [AFMChatGenerationRequest] = []

    init(result: AFMChatGenerationResult) {
        self.result = result
    }

    func generate(_ request: AFMChatGenerationRequest) async throws -> AFMChatGenerationResult {
        requests.append(request)
        return result
    }

    func recordedRequests() -> [AFMChatGenerationRequest] {
        requests
    }
}

private struct PausingGenerator: AFMChatCompletionGenerating {
    let probe: GenerationProbe

    func generate(_ request: AFMChatGenerationRequest) async throws -> AFMChatGenerationResult {
        await probe.markStarted()
        return try await withTaskCancellationHandler {
            try await ContinuousClock().sleep(for: .seconds(30))
            return standardResult()
        } onCancel: {
            Task { await probe.markCancelled() }
        }
    }
}

private struct FailingGenerator: AFMChatCompletionGenerating {
    let error: AFMChatGenerationError

    func generate(_ request: AFMChatGenerationRequest) async throws -> AFMChatGenerationResult {
        throw error
    }
}

private actor GenerationProbe {
    private var started = false
    private var cancelled = false

    func markStarted() { started = true }
    func markCancelled() { cancelled = true }

    func waitUntilStarted() async {
        while !started { await Task.yield() }
    }

    func waitUntilCancelled() async {
        while !cancelled { await Task.yield() }
    }
}

private struct ServiceTestClock: AFMServerClock {
    func unixTime() -> Int64 { 123 }
}

private func testChatService(
    generator: any AFMChatCompletionGenerating,
    catalog: any AFMModelCatalog = AFMStaticModelCatalog(
        models: [.init(id: "system", isAvailable: true)]
    ),
    policy: AFMServerGenerationPolicy = .init()
) -> AFMChatCompletionService {
    AFMChatCompletionService(
        catalog: catalog,
        generator: generator,
        clock: ServiceTestClock(),
        policy: policy
    )
}

private func standardResult() -> AFMChatGenerationResult {
    .init(
        content: "Done",
        usage: .init(inputTokenCount: 1, measurement: .estimated, scope: .response)
    )
}

private func chatBody(model: String = "system") -> Data {
    Data(#"{"model":"\#(model)","messages":[{"role":"user","content":"Hi"}]}"#.utf8)
}

private func structuredChatBody() -> Data {
    Data(
        #"""
        {
          "model": "system",
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
        """#.utf8
    )
}

private func serviceJSONObject(_ data: Data) throws -> [String: Any] {
    try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
}

private func serviceErrorCode(_ data: Data) throws -> String? {
    let json = try serviceJSONObject(data)
    let error = try #require(json["error"] as? [String: Any])
    return error["code"] as? String
}
