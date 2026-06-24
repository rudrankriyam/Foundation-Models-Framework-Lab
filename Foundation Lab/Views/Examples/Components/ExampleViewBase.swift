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
  let showsPrompt: Bool
  let promptTitle: LocalizedStringKey
  let promptPlaceholder: LocalizedStringKey
  let onRun: () async -> Void
  let onReset: () -> Void
  let content: Content
  @State private var runTask: Task<Void, Never>?

  init(
    title: String,
    description: String,
    currentPrompt: Binding<String>,
    isRunning: Bool = false,
    errorMessage: String? = nil,
    codeExample: String? = nil,
    runLabel: String = "Run",
    showsPrompt: Bool = true,
    promptTitle: LocalizedStringKey = "Prompt",
    promptPlaceholder: LocalizedStringKey = "Enter a prompt",
    onRun: @escaping () async -> Void,
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
    self.showsPrompt = showsPrompt
    self.promptTitle = promptTitle
    self.promptPlaceholder = promptPlaceholder
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

        if showsPrompt {
          promptSection
        } else {
          runButton
        }

        if let error = errorMessage {
          Label {
            Text(error)
              .foregroundStyle(.primary)
          } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundStyle(.red)
          }
            .font(.callout)
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary, in: .rect(cornerRadius: CornerRadius.medium))
            .accessibilityLabel("Error: \(error)")
            .accessibilityElement(children: .combine)
        }

        content

        if let code = codeExample {
          CodeDisclosure(code: code)
        }
      }
      .padding(.horizontal, Spacing.medium)
      .padding(.vertical, Spacing.large)
      .frame(maxWidth: FoundationLabLayout.readableContentWidth, alignment: .leading)
      .frame(maxWidth: .infinity)
    }
    #if os(iOS)
    .scrollDismissesKeyboard(.interactively)
    #endif
    .navigationTitle(Text(LocalizedStringKey(title)))
    #if os(iOS)
    .navigationBarTitleDisplayMode(.large)
    #endif
    .onDisappear {
      cancelRun()
    }
  }

  private var promptSection: some View {
    VStack(alignment: .leading, spacing: Spacing.medium) {
      HStack {
        Text(promptTitle)
          .font(.headline)

        Spacer()

        Button("Reset", systemImage: "arrow.counterclockwise", action: reset)
          .buttonStyle(.borderless)
          .frame(minHeight: FoundationLabLayout.minimumTouchTarget)
          .disabled(isExecuting)
          .accessibilityHint("Restore this example's defaults")
      }

      TextField(promptPlaceholder, text: $currentPrompt, axis: .vertical)
        .lineLimit(3...6)
        .textFieldStyle(.roundedBorder)
        .accessibilityLabel("Prompt")

      runButton
    }
  }

  private var runButton: some View {
    Button(action: toggleRun) {
      Label {
        Text(LocalizedStringKey(isExecuting ? "Stop" : runLabel))
          .font(.callout.weight(.semibold))
      } icon: {
        Image(systemName: isExecuting ? "stop.fill" : "play.fill")
      }
      .frame(maxWidth: .infinity, minHeight: FoundationLabLayout.minimumTouchTarget)
    }
    .buttonStyle(.glassProminent)
    .disabled(
      !isExecuting && showsPrompt
        && currentPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    )
  }

  private var isExecuting: Bool {
    isRunning || runTask != nil
  }

  private func toggleRun() {
    if isExecuting {
      cancelRun()
      return
    }

    runTask = Task {
      await onRun()
      guard !Task.isCancelled else { return }
      runTask = nil
    }
  }

  private func cancelRun() {
    runTask?.cancel()
    runTask = nil
  }

  private func reset() {
    cancelRun()
    onReset()
  }
}

// MARK: - Supporting Views

/// Reusable prompt suggestions view
struct PromptSuggestions: View {
  let suggestions: [String]
  let onSelect: (String) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.small) {
      Text("Try a Prompt")
        .font(.headline)

      LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 180), spacing: Spacing.small)],
        alignment: .leading,
        spacing: Spacing.small
      ) {
        ForEach(suggestions, id: \.self) { suggestion in
          Button(action: { onSelect(suggestion) }, label: {
            Text(suggestion)
              .font(.callout)
              .multilineTextAlignment(.leading)
              .frame(maxWidth: .infinity, alignment: .leading)
          })
          .buttonStyle(.bordered)
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
