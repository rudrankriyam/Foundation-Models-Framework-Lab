//
//  TVRecipeModel.swift
//  Foundation Lab TV
//

#if canImport(FoundationModels, _version: 2.2)
import Foundation
import FoundationModels
import Observation

@available(tvOS 27.3, *)
@Observable
final class TVRecipeModel {
    static let dishes = [
        String(localized: "A cozy pasta for movie night"),
        String(localized: "A quick vegetarian breakfast"),
        String(localized: "A no-bake dessert for four")
    ]

    private(set) var recipe: TVRecipe.PartiallyGenerated?
    private(set) var dish: String?
    private(set) var isResponding = false
    private(set) var errorMessage: String?
    private var task: Task<Void, Never>?
    private var runCount = 0

    func generate(_ dish: String) {
        task?.cancel()
        runCount += 1
        let run = runCount
        self.dish = dish
        recipe = nil
        errorMessage = nil
        isResponding = true

        task = Task {
            defer {
                if run == runCount { isResponding = false }
            }
            do {
                let session = LanguageModelSession()
                let stream = session.streamResponse(
                    to: "Create a recipe for: \(dish)",
                    generating: TVRecipe.self
                )
                for try await snapshot in stream {
                    guard !Task.isCancelled else { break }
                    recipe = snapshot.content
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
