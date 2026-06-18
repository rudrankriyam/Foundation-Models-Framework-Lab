//
//  ProviderBridgeWalkthroughView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct ProviderBridgeWalkthroughView: View {
    @State private var selectedLayer = ProviderBridgeLayer.protocols

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                Label {
                    VStack(alignment: .leading, spacing: Spacing.xSmall) {
                        Text("Reference walkthrough")
                            .bold()
                        Text("No model is loaded and no request is sent. Select a layer to inspect the provider contract.")
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "book.pages")
                        .foregroundStyle(.purple)
                }
                .font(.callout)
                .padding(Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.purple.opacity(0.08), in: .rect(cornerRadius: CornerRadius.medium))

                Xcode27Section("Bridge Layers") {
                    VStack(spacing: 0) {
                        ForEach(ProviderBridgeLayer.allCases) { layer in
                            Button {
                                select(layer)
                            } label: {
                                HStack {
                                    Xcode27InfoRow(
                                        title: layer.title,
                                        detail: layer.detail,
                                        systemImage: layer.icon,
                                        tint: layer == selectedLayer ? .purple : .secondary
                                    )

                                    if layer == selectedLayer {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.purple)
                                            .accessibilityHidden(true)
                                    }
                                }
                                .frame(minHeight: 44)
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(layer == selectedLayer ? .isSelected : [])

                            if layer != ProviderBridgeLayer.allCases.last {
                                Divider()
                            }
                        }
                    }
                }

                Xcode27Section(selectedLayer.title) {
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Text(selectedLayer.explanation)
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        Button("Inspect Next Layer", systemImage: "arrow.down", action: nextLayer)
                            .buttonStyle(.glassProminent)
                    }
                }

                CodeDisclosure(code: selectedLayer.code)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
        }
        .navigationTitle("Provider Bridge")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .navigationSubtitle("How a custom LanguageModel executes session requests")
        #endif
    }

    private func nextLayer() {
        let cases = ProviderBridgeLayer.allCases
        guard let index = cases.firstIndex(of: selectedLayer) else { return }
        selectedLayer = cases[(index + 1) % cases.count]
    }

    private func select(_ layer: ProviderBridgeLayer) {
        selectedLayer = layer
    }
}

private enum ProviderBridgeLayer: String, CaseIterable, Identifiable {
    case protocols
    case prewarm
    case request
    case transcript
    case streaming

    var id: String { rawValue }

    var title: String {
        switch self {
        case .protocols: return "Protocols"
        case .prewarm: return "Prewarm"
        case .transcript: return "Transcript"
        case .streaming: return "Streaming"
        case .request: return "Request Mapping"
        }
    }

    var detail: String {
        switch self {
        case .protocols: return "Declare LanguageModel and LanguageModelExecutor."
        case .prewarm: return "Load resources before the user waits."
        case .transcript: return "Map transcript entries to provider messages."
        case .streaming: return "Send tokens and tool output through the channel."
        case .request: return "Translate the transcript and options for the backend."
        }
    }

    var explanation: String {
        switch self {
        case .protocols:
            return "A custom model adopts LanguageModel and pairs itself with one LanguageModelExecutor type. "
                + "LanguageModelSession continues to own the public prompting API."
        case .prewarm:
            return "The framework calls the executor's prewarm hook when a session is prewarmed. "
                + "Providers can load assets or prepare cached state before generation begins."
        case .transcript:
            return "The executor receives the session transcript and is responsible for mapping its entries "
                + "to the provider's request format."
        case .streaming:
            return "The executor sends incremental generation events through LanguageModelExecutorGenerationChannel. "
                + "The channel finishes when respond returns or throws."
        case .request:
            return "LanguageModelExecutorGenerationRequest carries the transcript plus generation and context options. "
                + "A provider maps supported options and defines deliberate fallbacks for unsupported ones."
        }
    }

    var icon: String {
        switch self {
        case .protocols: return "curlybraces"
        case .prewarm: return "flame"
        case .transcript: return "list.bullet.rectangle.portrait"
        case .streaming: return "waveform"
        case .request: return "arrow.left.arrow.right"
        }
    }

    var code: String {
        switch self {
        case .protocols:
            return """
            struct MyLanguageModel: LanguageModel {
                typealias Executor = MyLanguageModelExecutor

                let capabilities: LanguageModelCapabilities
                let executorConfiguration: Executor.Configuration
            }

            let session = LanguageModelSession(model: myModel)
            """
        case .prewarm:
            return """
            func prewarm(
                model: MyLanguageModel,
                transcript: Transcript
            ) {
                // Load assets or prepare cached state.
            }
            """
        case .transcript, .request:
            return """
            func respond(
                to request: LanguageModelExecutorGenerationRequest,
                model: MyLanguageModel,
                streamingInto channel: LanguageModelExecutorGenerationChannel
            ) async throws {
                // Map request.transcript and the requested options.
            }
            """
        case .streaming:
            return """
            func respond(
                to request: LanguageModelExecutorGenerationRequest,
                model: MyLanguageModel,
                streamingInto channel: LanguageModelExecutorGenerationChannel
            ) async throws {
                // Send incremental generation events to channel.
                // Returning or throwing finishes the channel.
            }
            """
        }
    }
}

#Preview {
    NavigationStack {
        ProviderBridgeWalkthroughView()
    }
}
