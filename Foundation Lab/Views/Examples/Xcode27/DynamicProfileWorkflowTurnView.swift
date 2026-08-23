//
//  DynamicProfileWorkflowTurnView.swift
//  FoundationLab
//

#if compiler(>=6.4)
import SwiftUI

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct DynamicProfileWorkflowTurnView: View {
    let turn: DynamicProfileWorkflowTurn

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                Label(turn.stage.title, systemImage: turn.stage.systemImage)
                    .font(.headline)

                Spacer(minLength: Spacing.small)

                Text(turn.runtime.apiName)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            Text(turn.prompt)
                .font(.callout)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            if !turn.toolOutputs.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text("Tool Output")
                        .font(.subheadline)
                        .bold()
                    ForEach(turn.toolOutputs, id: \.self) { output in
                        Text(output)
                            .font(.callout.monospaced())
                            .textSelection(.enabled)
                    }
                }
            }

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("Model response")
                    .font(.subheadline)
                    .bold()
                Text(turn.response)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }

            Xcode27KeyValueList(items: [
                (String(localized: "Elapsed"), durationLabel),
                (String(localized: "Input"), tokenLabel(turn.inputTokens)),
                (String(localized: "Cached input"), tokenLabel(turn.cachedInputTokens)),
                (String(localized: "Output"), tokenLabel(turn.outputTokens)),
                (String(localized: "Reasoning output"), tokenLabel(turn.reasoningTokens)),
                (String(localized: "Total"), tokenLabel(turn.totalTokens)),
                (String(localized: "Transcript entries"), turn.transcriptEntryCount.formatted())
            ])
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var durationLabel: String {
        let components = turn.elapsed.components
        let seconds = Double(components.seconds) + Double(components.attoseconds) / 1e18
        return String(localized: "\(seconds.formatted(.number.precision(.fractionLength(2)))) s")
    }

    private func tokenLabel(_ count: Int) -> String {
        count == 1 ? String(localized: "1 token") : String(localized: "\(count) tokens")
    }
}
#endif
