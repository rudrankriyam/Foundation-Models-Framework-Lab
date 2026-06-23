//
//  SessionTranscriptSnapshot.swift
//  FoundationLab
//

import Foundation
import FoundationLabCore
import CoreGraphics

#if compiler(>=6.4)
import FoundationModels
#endif

struct SessionTranscriptSnapshot: Equatable, Sendable {
    struct Entry: Equatable, Identifiable, Sendable {
        enum Kind: String, Equatable, Sendable {
            case instructions
            case prompt
            case reasoning
            case toolCalls
            case toolOutput
            case response
            case unknown

            var title: String {
                switch self {
                case .instructions:
                    String(localized: "Instructions")
                case .prompt:
                    String(localized: "Prompt")
                case .reasoning:
                    String(localized: "Reasoning")
                case .toolCalls:
                    String(localized: "Tool Calls")
                case .toolOutput:
                    String(localized: "Tool Output")
                case .response:
                    String(localized: "Response")
                case .unknown:
                    String(localized: "Unknown Entry")
                }
            }

            var systemImage: String {
                switch self {
                case .instructions:
                    "text.badge.checkmark"
                case .prompt:
                    "person.crop.circle"
                case .reasoning:
                    "brain"
                case .toolCalls:
                    "hammer"
                case .toolOutput:
                    "wrench.and.screwdriver"
                case .response:
                    "sparkles"
                case .unknown:
                    "questionmark.circle"
                }
            }
        }

        struct Field: Equatable, Identifiable, Sendable {
            let name: String
            let value: String

            var id: String { name }
        }

        let id: String
        let frameworkID: String
        let ordinal: Int
        let kind: Kind
        let summary: String
        let segments: [Segment]
        let fields: [Field]
    }

    struct Segment: Equatable, Identifiable, Sendable {
        enum Kind: String, Equatable, Sendable {
            case text
            case structure
            case attachment
            case custom
            case toolCall
            case unknown

            var title: String {
                switch self {
                case .text:
                    String(localized: "Text")
                case .structure:
                    String(localized: "Structured Content")
                case .attachment:
                    String(localized: "Attachment")
                case .custom:
                    String(localized: "Custom Content")
                case .toolCall:
                    String(localized: "Tool Call")
                case .unknown:
                    String(localized: "Unknown Segment")
                }
            }
        }

        let id: String
        let kind: Kind
        let label: String
        let content: String
    }

    struct ToolEvent: Equatable, Identifiable, Sendable {
        enum Kind: Equatable, Sendable {
            case call
            case output
        }

        let id: String
        let frameworkID: String
        let kind: Kind
        let toolName: String
        let detail: String
    }

    let entries: [Entry]
    let toolCalls: [FoundationLabToolTrajectoryEvaluation.Call]
    let toolEvents: [ToolEvent]
}

