//
//  SpotlightRAGResultsSection.swift
//  FoundationLab
//

#if compiler(>=6.4) && arch(arm64)
import SwiftUI

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct SpotlightRAGResultsSection: View {
    let model: SpotlightRAGViewModel

    var body: some View {
        if model.isRunning && model.events.isEmpty {
            ProgressView("Searching Spotlight…")
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        if !model.events.isEmpty {
            Xcode27Section(String(localized: "Retrieval Trajectory")) {
                VStack(spacing: 0) {
                    ForEach(model.events) { event in
                        Label {
                            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                                HStack {
                                    Text("Query \(event.queryNumber): \(event.label)")
                                        .bold()
                                    Spacer()
                                    Text(event.isComplete ? "Complete" : "Partial")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text(event.detail)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }
                        } icon: {
                            Image(systemName: event.kind.systemImage)
                                .foregroundStyle(event.isComplete ? .green : .blue)
                        }
                        .padding(.vertical, Spacing.small)

                        if event.id != model.events.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }

        if !model.matchedDocuments.isEmpty {
            Xcode27Section(String(localized: "Retrieved Evidence")) {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    ForEach(model.matchedDocuments) { document in
                        VStack(alignment: .leading, spacing: Spacing.xSmall) {
                            Text(document.title)
                                .bold()
                            Text(document.body)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                            Text(document.modifiedAt, format: .dateTime.day().month().year())
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }

                        if document.id != model.matchedDocuments.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }

        if !model.answer.isEmpty {
            Xcode27Section(String(localized: "Grounded Answer")) {
                Text(formattedAnswer)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
    }

    private var formattedAnswer: AttributedString {
        (try? AttributedString(markdown: model.answer)) ?? AttributedString(model.answer)
    }
}
#endif
