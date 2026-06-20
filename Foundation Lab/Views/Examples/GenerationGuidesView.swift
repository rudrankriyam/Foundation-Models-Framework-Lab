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
      description: "Guided generation with constraints and structured output",
      currentPrompt: $currentPrompt,
      isRunning: executor.isRunning,
      errorMessage: executor.errorMessage,
      codeExample: DefaultPrompts.generationGuidesCode(prompt: currentPrompt),
      onRun: executeGenerationGuides,
      onReset: resetToDefaults
    ) {
      VStack(spacing: 16) {
        // Info Banner
        HStack {
          Image(systemName: "info.circle")
            .foregroundStyle(.blue)
          Text("Uses @Guide annotations to structure product reviews with ratings, pros, cons, and recommendations")
            .font(.caption)
            .foregroundStyle(.secondary)
          Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .clipShape(.rect(cornerRadius: 8))

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
            Label("Generated Product Review", systemImage: "star.leadinghalf.filled")
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
