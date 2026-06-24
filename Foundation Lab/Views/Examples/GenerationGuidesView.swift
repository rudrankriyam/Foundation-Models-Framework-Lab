//
//  GenerationGuidesView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationLabCore
import SwiftUI

struct GenerationGuidesView: View {
  @State private var currentPrompt = FoundationLabExampleDemo.generationGuides.defaultPrompt
  @State private var executor = ExampleExecutor()

  var body: some View {
    ExampleViewBase(
      title: "Generation Guides",
      description: "Constrain a structured response with @Guide annotations.",
      currentPrompt: $currentPrompt,
      isRunning: executor.isRunning,
      errorMessage: executor.errorMessage,
      codeExample: DefaultPrompts.generationGuidesCode(prompt: currentPrompt),
      onRun: executeGenerationGuides,
      onReset: resetToDefaults
    ) {
      VStack(spacing: 16) {
        Label(
          "The schema uses @Guide annotations for the rating, strengths, limitations, and recommendation.",
          systemImage: "info.circle"
        )
        .font(.callout)
        .foregroundStyle(.secondary)

        // Prompt Suggestions
        PromptSuggestions(
          suggestions: FoundationLabExampleDemo.generationGuides.suggestions,
          onSelect: { currentPrompt = $0 }
        )

        // Prompt History
        if !executor.promptHistory.isEmpty {
          PromptHistory(
            history: executor.promptHistory,
            onSelect: { currentPrompt = $0 }
          )
        }

        // Result Display
        if !executor.result.isEmpty {
          VStack(alignment: .leading, spacing: 12) {
            Label("Product Review", systemImage: "star.leadinghalf.filled")
              .font(.headline)

            ResultDisplay(
              result: executor.result,
              isSuccess: executor.errorMessage == nil,
              tokenCount: executor.lastTokenCount
            )
          }
        }
      }
    }
  }

  private func executeGenerationGuides() async {
    await executor.executeStructured(
      prompt: currentPrompt,
      type: ProductReview.self
    ) { review in
      review.plainTextSummary
    }
  }

  private func resetToDefaults() {
    currentPrompt = FoundationLabExampleDemo.generationGuides.defaultPrompt
    executor.clearAll()
  }
}

#Preview {
  NavigationStack {
    GenerationGuidesView()
  }
}
