//
//  TVPromptModel.swift
//  Foundation Lab TV
//

#if canImport(FoundationModels, _version: 2.2)
import Foundation
import FoundationModels
import Observation

@available(tvOS 27.3, *)
@Observable
final class TVPromptModel {
    static let presets = [
        String(localized: "Explain how a rainbow forms in three sentences."),
        String(localized: "Write a haiku about a quiet evening at home."),
        String(localized: "Suggest five names for a family movie night.")
    ]

    var prompt = ""
    private(set) var response = ""
    private(set) var isResponding = false
    private(set) var errorMessage: String?
    private var task: Task<Void, Never>?
    private var runCount = 0

    var hasPrompt: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func run() {
        let prompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        task?.cancel()
        runCount += 1
        let run = runCount
        response = ""
        errorMessage = nil
        isResponding = true

        task = Task {
            defer {
                if run == runCount { isResponding = false }
            }
            do {
                let session = LanguageModelSession(
                    instructions: "Answer clearly and keep responses short enough to read on a TV screen."
                )
                for try await snapshot in session.streamResponse(to: prompt) {
                    guard !Task.isCancelled else { break }
                    response = snapshot.content
                }
            } catch {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        runCount += 1
        isResponding = false
    }
}
#endif
