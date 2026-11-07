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

    var canRun: Bool {
        !isResponding && !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func run() {
        guard canRun else { return }
        let prompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        response = ""
        errorMessage = nil
        isResponding = true

        task = Task {
            defer { isResponding = false }
            do {
                let session = LanguageModelSession(
                    instructions: "Answer clearly and keep responses short enough to read on a TV screen."
                )
                for try await snapshot in session.streamResponse(to: prompt) {
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
    }
}
#endif
