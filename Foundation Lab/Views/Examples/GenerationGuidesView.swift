//
//  GenerationGuidesView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import Foundation
import FoundationLabCore
import FoundationModels
import FoundationModelsKit
import SwiftUI

struct GenerationGuidesView: View {
  @State private var currentPrompt = FoundationLabExampleDemo.generationGuides.defaultPrompt
  @State private var executor = ExampleExecutor()
  @State private var generatedJSON = ""

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
        Label(schemaNote, systemImage: "info.circle")
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

          if !generatedJSON.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
              Label("Generated Content", systemImage: "curlybraces")
                .font(.headline)

              Text(generatedJSON)
                .font(.system(.callout, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.quaternary, in: .rect(cornerRadius: 12))
            }
          }
        }
      }
    }
  }

  private func executeGenerationGuides() async {
    generatedJSON = ""
    await executor.executeStructured(
      prompt: currentPrompt,
      type: ProductReview.self
    ) { review in
      generatedJSON = Self.prettyJSON(review.generatedContent.jsonString)
      return review.plainTextSummary
    }
  }

  private var schemaNote: String {
    #if canImport(FoundationModels, _version: 2.2)
    String(
      localized: """
      @Guide(key:) maps productName, rating, and recommendation to product_name, star_rating, \
      and verdict in the generated content.
      """
    )
    #else
    String(localized: "The schema uses @Guide annotations for the rating, strengths, limitations, and recommendation.")
    #endif
  }

  private static func prettyJSON(_ source: String) -> String {
    guard let data = source.data(using: .utf8),
          let object = try? JSONSerialization.jsonObject(with: data),
          let prettyData = try? JSONSerialization.data(
            withJSONObject: object,
            options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
          ),
          let result = String(data: prettyData, encoding: .utf8) else {
      return source
    }
    return result
  }

  private func resetToDefaults() {
    currentPrompt = FoundationLabExampleDemo.generationGuides.defaultPrompt
    generatedJSON = ""
    executor.clearAll()
  }
}

#Preview {
  NavigationStack {
    GenerationGuidesView()
  }
}
