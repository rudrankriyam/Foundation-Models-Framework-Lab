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
  let defaultPrompt: String
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
    defaultPrompt: String,
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
    self.defaultPrompt = defaultPrompt
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
        promptSection
        actionButtons

        if let error = errorMessage {
          Text(error)
            .font(.callout)
            .foregroundColor(.secondary)
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
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
    .navigationTitle(title)
    #if os(iOS)
    .navigationBarTitleDisplayMode(.large)
    .navigationSubtitle(description)
    #endif
  }

  private var promptSection: some View {
    VStack(alignment: .leading, spacing: Spacing.small) {
      Text("PROMPT")
        .font(.footnote)
        .fontWeight(.medium)
        .foregroundColor(.secondary)

      TextEditor(text: $currentPrompt)
        .font(.body)
        .scrollContentBackground(.hidden)
        .padding(Spacing.medium)
        .frame(minHeight: 120)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
  }

  private var actionButtons: some View {
    HStack(spacing: Spacing.small) {
      Button(action: onReset) {
        Text("Clear")
          .font(.callout)
          .fontWeight(.medium)
          .frame(maxWidth: .infinity)
          .padding(.vertical, Spacing.small)
      }
      .buttonStyle(.glassProminent)
      .tint(.secondary)
      .disabled(currentPrompt == defaultPrompt || currentPrompt.isEmpty)

      Button(action: onRun) {
        HStack(spacing: Spacing.small) {
          if isRunning {
            ProgressView()
              .scaleEffect(0.8)
              .tint(.white)
          }
          Text(isRunning ? "Running..." : runLabel)
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
      Text("SUGGESTIONS")
        .font(.footnote)
        .fontWeight(.medium)
        .foregroundColor(.secondary)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: Spacing.small) {
          ForEach(suggestions, id: \.self) { suggestion in
            Button(action: { onSelect(suggestion) }, label: {
              Text(suggestion)
                .font(.callout)
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
                .background(Color.gray.opacity(0.1))
                .foregroundColor(.primary)
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(12)
            })
            .buttonStyle(.plain)
          }
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    ExampleViewBase(
      title: "Sample Example",
      description: "This is a sample example for demonstration",
      defaultPrompt: "Tell me a joke",
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
