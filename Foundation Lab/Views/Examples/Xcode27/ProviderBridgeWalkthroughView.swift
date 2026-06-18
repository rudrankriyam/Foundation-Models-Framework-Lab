//
//  ProviderBridgeWalkthroughView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct ProviderBridgeWalkthroughView: View {
    @State private var currentPrompt = "Explain how a custom model becomes a LanguageModelSession backend."
    @State private var selectedLayer = ProviderBridgeLayer.protocols

    var body: some View {
        ExampleViewBase(
            title: "Provider Bridge",
            description: "Map custom models into LanguageModelSession",
            defaultPrompt: "Explain how a custom model becomes a LanguageModelSession backend.",
            currentPrompt: $currentPrompt,
            codeExample: selectedLayer.code,
            onRun: nextLayer,
            onReset: reset
        ) {
            VStack(spacing: Spacing.medium) {
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
                    Text(selectedLayer.explanation)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func nextLayer() {
        let cases = ProviderBridgeLayer.allCases
        guard let index = cases.firstIndex(of: selectedLayer) else { return }
        selectedLayer = cases[(index + 1) % cases.count]
    }

    private func select(_ layer: ProviderBridgeLayer) {
        selectedLayer = layer
    }

    private func reset() {
        currentPrompt = ""
        selectedLayer = .protocols
    }
}

private enum ProviderBridgeLayer: String, CaseIterable, Identifiable {
    case protocols
    case prewarm
    case transcript
    case streaming
    case metadata

    var id: String { rawValue }

    var title: String {
        switch self {
        case .protocols: return "Protocols"
        case .prewarm: return "Prewarm"
        case .transcript: return "Transcript"
        case .streaming: return "Streaming"
        case .metadata: return "Metadata"
        }
    }

    var detail: String {
        switch self {
        case .protocols: return "Declare LanguageModel and LanguageModelExecutor."
        case .prewarm: return "Load resources before the user waits."
        case .transcript: return "Map transcript entries to provider messages."
        case .streaming: return "Send tokens and tool output through the channel."
        case .metadata: return "Attach provider diagnostics to responses."
        }
    }

    var explanation: String {
        switch self {
        case .protocols:
            return "A provider bridge should make a custom backend feel like any other LanguageModelSession model."
        case .prewarm:
            return "Prewarm is where package authors hide weight loading, connection setup, or KV cache preparation."
        case .transcript:
            return "The executor owns the translation from Foundation Models transcript entries to its provider's message format."
        case .streaming:
            return "Streaming should preserve cancellation, partial output, tool calls, and errors without blocking UI state."
        case .metadata:
            return """
            Metadata makes custom providers inspectable: model id, cache hits, latency, safety filters, and provider-specific usage.
            """
        }
    }

    var icon: String {
        switch self {
        case .protocols: return "curlybraces"
        case .prewarm: return "flame"
        case .transcript: return "list.bullet.rectangle.portrait"
        case .streaming: return "waveform"
        case .metadata: return "tag"
        }
    }

    var code: String {
        """
        public struct MyLanguageModel: LanguageModel {
            public typealias Executor = MyLanguageModelExecutor
            public var capabilities: LanguageModelCapabilities
            public var executorConfiguration: Executor.Configuration
        }

        let custom = try await CoreAILanguageModel(resourcesAt: modelURL)
        let session = LanguageModelSession(model: custom)
        """
    }
}

#Preview {
    NavigationStack {
        ProviderBridgeWalkthroughView()
    }
}
