//
//  TranscriptExplorerView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct TranscriptExplorerView: View {
    @State private var currentPrompt = "Browse the Xcode 27 transcript segment types."
    @State private var selectedSegment = TranscriptSegmentExample.reasoning

    var body: some View {
        ExampleViewBase(
            title: "Transcript Explorer",
            description: "Browse new reasoning, attachment, and custom segment cases",
            defaultPrompt: "Browse the Xcode 27 transcript segment types.",
            currentPrompt: $currentPrompt,
            codeExample: codeExample,
            onRun: run,
            onReset: reset
        ) {
            VStack(spacing: Spacing.medium) {
                Picker("Segment", selection: $selectedSegment) {
                    ForEach(TranscriptSegmentExample.allCases) { segment in
                        Label(segment.title, systemImage: segment.icon)
                            .tag(segment)
                    }
                }
                .pickerStyle(.segmented)

                Xcode27Section(selectedSegment.title) {
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Text(selectedSegment.detail)
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        Text(selectedSegment.sample)
                            .font(.body.monospaced())
                            .textSelection(.enabled)
                            .padding(.vertical, Spacing.small)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Xcode27Section("Why this matters") {
                    VStack(alignment: .leading, spacing: 0) {
                        Xcode27InfoRow(
                            title: "Switches need new cases",
                            detail: """
                            Code that walked transcript entries or segments in Xcode 26 should explicitly handle the new Xcode 27 cases.
                            """,
                            systemImage: "switch.2"
                        )
                        .padding(.vertical, Spacing.small)

                        Divider()

                        Xcode27InfoRow(
                            title: "Debug views get richer",
                            detail: """
                            A transcript debugger can now show reasoning, image attachments, generated references, and app-defined \
                            custom content.
                            """,
                            systemImage: "ladybug"
                        )
                        .padding(.vertical, Spacing.small)
                    }
                }
            }
        }
    }

    private func run() {}

    private func reset() {
        currentPrompt = ""
    }

    private var codeExample: String {
        """
        switch entry {
        case .reasoning(let reasoning):
            renderReasoning(reasoning)
        case .segment(let segment):
            switch segment {
            case .text(let text):
                render(text.content)
            case .structure(let structured):
                render(structured.schemaName)
            case .attachment(let attachment):
                render(attachment.label)
            case .custom(let custom):
                render(custom.description)
            @unknown default:
                render("Unknown segment")
            }
        @unknown default:
            render("Unknown entry")
        }
        """
    }
}

private enum TranscriptSegmentExample: String, CaseIterable, Identifiable {
    case reasoning
    case attachment
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reasoning:
            return "Reasoning"
        case .attachment:
            return "Attachment"
        case .custom:
            return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .reasoning:
            return "brain"
        case .attachment:
            return "paperclip"
        case .custom:
            return "puzzlepiece.extension"
        }
    }

    var detail: String {
        switch self {
        case .reasoning:
            return "Xcode 27 adds transcript reasoning entries so developer tools can separate reasoning from ordinary assistant text."
        case .attachment:
            return "Attachment segments let image inputs and generated image references travel through the transcript."
        case .custom:
            return "Custom segments give framework and app integrations room to preserve extra typed transcript content."
        }
    }

    var sample: String {
        switch self {
        case .reasoning:
            return "Transcript.Entry.reasoning(...)"
        case .attachment:
            return "Transcript.Segment.attachment(...)"
        case .custom:
            return "Transcript.Segment.custom(...)"
        }
    }
}

#Preview {
    NavigationStack {
        TranscriptExplorerView()
    }
}
