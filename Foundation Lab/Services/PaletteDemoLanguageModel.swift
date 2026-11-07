//
//  PaletteDemoLanguageModel.swift
//  FoundationLab
//

import Foundation
import FoundationModels
import UniformTypeIdentifiers

@available(iOS 27.2, macOS 27.2, visionOS 27.2, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
nonisolated struct PaletteDemoLanguageModel: LanguageModel {
    typealias Executor = PaletteDemoLanguageModelExecutor

    let capabilities = LanguageModelCapabilities([])
    let executorConfiguration = Executor.Configuration()

    func supportsDataAttachmentType(_ type: UTType) async throws -> Bool {
        type == .foundationLabColorSwatch
    }

    func supportsDataEntryType(_ type: UTType) async throws -> Bool {
        type == .foundationLabColorPalette
    }
}

@available(iOS 27.2, macOS 27.2, visionOS 27.2, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
nonisolated struct PaletteDemoLanguageModelExecutor: LanguageModelExecutor {
    typealias Model = PaletteDemoLanguageModel

    struct Configuration: Hashable, Sendable {}

    init(configuration: Configuration) throws {}

    func respond(
        to request: LanguageModelExecutorGenerationRequest,
        model: PaletteDemoLanguageModel,
        streamingInto channel: LanguageModelExecutorGenerationChannel
    ) async throws {
        guard let swatch = try latestSwatch(in: request.transcript) else {
            throw LanguageModelError.unsupportedTranscriptContent(
                .init(
                    unsupportedContent: Array(request.transcript),
                    debugDescription: "The prompt has no color swatch attachment."
                )
            )
        }

        let palette = ColorPalette(swatch: swatch.complement).transcriptRepresentation
        await channel.send(
            .data(action: .update(
                contentType: palette.contentType,
                content: palette.content,
                metadata: palette.metadata
            ))
        )
        await channel.send(
            .response(action: .appendText(
                "Inverted \(swatch.colors.count) colors from \(swatch.name).",
                tokenCount: 0
            ))
        )
    }

    private func latestSwatch(in transcript: Transcript) throws -> ColorSwatch? {
        for entry in transcript.reversed() {
            guard case let .prompt(prompt) = entry else { continue }
            for segment in prompt.segments {
                if case let .attachment(attachment) = segment,
                   case let .data(data) = attachment.content {
                    return try ColorSwatch(data)
                }
            }
        }
        return nil
    }
}
