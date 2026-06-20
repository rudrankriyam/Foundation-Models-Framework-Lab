//
//  CodeViewer.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import HighlightSwift
import SwiftUI

/// A view for displaying syntax-highlighted code snippets
struct CodeViewer: View {
  let code: String
  let language: String
  @State private var isCopied = false

  @Environment(\.colorScheme) private var colorScheme
  @State private var highlightedCode: AttributedString?

  init(code: String, language: String = "swift") {
    self.code = code
    self.language = language
  }

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.small) {
      HStack {
        Text("Code")
          .font(.headline)
          .foregroundStyle(.secondary)

        Spacer()

        Button(action: copyToClipboard) {
          Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
            .font(.callout)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
        }
        .buttonStyle(.glass)
        .accessibilityLabel(isCopied ? "Copied" : "Copy code")
      }

      ScrollView([.horizontal, .vertical]) {
        Text(highlightedCode ?? AttributedString(code))
          .font(highlightedCode == nil ? .system(.callout, design: .monospaced) : nil)
          .textSelection(.enabled)
          .padding(Spacing.medium)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(maxHeight: 400)
      .background(.quaternary, in: .rect(cornerRadius: CornerRadius.medium))
      .task(id: colorScheme) {
          do {
              let highlight = Highlight()
              self.highlightedCode = try await highlight
                  .attributedText(code,
                    language: language,
                    colors: colorScheme == .dark ? .dark(.xcode) : .light(.xcode)
                  )
          } catch {
              self.highlightedCode = nil
          }
      }
    }
  }

  private func copyToClipboard() {
    #if os(iOS)
    UIPasteboard.general.string = code
    #elseif os(macOS)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(code, forType: .string)
    #endif

    isCopied = true
    Task {
      try? await Task.sleep(for: .seconds(2))
      guard !Task.isCancelled else { return }
      isCopied = false
    }
  }
}

/// Collapsible code section with disclosure
struct CodeDisclosure: View {
  let code: String
  let language: String
  @State private var isExpanded = false

  init(code: String, language: String = "swift") {
    self.code = code
    self.language = language
  }

  var body: some View {
    DisclosureGroup("View Code", isExpanded: $isExpanded) {
      CodeViewer(code: code, language: language)
        .padding(.top, Spacing.small)
    }
    .font(.callout)
  }
}

#Preview("CodeViewer") {
  ScrollView {
    VStack(spacing: Spacing.large) {
      CodeViewer(code: """
import FoundationModels

let session = LanguageModelSession()
let response = try await session.generate(
    with: "Tell me a joke",
    using: .conversational
)
""")

      CodeViewer(code: """
@Generable
struct Book {
    let title: String
    let author: String
    let genre: String
    let yearPublished: Int
}

let book = try await session.generate(
    prompt: "Suggest a sci-fi book",
    as: Book.self
)
""")
    }
    .padding()
  }
}

#Preview("CodeDisclosure") {
  ScrollView {
    VStack(spacing: Spacing.large) {
      CodeDisclosure(code: """
// Basic chat example
let session = LanguageModelSession()
let response = try await session.generate(
    with: prompt,
    using: .conversational
)
""")

      CodeDisclosure(code: """
// Structured data example
@Generable
struct JournalEntrySummary {
    let prompt: String
    let upliftingMessage: String
    let sentenceStarters: [String]
    let summaryBullets: [String]
    let themes: [String]
}

let summary = try await session.generate(
    prompt: prompt,
    as: JournalEntrySummary.self
)
""")
    }
    .padding()
  }
}
