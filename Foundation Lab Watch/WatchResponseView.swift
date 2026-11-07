//
//  WatchResponseView.swift
//  Foundation Lab Watch
//

import FoundationModels
import SwiftUI

struct WatchResponseView: View {
    let model: PrivateCloudComputeLanguageModel
    let prompt: String

    @State private var response = ""
    @State private var errorMessage: String?
    @State private var hasCompleted = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(prompt)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                } else if response.isEmpty && !hasCompleted {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if response.isEmpty {
                    Text("The model returned an empty response.")
                        .foregroundStyle(.secondary)
                } else {
                    Text(response)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Response")
        .task { await respond() }
    }

    private func respond() async {
        guard !hasCompleted else { return }
        response = ""
        errorMessage = nil

        let session = LanguageModelSession(
            model: model,
            instructions: "Answer in a few short sentences that fit on an Apple Watch screen."
        )

        do {
            for try await snapshot in session.streamResponse(to: prompt) {
                response = snapshot.content
            }
            hasCompleted = true
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
            hasCompleted = true
        }
    }
}
