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

                Xcode27Section(String(localized: "Bridge Layers")) {
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
        case .protocols: return String(localized: "Protocols")
        case .prewarm: return String(localized: "Prewarm")
        case .transcript: return String(localized: "Transcript")
        case .streaming: return String(localized: "Streaming")
        case .request: return String(localized: "Request Mapping")
        }
    }

    var detail: String {
        switch self {
        case .protocols: return String(localized: "Declare LanguageModel and LanguageModelExecutor.")
        case .prewarm: return String(localized: "Load resources before the user waits.")
        case .transcript: return String(localized: "Map transcript entries to provider messages.")
        case .streaming: return String(localized: "Send tokens and tool output through the channel.")
        case .request: return String(localized: "Translate the transcript and options for the backend.")
        }
    }

    var explanation: String {
        switch self {
        case .protocols:
            return String(
                localized: """
                A custom model adopts LanguageModel and pairs itself with one LanguageModelExecutor type. LanguageModelSession \
                continues to own the public prompting API.
                """
            )
        case .prewarm:
            return String(
                localized: """
                The framework calls the executor's prewarm hook when a session is prewarmed. Providers can load assets or prepare \
                cached state before generation begins.
                """
            )
        case .transcript:
            return String(
                localized: """
                The executor receives the session transcript and is responsible for mapping its entries to the provider's request \
                format.
                """
            )
        case .streaming:
            return String(
                localized: """
                The executor sends incremental generation events through LanguageModelExecutorGenerationChannel. The channel \
                finishes when respond returns or throws.
                """
            )
        case .request:
            return String(
                localized: """
                LanguageModelExecutorGenerationRequest carries the transcript plus generation and context options. A provider maps \
                supported options and defines deliberate fallbacks for unsupported ones.
                """
            )
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
            @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
            struct MyLanguageModel: LanguageModel {
                typealias Executor = MyLanguageModelExecutor

                let capabilities: LanguageModelCapabilities
                let executorConfiguration: Executor.Configuration
            }

            let session = LanguageModelSession(model: myModel)
            """
        case .prewarm:
            return """
            @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
            func prewarm(
                model: MyLanguageModel,
                transcript: Transcript
            ) {
                // Load assets or prepare cached state.
            }
            """
        case .transcript, .request:
            return """
            @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
            func respond(
                to request: LanguageModelExecutorGenerationRequest,
                model: MyLanguageModel,
                streamingInto channel: LanguageModelExecutorGenerationChannel
            ) async throws {
                let transcript = request.transcript
                let options = request.generationOptions
                // Translate transcript and options for the provider here.
            }
            """
        case .streaming:
            return """
            @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
            func respond(
                to request: LanguageModelExecutorGenerationRequest,
                model: MyLanguageModel,
                streamingInto channel: LanguageModelExecutorGenerationChannel
            ) async throws {
                await channel.send(.response(
                    action: .appendText("Hello", tokenCount: 1)
                ))
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
