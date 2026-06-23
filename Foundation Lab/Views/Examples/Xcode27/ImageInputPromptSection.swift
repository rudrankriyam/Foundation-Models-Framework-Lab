//
//  ImageInputPromptSection.swift
//  FoundationLab
//

#if compiler(>=6.4)
import SwiftUI

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
struct ImageInputPromptSection: View {
    @Binding var prompt: String
    @Binding var recipe: ImageInputRecipe
    let isBusy: Bool
    let chooseRecipe: (ImageInputRecipe) -> Void
    let reset: () -> Void

    var body: some View {
        Xcode27Section(String(localized: "Prompt")) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                LabeledContent("Starting prompt") {
                    Picker("Starting prompt", selection: $recipe) {
                        ForEach(ImageInputRecipe.allCases) { recipe in
                            Text(recipe.title).tag(recipe)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .disabled(isBusy)
                    .onChange(of: recipe) { _, newValue in
                        chooseRecipe(newValue)
                    }
                }
                .frame(minHeight: 44)

                TextField("Ask about the image", text: $prompt, axis: .vertical)
                    .lineLimit(3...8)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isBusy)
                    .accessibilityHint("Edit what the model should inspect in the selected image")

                Button("Reset Lab", systemImage: "arrow.counterclockwise", action: reset)
                    .buttonStyle(.borderless)
                    .controlSize(.large)
                    .frame(minHeight: 44)
                    .disabled(isBusy)
            }
        }
    }
}
#endif
