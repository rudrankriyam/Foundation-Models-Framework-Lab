//
//  ImageInputResultSection.swift
//  FoundationLab
//

#if compiler(>=6.4)
import SwiftUI

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
struct ImageInputResultSection: View {
    let result: ImageInputRunResult
    @State private var showsDetails = false

    var body: some View {
        Xcode27Section(String(localized: "Model Response")) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text(result.response)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: hasAttachmentEvidence ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(hasAttachmentEvidence ? Color.secondary : Color.orange)

                    Text(summary)
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilitySummary)

                DisclosureGroup("Run Evidence", isExpanded: $showsDetails) {
                    VStack(spacing: Spacing.small) {
                        LabeledContent("Image", value: result.imageName)
                        LabeledContent("Prompt", value: result.prompt)
                        LabeledContent("Input tokens", value: result.inputTokens.formatted())
                        LabeledContent("Cached input tokens", value: result.cachedInputTokens.formatted())
                        LabeledContent("Output tokens", value: result.outputTokens.formatted())
                        LabeledContent("Reasoning tokens", value: result.reasoningTokens.formatted())
                        LabeledContent("Total tokens", value: result.totalTokens.formatted())
                        LabeledContent("Transcript entries", value: result.transcriptEntryCount.formatted())
                        LabeledContent("Attachment segments", value: result.attachmentSegmentCount.formatted())
                        LabeledContent("Elapsed time", value: durationLabel)
                    }
                    .font(.callout)
                    .padding(.top, Spacing.small)
                }
            }
        }
    }

    private var hasAttachmentEvidence: Bool {
        result.attachmentSegmentCount > 0
    }

    private var summary: String {
        if hasAttachmentEvidence {
            String(
                localized: """
                \(result.totalTokens) tokens · \(result.attachmentSegmentCount) attachment segments · \(durationLabel)
                """
            )
        } else {
            String(localized: "Attachment evidence missing · 0 attachment segments · \(result.totalTokens) tokens")
        }
    }

    private var accessibilitySummary: String {
        if hasAttachmentEvidence {
            String(
                localized: """
                Run completed with \(result.totalTokens) total tokens, \(result.attachmentSegmentCount) attachment segments, \
                and \(result.transcriptEntryCount) transcript entries, in \(durationLabel)
                """
            )
        } else {
            String(
                localized: """
                Warning: run completed with no attachment segment in the transcript. Total tokens: \(result.totalTokens).
                """
            )
        }
    }

    private var durationLabel: String {
        let seconds = Double(result.duration.components.seconds)
            + (Double(result.duration.components.attoseconds) / 1_000_000_000_000_000_000)
        return String(localized: "\(seconds.formatted(.number.precision(.fractionLength(2)))) s")
    }
}
#endif
