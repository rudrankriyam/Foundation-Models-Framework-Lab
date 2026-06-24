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

    @State private var showsSamples = false

    var body: some View {
        Xcode27Section(String(localized: "Local Spotlight Index")) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                if model.isIndexing {
                    ProgressView("Indexing four sample notes…")
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if model.hasIndexedSamples {
                    HStack(spacing: Spacing.small) {
                        Label("Four sample notes are ready", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)

                        Spacer()

                        Menu("Index actions", systemImage: "ellipsis.circle") {
                            Button("Reindex Samples", systemImage: "arrow.clockwise", action: indexSamples)
                            Button("Clear Index", systemImage: "trash", role: .destructive, action: clearIndex)
                        }
                        .labelStyle(.iconOnly)
                        .frame(
                            minWidth: FoundationLabLayout.minimumTouchTarget,
                            minHeight: FoundationLabLayout.minimumTouchTarget
                        )
                    }
                } else {
                    Button(
                        "Index Four Sample Notes",
                        systemImage: "square.stack.3d.up.badge.a",
                        action: indexSamples
                    )
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .disabled(model.isIndexing || model.isRunning)
                }

                DisclosureGroup(isExpanded: $showsSamples) {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        ForEach(model.sampleDocuments) { document in
                            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                                Text(document.title)
                                    .bold()
                                Text(document.body)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }

                            if document.id != model.sampleDocuments.last?.id {
                                Divider()
                            }
                        }
                    }
                    .padding(.top, Spacing.small)
                } label: {
                    Text("Preview sample notes")
                        .frame(
                            maxWidth: .infinity,
                            minHeight: FoundationLabLayout.minimumTouchTarget,
                            alignment: .leading
                        )
                }
                .font(.callout)
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
