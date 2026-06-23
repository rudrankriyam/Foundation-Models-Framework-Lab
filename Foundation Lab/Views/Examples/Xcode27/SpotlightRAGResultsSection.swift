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
        Xcode27Section(String(localized: "Retrieval Trajectory")) {
            if model.events.isEmpty {
                ContentUnavailableView {
                    Label("No Search Events", systemImage: "point.3.connected.trianglepath.dotted")
                } description: {
                    Text("Run a grounded question to watch the model build and execute Spotlight search stages.")
                }
            } else {
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

        Xcode27Section(String(localized: "Retrieved Evidence")) {
            if model.matchedDocuments.isEmpty {
                ContentUnavailableView {
                    Label("No Evidence Retrieved", systemImage: "doc.text.magnifyingglass")
                } description: {
                    Text("Matched items appear here separately from the generated answer.")
                }
            } else {
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

        Xcode27Section(String(localized: "Grounded Answer")) {
            if model.answer.isEmpty {
                ContentUnavailableView {
                    Label("No Answer Yet", systemImage: "text.bubble")
                } description: {
                    Text("The final model response appears here after retrieval completes.")
                }
            } else {
                Text(model.answer)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
    }
}
#endif
