import Foundation
import FoundationModelsKit
import NIOHTTP1
import Testing
@testable import AFMServer

@Suite("Streaming chat completions")
struct AFMChatStreamingServiceTests {
    @Test("Streaming emits role, content deltas, finish, usage, and DONE")
    func completeStreamShape() async throws {
        let usage = ModelTokenUsage(
            input: .init(totalTokenCount: 11, cachedTokenCount: 2),
            output: .init(totalTokenCount: 7, reasoningTokenCount: 3),
            measurement: .observed,
            scope: .response
        )
        let generator = StreamingGenerator(
            deltas: ["Hel", "lo"],
            result: .init(content: "Hello", usage: usage)
        )
        let emissions = try await Self.collect(
            Self.service(generator: generator),
            body: Self.streamBody(includeUsage: true)
        )

        let firstEmission = try #require(emissions.first)
        guard case .streamHead(let status, _) = firstEmission else {
            Issue.record("Expected a streaming response head")
            return
        }
        #expect(status == .ok)
        let lastEmission = try #require(emissions.last)
        guard case .streamEnd = lastEmission else {
            Issue.record("Expected the stream to end")
            return
        }

        let bodies = Self.streamBodies(emissions)
        #expect(bodies.last == "data: [DONE]\n\n")
        let chunks = try bodies.dropLast().map(Self.eventObject)
        #expect(chunks.count == 5)

        let firstChoice = try Self.choice(in: chunks[0])
        let firstDelta = try #require(firstChoice["delta"] as? [String: Any])
        #expect(firstDelta["role"] as? String == "assistant")
        #expect(firstDelta["content"] == nil)
        #expect(firstChoice["finish_reason"] is NSNull)

        #expect(try Self.content(in: chunks[1]) == "Hel")
        #expect(try Self.content(in: chunks[2]) == "lo")

        let finishChoice = try Self.choice(in: chunks[3])
        #expect(finishChoice["finish_reason"] as? String == "stop")
        #expect((finishChoice["delta"] as? [String: Any])?.isEmpty == true)

        #expect((chunks[4]["choices"] as? [Any])?.isEmpty == true)
        let usageJSON = try #require(chunks[4]["usage"] as? [String: Any])
        #expect(usageJSON["prompt_tokens"] as? Int == 11)
        #expect(usageJSON["completion_tokens"] as? Int == 7)
        #expect(usageJSON["total_tokens"] as? Int == 18)
        #expect(usageJSON["afm_measurement"] as? String == "observed")
        let promptDetails = try #require(usageJSON["prompt_tokens_details"] as? [String: Any])
        let completionDetails = try #require(usageJSON["completion_tokens_details"] as? [String: Any])
        #expect(promptDetails["cached_tokens"] as? Int == 2)
        #expect(completionDetails["reasoning_tokens"] as? Int == 3)

        let identifiers = chunks.compactMap { $0["id"] as? String }
        #expect(Set(identifiers).count == 1)
        #expect(identifiers.first?.hasPrefix("chatcmpl-") == true)
        #expect(chunks.allSatisfy { $0["object"] as? String == "chat.completion.chunk" })
        #expect(chunks.allSatisfy { $0["created"] as? Int == 123 })
        #expect(chunks.allSatisfy { $0["model"] as? String == "system" })
    }

    @Test("Streaming omits usage unless requested and preserves length finish reason")
    func streamWithoutUsage() async throws {
        let generator = StreamingGenerator(
            deltas: ["Done"],
            result: .init(content: "Done", finishReason: .length, usage: Self.standardUsage())
        )
        let emissions = try await Self.collect(Self.service(generator: generator), body: Self.streamBody())
        let bodies = Self.streamBodies(emissions)
        let chunks = try bodies.dropLast().map(Self.eventObject)

        #expect(chunks.count == 3)
        #expect(try Self.choice(in: chunks[2])["finish_reason"] as? String == "length")
        #expect(chunks.allSatisfy { !((($0["choices"] as? [Any])?.isEmpty) ?? false) })
        #expect(bodies.last == "data: [DONE]\n\n")
    }

    @Test("Streaming refusals finish with content_filter")
    func streamRefusal() async throws {
        let generator = StreamingGenerator(
            deltas: [],
            result: .init(
                content: nil,
                refusal: "Declined",
                finishReason: .contentFilter,
                usage: Self.standardUsage()
            )
        )
        let emissions = try await Self.collect(Self.service(generator: generator), body: Self.streamBody())
        let chunks = try Self.streamBodies(emissions).dropLast().map(Self.eventObject)

        #expect(chunks.count == 3)
        let refusalChoice = try Self.choice(in: chunks[1])
        let refusalDelta = try #require(refusalChoice["delta"] as? [String: Any])
        #expect(refusalDelta["refusal"] as? String == "Declined")
        #expect(refusalChoice["finish_reason"] is NSNull)
        #expect(try Self.choice(in: chunks[2])["finish_reason"] as? String == "content_filter")
    }