#if compiler(>=6.4)
@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SessionTranscriptSnapshot {
    private struct Capture {
        let entry: Entry
        var calls: [FoundationLabToolTrajectoryEvaluation.Call] = []
        var events: [ToolEvent] = []
    }

    init(transcript: Transcript) {
        let captures = transcript.enumerated().map { index, transcriptEntry in
            Self.capture(transcriptEntry, ordinal: index + 1)
        }

        self.init(
            entries: captures.map(\.entry),
            toolCalls: captures.flatMap(\.calls),
            toolEvents: captures.flatMap(\.events)
        )
    }

    private static func capture(_ transcriptEntry: Transcript.Entry, ordinal: Int) -> Capture {
        switch transcriptEntry {
        case .instructions(let instructions):
            capture(instructions, ordinal: ordinal)
        case .prompt(let prompt):
            capture(prompt, ordinal: ordinal)
        case .reasoning(let reasoning):
            capture(reasoning, ordinal: ordinal)
        case .toolCalls(let calls):
            capture(calls, ordinal: ordinal)
        case .toolOutput(let output):
            capture(output, ordinal: ordinal)
        case .response(let response):
            capture(response, ordinal: ordinal)
        @unknown default:
            Capture(
                entry: Entry(
                    id: "\(ordinal)-unknown",
                    frameworkID: String(localized: "Unavailable"),
                    ordinal: ordinal,
                    kind: .unknown,
                    summary: transcriptEntry.description,
                    segments: [],
                    fields: []
                )
            )
        }
    }

    private static func capture(_ instructions: Transcript.Instructions, ordinal: Int) -> Capture {
        let segments = segments(from: instructions.segments, entryOrdinal: ordinal)
        let toolFields = instructions.toolDefinitions.enumerated().map { toolIndex, definition in
            Entry.Field(
                name: String(localized: "Tool \(toolIndex + 1)"),
                value: "\(definition.name): \(definition.description)"
            )
        }
        return Capture(
            entry: entry(
                id: instructions.id,
                ordinal: ordinal,
                kind: .instructions,
                segments: segments,
                fields: toolFields
            )
        )
    }

    private static func capture(_ prompt: Transcript.Prompt, ordinal: Int) -> Capture {
        let segments = segments(from: prompt.segments, entryOrdinal: ordinal)
        return Capture(
            entry: entry(
                id: prompt.id,
                ordinal: ordinal,
                kind: .prompt,
                segments: segments,
                fields: metadataFields(prompt.metadata)
            )
        )
    }

    private static func capture(_ reasoning: Transcript.Reasoning, ordinal: Int) -> Capture {
        let segments = segments(from: reasoning.segments, entryOrdinal: ordinal)
        var fields = metadataFields(reasoning.metadata)
        if let signature = reasoning.signature {
            fields.append(
                Entry.Field(
                    name: String(localized: "Signature"),
                    value: String(localized: "\(signature.count) bytes")
                )
            )
        }
        return Capture(
            entry: entry(
                id: reasoning.id,
                ordinal: ordinal,
                kind: .reasoning,
                segments: segments,
                fields: fields
            )
        )
    }

    private static func capture(_ calls: Transcript.ToolCalls, ordinal: Int) -> Capture {
        var observedCalls: [FoundationLabToolTrajectoryEvaluation.Call] = []
        var events: [ToolEvent] = []
        let callSegments = calls.enumerated().map { callIndex, call in
            let arguments = prettyJSON(call.arguments.jsonString)
            observedCalls.append(
                FoundationLabToolTrajectoryEvaluation.Call(
                    id: call.id,
                    name: call.toolName,
                    arguments: call.arguments.jsonString
                )
            )
            events.append(
                ToolEvent(
                    id: "call-\(ordinal)-\(callIndex)-\(call.id)",
                    frameworkID: call.id,
                    kind: .call,
                    toolName: call.toolName,
                    detail: arguments
                )
            )
            return Segment(
                id: "\(ordinal)-call-\(callIndex)-\(call.id)",
                kind: .toolCall,
                label: call.toolName,
                content: arguments
            )
        }
        return Capture(
            entry: entry(
                id: calls.id,
                ordinal: ordinal,
                kind: .toolCalls,
                segments: callSegments,
                fields: [Entry.Field(name: String(localized: "Observed calls"), value: calls.count.formatted())]
            ),
            calls: observedCalls,
            events: events
        )
    }

    private static func capture(_ output: Transcript.ToolOutput, ordinal: Int) -> Capture {
        let segments = segments(from: output.segments, entryOrdinal: ordinal)
        return Capture(
            entry: entry(
                id: output.id,
                ordinal: ordinal,
                kind: .toolOutput,
                segments: segments,
                fields: [Entry.Field(name: String(localized: "Tool"), value: output.toolName)]
            ),
            events: [
                ToolEvent(
                    id: "output-\(ordinal)-\(output.id)",
                    frameworkID: output.id,
                    kind: .output,
                    toolName: output.toolName,
                    detail: combinedContent(segments)
                )
            ]
        )
    }

    private static func capture(_ response: Transcript.Response, ordinal: Int) -> Capture {
        let segments = segments(from: response.segments, entryOrdinal: ordinal)
        return Capture(
            entry: entry(
                id: response.id,
                ordinal: ordinal,
                kind: .response,
                segments: segments,
                fields: metadataFields(response.metadata)
            )
        )
    }

    private static func entry(
        id: String,
        ordinal: Int,
        kind: Entry.Kind,
        segments: [Segment],
        fields: [Entry.Field]
    ) -> Entry {
        Entry(
            id: "\(ordinal)-\(id)",
            frameworkID: id,
            ordinal: ordinal,
            kind: kind,
            summary: summary(for: kind, segments: segments),
            segments: segments,
            fields: fields
        )
    }

    private static func segments(
        from transcriptSegments: [Transcript.Segment],
        entryOrdinal: Int
    ) -> [Segment] {
        transcriptSegments.enumerated().map { segmentIndex, segment in
            let id = "\(entryOrdinal)-\(segmentIndex)-\(segment.id)"
            switch segment {
            case .text(let text):
                return Segment(id: id, kind: .text, label: String(localized: "Text"), content: text.content)
            case .structure(let structure):
                return Segment(
                    id: id,
                    kind: .structure,
                    label: structure.schemaName,
                    content: prettyJSON(structure.content.jsonString)
                )
            case .attachment(let attachment):
                return Segment(
                    id: id,
                    kind: .attachment,
                    label: attachment.label ?? String(localized: "Image attachment"),
                    content: attachmentDescription(attachment.content)
                )
            case .custom(let custom):
                return Segment(
                    id: id,
                    kind: .custom,
                    label: String(describing: type(of: custom)),
                    content: custom.description
                )
            @unknown default:
                return Segment(
                    id: id,
                    kind: .unknown,
                    label: String(localized: "Unknown segment"),
                    content: segment.description
                )
            }
        }
    }

    private static func attachmentDescription(_ attachment: Transcript.Attachment) -> String {
        switch attachment {
        case .image(let image):
            if let url = image.url {
                return url.lastPathComponent
            }
            return String(localized: "\(image.cgImage.width) × \(image.cgImage.height) pixels")
        @unknown default:
            return String(localized: "A newer attachment type was emitted.")
        }
    }

    private static func metadataFields(
        _ metadata: [String: any Codable & Sendable & Equatable]
    ) -> [Entry.Field] {
        metadata.keys.sorted().compactMap { key in
            guard let value = metadata[key] else { return nil }
            return Entry.Field(name: key, value: String(describing: value))
        }
    }

    private static func summary(for kind: Entry.Kind, segments: [Segment]) -> String {
        guard let first = segments.first else {
            switch kind {
            case .reasoning:
                return String(localized: "The framework emitted a reasoning entry without displayable segments.")
            case .toolCalls:
                return String(localized: "The framework emitted an empty tool-call group.")
            default:
                return String(localized: "No displayable segments were emitted.")
            }
        }

        let flattened = first.content.replacing("\n", with: " ")
        if flattened.count <= 120 {
            return flattened
        }
        return String(flattened.prefix(117)) + "…"
    }

    private static func combinedContent(_ segments: [Segment]) -> String {
        let content = segments.map(\.content).filter { !$0.isEmpty }.joined(separator: "\n\n")
        return content.isEmpty ? String(localized: "No displayable output segments were emitted.") : content
    }

    private static func prettyJSON(_ source: String) -> String {
        guard let data = source.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              JSONSerialization.isValidJSONObject(object),
              let prettyData = try? JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
              ),
              let result = String(data: prettyData, encoding: .utf8) else {
            return source
        }

        return result
    }
}
#endif
