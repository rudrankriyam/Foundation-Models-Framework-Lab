//
//  AppBenchStudioInspector.swift
//  Foundation Lab
//
//  Created by Codex on 6/12/26.
//

import SwiftUI

struct AppBenchStudioInspector: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                metric(value: "5", title: "Suites")
                metric(value: "10", title: "Workloads")
                metric(value: "2", title: "Runners")
            }

            Divider()

            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Canonical Execution")
                    .font(.headline)

                note(title: "Mac", detail: "Run the CLI for official macOS results.")
                note(title: "iPhone and iPad", detail: "Use the signed runner on physical hardware.")
                note(title: "Simulator", detail: "Never publish its benchmark output.")
            }
        }
        .padding(Spacing.large)
    }

    private func metric(value: String, title: String) -> some View {
        LabeledContent {
            Text(value)
                .font(.callout.monospacedDigit())
        } label: {
            Text(title)
                .font(.callout)
        }
    }

    private func note(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.callout)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    AppBenchStudioInspector()
        .frame(width: 300)
}