    @Test("Streaming awaits each emitted body before requesting the next delta")
    func streamBackpressure() async throws {
        let probe = BackpressureProbe()
        let blocker = StreamBlocker()
        let recorder = EmissionRecorder()
        let chatService = Self.service(generator: BackpressureGenerator(probe: probe))
        let task = Task {
            try await chatService.writeResponse(for: Self.streamBody()) { emission in
                await recorder.record(emission)
                if case .streamBody(let data) = emission,
                   String(bytes: data, encoding: .utf8)?.contains(#""content":"first""#) == true {
                    await blocker.block()
                }
            }
        }

        await probe.waitUntilFirstAttempt()
        await blocker.waitUntilBlocked()
        for _ in 0..<100 {
            await Task.yield()
        }
        #expect(!(await probe.didAttemptSecond()))

        await blocker.release()
        try await task.value
        #expect(await probe.didAttemptSecond())
        #expect(Self.streamBodies(await recorder.snapshot()).contains { $0.contains(#""content":"second""#) })
    }

    @Test("A streaming timeout cancels generation and stays inside SSE framing")
    func streamTimeout() async throws {
        let probe = CancellationProbe()
        let chatService = Self.service(
            generator: PausingGenerator(probe: probe),
            policy: .init(maximumConcurrentGenerations: 1, timeoutSeconds: 0.01)
        )
        let emissions = try await Self.collect(chatService, body: Self.streamBody())
        await probe.waitUntilCancelled()

        let firstEmission = try #require(emissions.first)
        guard case .streamHead = firstEmission else {
            Issue.record("Expected timeout after the SSE response started")
            return
        }
        let lastEmission = try #require(emissions.last)
        guard case .streamEnd = lastEmission else {
            Issue.record("Expected the timed-out SSE response to end")
            return
        }
        let errorEvent = try #require(Self.streamBodies(emissions).last)
        let error = try Self.eventObject(errorEvent)
        let errorBody = try #require(error["error"] as? [String: Any])
        #expect(errorBody["code"] as? String == "model_timeout")

        let retry = try await Self.collect(chatService, body: Self.streamBody())
        let retryFirstEmission = try #require(retry.first)
        guard case .streamHead = retryFirstEmission else {
            Issue.record("Expected the generation permit to be released after timeout")
            return
        }
    }

