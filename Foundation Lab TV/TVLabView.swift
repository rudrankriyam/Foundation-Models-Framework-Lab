//
//  TVLabView.swift
//  Foundation Lab TV
//

#if canImport(FoundationModels, _version: 2.2)
import FoundationModels
import SwiftUI

@available(tvOS 27.3, *)
struct TVLabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var availability = SystemLanguageModel.default.availability
    @State private var promptModel = TVPromptModel()
    @State private var recipeModel = TVRecipeModel()

    var body: some View {
        content
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    refreshAvailability()
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch availability {
        case .available:
            TabView {
                Tab("Prompt", systemImage: "text.bubble") {
                    TVPromptView(model: promptModel)
                }
                Tab("Structured Output", systemImage: "list.bullet.rectangle") {
                    TVRecipeView(model: recipeModel)
                }
            }
        case .unavailable(let reason):
            TVModelUnavailableView(reason: reason, retry: refreshAvailability)
        }
    }

    private func refreshAvailability() {
        availability = SystemLanguageModel.default.availability
        if case .unavailable = availability {
            promptModel.stop()
            recipeModel.stop()
        }
    }
}
#endif
