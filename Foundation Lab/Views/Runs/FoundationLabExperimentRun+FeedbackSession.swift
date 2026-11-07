//
//  FoundationLabExperimentRun+FeedbackSession.swift
//  Foundation Lab
//

import Foundation
import FoundationLabCore
import FoundationModels
import FoundationModelsKit

extension FoundationLabExperimentRun {
    func makeFeedbackSession() -> LanguageModelSession {
        let transcript = feedbackTranscript
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *),
           configuration.modelRuntime == .privateCloudCompute {
            return LanguageModelSession(model: PrivateCloudComputeLanguageModel(), transcript: transcript)
        }
        return LanguageModelSession(transcript: transcript)
    }

    private var feedbackTranscript: Transcript {
        var entries: [Transcript.Entry] = []
        var pendingToolCalls: [Transcript.ToolCall] = []
        var unansweredCallIDs: [String: [String]] = [:]

        if !events.contains(where: { $0.role == .system }), !configuration.instructions.isEmpty {
            entries.append(Self.instructionsEntry(configuration.instructions))
        }

        for event in events {
            if event.kind != .toolCall, !pendingToolCalls.isEmpty {
                entries.append(.toolCalls(Transcript.ToolCalls(pendingToolCalls)))
                pendingToolCalls.removeAll()
            }

            switch event.kind {
            case .toolCall:
                guard let toolName = event.toolName,
                      let arguments = try? GeneratedContent(json: event.text) else { continue }
                let callID = UUID().uuidString
                pendingToolCalls.append(Transcript.ToolCall(id: callID, toolName: toolName, arguments: arguments))
                unansweredCallIDs[toolName, default: []].append(callID)
            case .toolResult:
                guard let toolName = event.toolName,
                      let callID = unansweredCallIDs[toolName]?.first else { continue }
                unansweredCallIDs[toolName]?.removeFirst()
                entries.append(.toolOutput(Transcript.ToolOutput(
                    id: callID,
                    toolName: toolName,
                    segments: Self.segments(event.text)
                )))
            case .message:
                if let entry = Self.messageEntry(for: event) {
                    entries.append(entry)
                }
            case .reasoning:
                if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
                    entries.append(.reasoning(Transcript.Reasoning(segments: Self.segments(event.text))))
                }
            }
        }

        if !pendingToolCalls.isEmpty {
            entries.append(.toolCalls(Transcript.ToolCalls(pendingToolCalls)))
        }
        return Transcript(entries: entries)
    }

    private static func messageEntry(for event: FoundationLabExperimentEvent) -> Transcript.Entry? {
        switch event.role {
        case .system:
            instructionsEntry(event.text)
        case .user:
            .prompt(Transcript.Prompt(segments: segments(event.text)))
        case .assistant:
            .response(Transcript.Response(assetIDs: [], segments: segments(event.text)))
        case .tool:
            nil
        }
    }

    private static func instructionsEntry(_ text: String) -> Transcript.Entry {
        .instructions(Transcript.Instructions(segments: segments(text), toolDefinitions: []))
    }

    private static func segments(_ text: String) -> [Transcript.Segment] {
        [.text(Transcript.TextSegment(content: text))]
    }
}
