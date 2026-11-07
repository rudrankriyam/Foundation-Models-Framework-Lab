//
//  TVLabView.swift
//  Foundation Lab TV
//

#if canImport(FoundationModels, _version: 2.2)
import FoundationModels
import SwiftUI

@available(tvOS 27.3, *)
struct TVLabView: View {
    private let model = SystemLanguageModel.default

    var body: some View {
        switch model.availability {
        case .available:
            TabView {
                Tab("Prompt", systemImage: "text.bubble") {
                    TVPromptView()
                }
                Tab("Structured Output", systemImage: "list.bullet.rectangle") {
                    TVRecipeView()
                }
            }
        case .unavailable(let reason):
            TVModelUnavailableView(reason: reason)
        }
    }
}
#endif
