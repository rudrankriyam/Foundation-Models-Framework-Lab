//
//  ExampleViewBase.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import SwiftUI

/// Base component for example views providing consistent UI elements
struct ExampleViewBase<Content: View>: View {
  let title: String
  let description: String
  @Binding var currentPrompt: String
  let isRunning: Bool
  let errorMessage: String?
  let codeExample: String?
  let runLabel: String
  let onRun: () -> Void
  let onReset: () -> Void
  let content: Content

  init(
    title: String,
    description: String,
    currentPrompt: Binding<String>,
    isRunning: Bool = false,
    errorMessage: String? = nil,
    codeExample: String? = nil,
    runLabel: String = "Run",
    onRun: @escaping () -> Void,
    onReset: @escaping () -> Void,
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.description = description
    self._currentPrompt = currentPrompt
    self.isRunning = isRunning
    self.errorMessage = errorMessage
    self.codeExample = codeExample
    self.runLabel = runLabel
    self.onRun = onRun
    self.onReset = onReset
    self.content = content()
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: Spacing.large) {
        Text(LocalizedStringKey(description))
          .font(.subheadline)
          .foregroundStyle(.secondary)

        promptSection
        actionButtons

        if let error = errorMessage {
          Label(error, systemImage: "exclamationmark.triangle.fill")
            .font(.callout)
            .foregroundStyle(.red)
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.red.opacity(0.08), in: .rect(cornerRadius: CornerRadius.medium))
        }

        content

        if let code = codeExample {
          CodeDisclosure(code: code)
        }
      }
      .padding(.horizontal, Spacing.medium)
      .padding(.vertical, Spacing.large)
    }
    #if os(iOS)
    .scrollDismissesKeyboard(.interactively)
    #endif
    .navigationTitle(Text(LocalizedStringKey(title)))
    #if os(iOS)
    .navigationBarTitleDisplayMode(.large)
    #endif
  }

  private var promptSection: some View {
    VStack(alignment: .leading, spacing: Spacing.small) {
      Text("Prompt")
        .font(.headline)
        .foregroundStyle(.secondary)

      TextEditor(text: $currentPrompt)
        .font(.body)
        .scrollContentBackground(.hidden)
        .padding(Spacing.medium)
        .frame(minHeight: 120)
        .background(.quaternary, in: .rect(cornerRadius: CornerRadius.medium))
        .accessibilityLabel("Prompt")
    }
  }

  private var actionButtons: some View {
    HStack(spacing: Spacing.small) {
      Button(action: onReset) {
        Text("Reset")
          .font(.callout)
          .fontWeight(.medium)
          .frame(maxWidth: .infinity)
          .padding(.vertical, Spacing.small)
      }
      .buttonStyle(.glass)
      .disabled(isRunning)
      .accessibilityHint("Restore this example's defaults")

      Button(action: onRun) {
        HStack(spacing: Spacing.small) {
          if isRunning {
            ProgressView()
              .scaleEffect(0.8)
          }
          Text(LocalizedStringKey(isRunning ? "Running..." : runLabel))
            .font(.callout)
            .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.small)
      }
      .buttonStyle(.glassProminent)
      .disabled(isRunning || currentPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
  }
}

// MARK: - Supporting Views

/// Reusable prompt suggestions view
struct PromptSuggestions: View {
  let suggestions: [String]
  let onSelect: (String) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.small) {
      Text("Suggestions")
        .font(.headline)
        .foregroundStyle(.secondary)

      ScrollView(.horizontal) {
        HStack(spacing: Spacing.small) {
          ForEach(suggestions, id: \.self) { suggestion in
            Button(action: { onSelect(suggestion) }, label: {
              Text(suggestion)
                .font(.callout)
            })
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
          }
        }
      }
      .scrollIndicators(.hidden)
    }
  }
}

#Preview {
  NavigationStack {
    ExampleViewBase(
      title: "Sample Example",
      description: "This is a sample example for demonstration",
      currentPrompt: .constant("Tell me a joke"),
      isRunning: false,
      errorMessage: nil,
      onRun: {},
      onReset: {},
      content: {
      ResultDisplay(
        result: "Why don't scientists trust atoms? Because they make up everything!",
        isSuccess: true
      )
    }
    )
  }
}
