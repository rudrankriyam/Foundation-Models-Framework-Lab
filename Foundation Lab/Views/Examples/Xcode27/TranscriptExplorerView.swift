//
//  TranscriptExplorerView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct TranscriptExplorerView: View {
    @State private var selectedSegment = TranscriptSegmentExample.reasoning

    var body: some View {
        ReferenceExampleView(
            title: String(localized: "Transcript Explorer"),
            description: String(localized: "Inspect reasoning, attachment, and custom transcript cases"),
            codeExample: codeExample,
            referenceNote: String(
                localized: "Choose a segment to inspect its API case and code path. This page does not create a session or transcript."
            )
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

                Xcode27Section(String(localized: "Why this matters")) {
                    VStack(alignment: .leading, spacing: 0) {
                        Xcode27InfoRow(
                            title: String(localized: "Switches need new cases"),
                            detail: String(localized: """
                            Code that walked transcript entries or segments in Xcode 26 should explicitly handle the new Xcode 27 cases.
                            """),
                            systemImage: "switch.2"
                        )
                        .padding(.vertical, Spacing.small)

                        Divider()

                        Xcode27InfoRow(
                            title: String(localized: "Debug views get richer"),
                            detail: String(localized: """
                            A transcript debugger can now show reasoning, image attachments, generated references, and app-defined \
                            custom content.
                            """),
                            systemImage: "ladybug"
                        )
                        .padding(.vertical, Spacing.small)
                    }
                }
            }
        }
    }

    private var codeExample: String {
        """
        func render(_ entry: Transcript.Entry) {
            switch entry {
            case .instructions(let instructions):
                render(instructions.segments)
            case .prompt(let prompt):
                render(prompt.segments)
            case .toolCalls(let calls):
                for call in calls {
                    render(call.toolName)
                    render(String(describing: call.arguments))
                }
            case .toolOutput(let output):
                render(output.segments)
            case .response(let response):
                render(response.segments)
            case .reasoning(let reasoning):
                render(reasoning.segments)
            @unknown default:
                render("Unknown entry")
            }
        }

        func render(_ segments: [Transcript.Segment]) {
            for segment in segments {
                switch segment {
                case .text(let text):
                    render(text.content)
                case .structure(let structured):
                    render(structured.schemaName)
                case .attachment(let attachment):
                    render(attachment.label ?? "Attachment")
                case .custom(let custom):
                    render(custom.description)
                @unknown default:
                    render("Unknown segment")
                }
            }
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
            return String(localized: "Reasoning")
        case .attachment:
            return String(localized: "Attachment")
        case .custom:
            return String(localized: "Custom")
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
            return String(
                localized: """
                Xcode 27 adds transcript reasoning entries so developer tools can separate reasoning from ordinary assistant text.
                """
            )
        case .attachment:
            return String(localized: "Attachment segments let image inputs and generated image references travel through the transcript.")
        case .custom:
            return String(localized: "Custom segments give framework and app integrations room to preserve extra typed transcript content.")
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
