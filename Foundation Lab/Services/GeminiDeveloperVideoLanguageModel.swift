//
//  GeminiDeveloperVideoLanguageModel.swift
//  FoundationLab
//
//  Created by Codex on 6/15/26.
//

import Foundation
import FoundationModels

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct GeminiDeveloperVideoLanguageModel: LanguageModel {
    typealias Executor = GeminiDeveloperVideoLanguageModelExecutor

    let capabilities = LanguageModelCapabilities(capabilities: [])
    let executorConfiguration: Executor.Configuration

    init(apiKey: String, modelName: String) {
        executorConfiguration = Executor.Configuration(
            apiKey: apiKey,
            modelName: modelName
        )
    }
}

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct GeminiDeveloperVideoLanguageModelExecutor: LanguageModelExecutor {
    typealias Model = GeminiDeveloperVideoLanguageModel

    struct Configuration: Hashable, Sendable {
        let apiKey: String
        let modelName: String
    }

    private let configuration: Configuration
    private let client: GeminiDeveloperAPIClient

    init(configuration: Configuration) throws {
        self.configuration = configuration
        client = GeminiDeveloperAPIClient(
            apiKey: configuration.apiKey,
            modelName: configuration.modelName
        )
    }
}

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension GeminiDeveloperVideoLanguageModelExecutor {
    func respond(
        to request: LanguageModelExecutorGenerationRequest,
        model: GeminiDeveloperVideoLanguageModel,
        streamingInto channel: LanguageModelExecutorGenerationChannel
    ) async throws {
        try validate(request)
        let convertedTranscript = try convert(request.transcript)
        let response = try await client.generateContent(
            contents: convertedTranscript.contents,
            systemInstruction: convertedTranscript.systemInstruction
        )

        guard !response.text.isEmpty else {
            throw GeminiDeveloperAPIError.noTextResponse
        }

        await send(response, for: request.id, into: channel)
    }
}

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension GeminiDeveloperVideoLanguageModelExecutor {
    func validate(_ request: LanguageModelExecutorGenerationRequest) throws {
        guard request.schema == nil else {
            throw LanguageModelError.unsupportedGenerationGuide(
                .init(
                    schemaName: nil,
                    debugDescription: "The Gemini video experiment currently supports text responses only."
                )
            )
        }

        guard request.enabledToolDefinitions.isEmpty else {
            throw LanguageModelError.unsupportedCapability(
                .init(
                    capability: .toolCalling,
                    debugDescription: "Tool calling is outside this focused video-input experiment."
                )
            )
        }
    }

    func convert(_ transcript: Transcript) throws -> ConvertedTranscript {
        var systemParts = [GeminiDeveloperAPIClient.Part]()
        var contents = [GeminiDeveloperAPIClient.Content]()

        for entry in transcript {
            switch entry {
            case let .instructions(instructions):
                systemParts.append(contentsOf: try geminiParts(
                    from: instructions.segments,
                    entry: entry,
                    allowsCustomMedia: false
                ))

            case let .prompt(prompt):
                let parts = try geminiParts(
                    from: prompt.segments,
                    entry: entry,
                    allowsCustomMedia: true
                )
                appendContent(role: "user", parts: parts, to: &contents)

            case let .response(response):
                let parts = try geminiParts(
                    from: response.segments,
                    entry: entry,
                    allowsCustomMedia: true
                )
                appendContent(role: "model", parts: parts, to: &contents)

            case .reasoning:
                continue

            case .toolCalls, .toolOutput:
                throw LanguageModelError.unsupportedCapability(
                    .init(
                        capability: .toolCalling,
                        debugDescription: "Tool transcript entries are not supported by this video wrapper."
                    )
                )

            @unknown default:
                throw unsupportedTranscriptError(
                    entry,
                    detail: "The transcript contains an unknown entry type."
                )
            }
        }

        guard !contents.isEmpty else {
            throw GeminiDeveloperAPIError.emptyPrompt
        }

        return ConvertedTranscript(
            contents: contents,
            systemInstruction: systemParts.isEmpty
                ? nil
                : GeminiDeveloperAPIClient.Content(role: nil, parts: systemParts)
        )
    }

    func appendContent(
        role: String,
        parts: [GeminiDeveloperAPIClient.Part],
        to contents: inout [GeminiDeveloperAPIClient.Content]
    ) {
        guard !parts.isEmpty else {
            return
        }
        contents.append(.init(role: role, parts: parts))
    }

    func send(
        _ response: GeminiDeveloperAPIClient.Response,
        for requestID: UUID,
        into channel: LanguageModelExecutorGenerationChannel
    ) async {
        let text = response.text
        let responseEntryID = requestID.uuidString
        await channel.send(
            .response(
                entryID: responseEntryID,
                action: .appendText(text, tokenCount: response.usageMetadata?.candidatesTokenCount ?? 0)
            )
        )
        await channel.send(
            .response(
                entryID: responseEntryID,
                action: .updateMetadata([
                    "provider": "Gemini Developer API",
                    "model": response.modelVersion ?? configuration.modelName
                ])
            )
        )

        if let usage = response.usageMetadata {
            await channel.send(
                .response(
                    entryID: responseEntryID,
                    action: .updateUsage(
                        input: .init(
                            totalTokenCount: usage.promptTokenCount,
                            cachedTokenCount: usage.cachedContentTokenCount ?? 0
                        ),
                        output: .init(
                            totalTokenCount: usage.candidatesTokenCount,
                            reasoningTokenCount: usage.thoughtsTokenCount ?? 0
                        )
                    )
                )
            )
        }
    }

    struct ConvertedTranscript {
        let contents: [GeminiDeveloperAPIClient.Content]
        let systemInstruction: GeminiDeveloperAPIClient.Content?
    }

    func geminiParts(
        from segments: [Transcript.Segment],
        entry: Transcript.Entry,
        allowsCustomMedia: Bool
    ) throws -> [GeminiDeveloperAPIClient.Part] {
        var parts = [GeminiDeveloperAPIClient.Part]()

        for segment in segments {
            switch segment {
            case let .text(text):
                parts.append(.text(text.content))

            case let .structure(structure):
                parts.append(.text(structure.content.jsonString))

            case let .custom(customSegment):
                guard allowsCustomMedia else {
                    throw unsupportedTranscriptError(
                        entry,
                        detail: "Gemini system instructions support text only."
                    )
                }

                if let video = customSegment as? VideoSegment {
                    parts.append(.inlineData(
                        data: video.content.data,
                        mimeType: video.content.mimeType
                    ))
                } else {
                    throw unsupportedTranscriptError(
                        entry,
                        detail: "Only VideoSegment custom segments are supported."
                    )
                }

            case .attachment:
                throw unsupportedTranscriptError(
                    entry,
                    detail: "Use VideoSegment for video input in this experiment."
                )

            @unknown default:
                throw unsupportedTranscriptError(
                    entry,
                    detail: "The transcript contains an unknown segment type."
                )
            }
        }

        return parts
    }

    func unsupportedTranscriptError(
        _ entry: Transcript.Entry,
        detail: String
    ) -> LanguageModelError {
        .unsupportedTranscriptContent(
            .init(
                unsupportedContent: [entry],
                debugDescription: detail
            )
        )
    }
}

