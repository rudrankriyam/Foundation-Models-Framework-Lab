//
//  SpotlightRAGIndexSection.swift
//  FoundationLab
//

#if compiler(>=6.4) && arch(arm64)
import SwiftUI

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct SpotlightRAGIndexSection: View {
    let model: SpotlightRAGViewModel

    var body: some View {
        Xcode27Section(String(localized: "Local Spotlight Index")) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                ForEach(model.sampleDocuments) { document in
                    Label {
                        VStack(alignment: .leading, spacing: Spacing.xSmall) {
                            Text(document.title)
                                .bold()
                            Text(document.body)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    } icon: {
                        Image(systemName: "doc.text")
                            .foregroundStyle(.blue)
                    }

                    if document.id != model.sampleDocuments.last?.id {
                        Divider()
                    }
                }

                HStack(spacing: Spacing.small) {
                    Button("Clear Index", systemImage: "trash", action: clearIndex)
                        .buttonStyle(.glass)
                        .disabled(model.isIndexing || !model.hasIndexedSamples)

                    Button(
                        model.hasIndexedSamples ? "Reindex Samples" : "Index Samples",
                        systemImage: "square.stack.3d.up.badge.a",
                        action: indexSamples
                    )
                    .buttonStyle(.glassProminent)
                    .disabled(model.isIndexing || model.isRunning)
                }
                .controlSize(.large)

                Label(
                    model.hasIndexedSamples ? "Sample index is ready" : "Index the samples before asking a question",
                    systemImage: model.hasIndexedSamples ? "checkmark.circle.fill" : "circle.dashed"
                )
                .font(.callout)
                .foregroundStyle(model.hasIndexedSamples ? .green : .secondary)
            }
        }
    }

    private func indexSamples() {
        Task { await model.indexSamples() }
    }

    private func clearIndex() {
        Task { await model.clearIndex() }
    }
}
#endif
