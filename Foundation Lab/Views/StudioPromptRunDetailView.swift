//
//  StudioPromptRunDetailView.swift
//  Foundation Lab
//

import SwiftUI

struct StudioPromptRunDetailView: View {
    let run: StudioPromptRun

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(run.variant.title)
                            .font(.headline)
                        Text(run.finishedAt, style: .time)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(run.durationLabel)
                            .font(.headline.monospacedDigit())
                        Text(run.tokenLabel)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text("Prompt")
                        .font(.headline)
                    Text(run.prompt)
                        .font(.callout)
                        .textSelection(.enabled)
                }

                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text("Output")
                        .font(.headline)
                    Text(run.output)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .frame(minWidth: 320, idealWidth: 420, maxWidth: 520, minHeight: 320, idealHeight: 460)
    }
}