struct GeminiDeveloperAPIClient: Sendable {
    struct Content: Codable, Sendable {
        let role: String?
        let parts: [Part]
    }

    struct Part: Codable, Sendable {
        let text: String?
        let inlineData: InlineData?

        static func text(_ text: String) -> Part {
            Part(text: text, inlineData: nil)
        }

        static func inlineData(data: Data, mimeType: String) -> Part {
            Part(
                text: nil,
                inlineData: .init(
                    mimeType: mimeType,
                    data: data.base64EncodedString()
                )
            )
        }

        enum CodingKeys: String, CodingKey {
            case text
            case inlineData = "inline_data"
        }
    }

    struct InlineData: Codable, Sendable {
        let mimeType: String
        let data: String

        enum CodingKeys: String, CodingKey {
            case mimeType = "mime_type"
            case data
        }
    }

    struct Response: Decodable, Sendable {
        struct Candidate: Decodable, Sendable {
            let content: Content
        }

        struct UsageMetadata: Decodable, Sendable {
            let promptTokenCount: Int
            let cachedContentTokenCount: Int?
            let candidatesTokenCount: Int
            let thoughtsTokenCount: Int?
            let totalTokenCount: Int
        }

        let candidates: [Candidate]
        let usageMetadata: UsageMetadata?
        let modelVersion: String?

        var text: String {
            candidates.first?.content.parts.compactMap(\.text).joined() ?? ""
        }
    }

    private struct RequestBody: Encodable {
        let contents: [Content]
        let systemInstruction: Content?
    }

    private struct ErrorResponse: Decodable {
        struct Details: Decodable {
            let message: String
        }

        let error: Details
    }

    let apiKey: String
    let modelName: String
    var urlSession = URLSession.shared

    func generateContent(
        contents: [Content],
        systemInstruction: Content?
    ) async throws -> Response {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GeminiDeveloperAPIError.apiKeyMissing
        }

        guard let encodedModelName = modelName.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        ),
            let url = URL(
                string: "https://generativelanguage.googleapis.com/v1beta/models/\(encodedModelName):generateContent"
            ) else {
            throw GeminiDeveloperAPIError.invalidModelName(modelName)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONEncoder().encode(
            RequestBody(
                contents: contents,
                systemInstruction: systemInstruction
            )
        )

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiDeveloperAPIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder().decode(ErrorResponse.self, from: data))
                .map(\.error.message)
                ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw GeminiDeveloperAPIError.requestFailed(
                statusCode: httpResponse.statusCode,
                message: message
            )
        }

        return try JSONDecoder().decode(Response.self, from: data)
    }
}

enum GeminiDeveloperAPIError: LocalizedError, Sendable {
    case apiKeyMissing
    case emptyPrompt
    case invalidModelName(String)
    case invalidResponse
    case noTextResponse
    case requestFailed(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "Enter a Gemini API key or launch with GEMINI_API_KEY."
        case .emptyPrompt:
            return "The transcript did not contain a prompt Gemini can send."
        case let .invalidModelName(modelName):
            return "The Gemini model name is invalid: \(modelName)."
        case .invalidResponse:
            return "Gemini returned an invalid HTTP response."
        case .noTextResponse:
            return "Gemini completed without returning text."
        case let .requestFailed(statusCode, message):
            return "Gemini request failed with HTTP \(statusCode): \(message)"
        }
    }
}