    @Test("Streaming validation errors stay as JSON before the SSE response starts")
    func streamValidationError() async throws {
        let generator = StreamingGenerator(deltas: [], result: Self.standardResult())
        let body = Data(
            #"{"messages":[{"role":"user","content":"Hi"}],"stream":true,"tools":[{}]}"#.utf8
        )
        let emissions = try await Self.collect(Self.service(generator: generator), body: body)

        #expect(emissions.count == 1)
        guard case .fixed(let response) = try #require(emissions.first) else {
            Issue.record("Expected a fixed JSON validation response")
            return
        }
        #expect(response.status == .badRequest)
        let json = try #require(JSONSerialization.jsonObject(with: response.body) as? [String: Any])
        let error = try #require(json["error"] as? [String: Any])
        #expect(error["code"] as? String == "missing_field")
        #expect(error["param"] as? String == "tools[0].type")
    }

    @Test("Unsupported forced tool choices fail before the SSE response starts")
    func streamForcedToolChoiceValidation() async throws {
        #if compiler(>=6.4)
        if #available(macOS 27.0, *) { return }
        #endif
        let generator = StreamingGenerator(deltas: [], result: Self.standardResult())
        let body = Data(
            #"""
            {"messages":[{"role":"user","content":"Call ping"}],"stream":true,
             "tools":[{"type":"function","function":{"name":"ping"}}],
             "tool_choice":"required"}
            """#.utf8
        )
        let emissions = try await Self.collect(Self.service(generator: generator), body: body)

        #expect(emissions.count == 1)
        guard case .fixed(let response) = try #require(emissions.first) else {
            Issue.record("Expected a fixed JSON validation response")
            return
        }
        #expect(response.status == .badRequest)
        let json = try #require(JSONSerialization.jsonObject(with: response.body) as? [String: Any])
        let error = try #require(json["error"] as? [String: Any])
        #expect(error["code"] as? String == "unsupported_tool_choice")
        #expect(error["param"] as? String == "tool_choice")
    }
}

extension AFMChatStreamingServiceTests {
    @Test("Streaming tool calls emit canonical deltas, finish, usage, and DONE")
    func streamToolCalls() async throws {
        let generator = StreamingGenerator(
            deltas: ["<start_of_turn>", "model:internal-base64"],
            result: .init(
                content: nil,
                finishReason: .toolCalls,
                usage: .init(
                    input: .init(totalTokenCount: 8),
                    output: .init(totalTokenCount: 5),
                    measurement: .tokenized,
                    scope: .response
                ),
                toolCalls: [
                    .init(id: "call_1", name: "weather", arguments: #"{"city":"Paris"}"#),
                    .init(id: "call_2", name: "weather", arguments: #"{"city":"Tokyo"}"#)
                ]
            )
        )
        let emissions = try await Self.collect(
            Self.service(generator: generator),
            body: Self.toolStreamBody(includeUsage: true)
        )
        let bodies = Self.streamBodies(emissions)
        #expect(bodies.last == "data: [DONE]\n\n")
        let chunks = try bodies.dropLast().map(Self.eventObject)
        #expect(chunks.count == 4)
        #expect(!bodies.contains { $0.contains("start_of_turn") || $0.contains("internal-base64") })

        let callChoice = try Self.choice(in: chunks[1])
        #expect(callChoice["finish_reason"] is NSNull)
        let delta = try #require(callChoice["delta"] as? [String: Any])
        #expect(delta["content"] == nil)
        let calls = try #require(delta["tool_calls"] as? [[String: Any]])
        #expect(calls.map { $0["index"] as? Int } == [0, 1])
        #expect(calls.map { $0["id"] as? String } == ["call_1", "call_2"])
        #expect(calls.allSatisfy { $0["type"] as? String == "function" })
        let secondFunction = try #require(calls[1]["function"] as? [String: Any])
        #expect(secondFunction["name"] as? String == "weather")
        #expect(secondFunction["arguments"] as? String == #"{"city":"Tokyo"}"#)

        #expect(try Self.choice(in: chunks[2])["finish_reason"] as? String == "tool_calls")
        #expect((chunks[3]["choices"] as? [Any])?.isEmpty == true)
        let usage = try #require(chunks[3]["usage"] as? [String: Any])
        #expect(usage["prompt_tokens"] as? Int == 8)
        #expect(usage["completion_tokens"] as? Int == 5)
        #expect(usage["afm_measurement"] as? String == "tokenized")
    }

    @Test("Tool-enabled streams release buffered content after a normal answer")
    func streamToolEnabledContent() async throws {
        let generator = StreamingGenerator(
            deltas: ["No tool", " needed"],
            result: .init(content: "No tool needed", usage: Self.standardUsage())
        )
        let emissions = try await Self.collect(
            Self.service(generator: generator),
            body: Self.toolStreamBody()
        )
        let chunks = try Self.streamBodies(emissions).dropLast().map(Self.eventObject)

        #expect(chunks.count == 4)
        #expect(try Self.content(in: chunks[1]) == "No tool")
        #expect(try Self.content(in: chunks[2]) == " needed")
        #expect(try Self.choice(in: chunks[3])["finish_reason"] as? String == "stop")
    }
}

private extension AFMChatStreamingServiceTests {
    actor StreamingGenerator: AFMChatCompletionGenerating {
        let deltas: [String]
        let result: AFMChatGenerationResult

        init(deltas: [String], result: AFMChatGenerationResult) {
            self.deltas = deltas
            self.result = result
        }

        func generate(_ request: AFMChatGenerationRequest) async throws -> AFMChatGenerationResult {
            result
        }

        func stream(
            _ request: AFMChatGenerationRequest,
            emitting event: @escaping @Sendable (AFMChatGenerationEvent) async throws -> Void
        ) async throws -> AFMChatGenerationResult {
            for delta in deltas {
                try await event(.contentDelta(delta))
            }
            return result
        }
    }

    struct BackpressureGenerator: AFMChatCompletionGenerating {
        let probe: BackpressureProbe

        func generate(_ request: AFMChatGenerationRequest) async throws -> AFMChatGenerationResult {
            AFMChatStreamingServiceTests.standardResult()
        }

        func stream(
            _ request: AFMChatGenerationRequest,
            emitting event: @escaping @Sendable (AFMChatGenerationEvent) async throws -> Void
        ) async throws -> AFMChatGenerationResult {
            await probe.markFirstAttempt()
            try await event(.contentDelta("first"))
            await probe.markSecondAttempt()
            try await event(.contentDelta("second"))
            return AFMChatStreamingServiceTests.standardResult()
        }
    }

    struct PausingGenerator: AFMChatCompletionGenerating {
        let probe: CancellationProbe

        func generate(_ request: AFMChatGenerationRequest) async throws -> AFMChatGenerationResult {
            await probe.markStarted()
            return try await withTaskCancellationHandler {
                try await ContinuousClock().sleep(for: .seconds(30))
                return AFMChatStreamingServiceTests.standardResult()
            } onCancel: {
                Task { await probe.markCancelled() }
            }
        }
    }

    actor EmissionRecorder {
        private var emissions: [AFMHTTPEmission] = []

        func record(_ emission: AFMHTTPEmission) {
            emissions.append(emission)
        }

        func snapshot() -> [AFMHTTPEmission] {
            emissions
        }
    }

    actor BackpressureProbe {
        private var firstAttempted = false
        private var secondAttempted = false

        func markFirstAttempt() { firstAttempted = true }
        func markSecondAttempt() { secondAttempted = true }
        func didAttemptSecond() -> Bool { secondAttempted }

        func waitUntilFirstAttempt() async {
            while !firstAttempted {
                await Task.yield()
            }
        }
    }

    actor StreamBlocker {
        private var isBlocked = false
        private var isReleased = false
        private var continuation: CheckedContinuation<Void, Never>?

        func block() async {
            isBlocked = true
            guard !isReleased else { return }
            await withCheckedContinuation { continuation = $0 }
        }

        func waitUntilBlocked() async {
            while !isBlocked {
                await Task.yield()
            }
        }

        func release() {
            isReleased = true
            continuation?.resume()
            continuation = nil
        }
    }

    actor CancellationProbe {
        private var cancelled = false

        func markStarted() {}
        func markCancelled() { cancelled = true }

        func waitUntilCancelled() async {
            while !cancelled {
                await Task.yield()
            }
        }
    }

    struct TestClock: AFMServerClock {
        func unixTime() -> Int64 { 123 }
    }

    static func service(
        generator: any AFMChatCompletionGenerating,
        policy: AFMServerGenerationPolicy = .init()
    ) -> AFMChatCompletionService {
        AFMChatCompletionService(
            catalog: AFMStaticModelCatalog(models: [.init(id: "system", isAvailable: true)]),
            generator: generator,
            clock: TestClock(),
            policy: policy
        )
    }

    static func collect(
        _ service: AFMChatCompletionService,
        body: Data
    ) async throws -> [AFMHTTPEmission] {
        let recorder = EmissionRecorder()
        try await service.writeResponse(for: body) { emission in
            await recorder.record(emission)
        }
        return await recorder.snapshot()
    }

    static func streamBody(includeUsage: Bool = false) -> Data {
        let options = includeUsage ? #", "stream_options":{"include_usage":true}"# : ""
        return Data(
            #"{"model":"system","messages":[{"role":"user","content":"Hi"}],"stream":true\#(options)}"#.utf8
        )
    }

    static func toolStreamBody(includeUsage: Bool = false) -> Data {
        let options = includeUsage ? #", "stream_options":{"include_usage":true}"# : ""
        let body = """
        {
          "model":"system",
          "messages":[{"role":"user","content":"Call ping"}],
          "stream":true,
          "tools":[{"type":"function","function":{"name":"ping"}}],
          "tool_choice":"auto"\(options)
        }
        """
        return Data(body.utf8)
    }

    static func streamBodies(_ emissions: [AFMHTTPEmission]) -> [String] {
        emissions.compactMap { emission in
            guard case .streamBody(let data) = emission else { return nil }
            return String(bytes: data, encoding: .utf8)
        }
    }

    static func eventObject(_ event: String) throws -> [String: Any] {
        let prefix = "data: "
        #expect(event.hasPrefix(prefix))
        let json = event.dropFirst(prefix.count).dropLast(2)
        return try #require(
            JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]
        )
    }

    static func choice(in chunk: [String: Any]) throws -> [String: Any] {
        let choices = try #require(chunk["choices"] as? [[String: Any]])
        return try #require(choices.first)
    }

    static func content(in chunk: [String: Any]) throws -> String? {
        let delta = try #require(try choice(in: chunk)["delta"] as? [String: Any])
        return delta["content"] as? String
    }

    static func standardUsage() -> ModelTokenUsage {
        .init(
            input: .init(totalTokenCount: 1),
            output: .init(totalTokenCount: 1),
            measurement: .estimated,
            scope: .response
        )
    }

    static func standardResult() -> AFMChatGenerationResult {
        .init(content: "firstsecond", usage: standardUsage())
    }
}
