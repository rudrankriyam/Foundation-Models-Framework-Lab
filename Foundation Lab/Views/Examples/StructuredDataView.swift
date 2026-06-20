//
//  StructuredDataView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationLabCore
import SwiftUI

struct StructuredDataView: View {
  @State private var currentPrompt = FoundationLabExampleDemo.structuredData.defaultPrompt
  @State private var executor = ExampleExecutor()

  var body: some View {
    ExampleViewBase(
      title: "Structured Data",
      description: "Generate and parse structured information",
      currentPrompt: $currentPrompt,
      isRunning: executor.isRunning,
      errorMessage: executor.errorMessage,
      codeExample: DefaultPrompts.structuredDataCode(prompt: currentPrompt),
      onRun: executeStructuredData,
      onReset: resetToDefaults
    ) {
      VStack(spacing: 16) {
        // Info Banner
        HStack {
          Image(systemName: "info.circle")
            .foregroundStyle(.tint)
          Text("Generates structured book recommendations with title, author, genre, and description")
            .font(.caption)
            .foregroundStyle(.secondary)
          Spacer()
        }
        .padding()
        .background(Color.main.opacity(0.1))
        .clipShape(.rect(cornerRadius: 8))

        // Prompt Suggestions
        PromptSuggestions(
          suggestions: FoundationLabExampleDemo.structuredData.suggestions,
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
            Label("Generated Book Recommendation", systemImage: "book")
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

  private func executeStructuredData() async {
    await executor.executeBookRecommendation(prompt: currentPrompt)
  }

  private func resetToDefaults() {
    currentPrompt = FoundationLabExampleDemo.structuredData.defaultPrompt
    executor.clearAll()
  }
}

#Preview {
  NavigationStack {
    StructuredDataView()
  }
}
