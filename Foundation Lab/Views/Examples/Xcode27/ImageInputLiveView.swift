//
//  ImageInputLiveView.swift
//  FoundationLab
//

#if compiler(>=6.4)
import SwiftUI
import UniformTypeIdentifiers

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ImageInputLiveView: View {
    @State private var model = ImageInputViewModel()
    @State private var isImporterPresented = false
    @AccessibilityFocusState private var isErrorFocused: Bool
    @AccessibilityFocusState private var isResultFocused: Bool

    var body: some View {
        @Bindable var model = model

        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.xLarge) {
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text("Ask the on-device model about an image")
                        .font(.title2.bold())
                    Text("Choose one image, edit the prompt, then inspect the model's answer and run evidence.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ImageInputAvailabilityView(message: model.readinessMessage)

                ImageInputSelectionSection(
                    selection: model.selection,
                    isImporting: model.isImporting,
                    isRunning: model.isRunning,
                    chooseImage: presentImporter,
                    removeImage: model.removeImage,
                    cancelImport: model.cancelImport
                )

                ImageInputPromptSection(
                    prompt: $model.prompt,
                    recipe: $model.recipe,
                    isBusy: model.isImporting || model.isRunning,
                    chooseRecipe: model.chooseRecipe,
                    reset: model.reset
                )

                Button(
                    model.isRunning ? "Stop" : "Analyze Image",
                    systemImage: model.isRunning ? "stop.fill" : "sparkles",
                    action: toggleRun
                )
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity, minHeight: 44)
                .disabled(!model.isRunning && !model.canRun)
                .accessibilityHint(runButtonHint)
                #if os(macOS)
                .keyboardShortcut(.return, modifiers: [.command])
                #endif

                if let errorMessage = model.errorMessage {
                    Label {
                        Text(errorMessage)
                            .foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                    .font(.callout)
                    .padding(Spacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary, in: .rect(cornerRadius: CornerRadius.medium))
                    .accessibilityLabel("Error: \(errorMessage)")
                    .accessibilityElement(children: .combine)
                    .accessibilityFocused($isErrorFocused)
                }

                if let result = model.result {
                    ImageInputResultSection(result: result)
                        .id("image-input-result")
                        .accessibilityFocused($isResultFocused)
                }

                ImageInputAttachmentNotesView()
                    .id("image-input-attachment-notes")
                ImageInputResolutionFindingsView()
                    .id("image-input-resolution-notes")
                CodeDisclosure(code: model.recipe.code)
                    .id("image-input-code")
            }
            .frame(maxWidth: 900, alignment: .leading)
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
            .frame(maxWidth: .infinity)
        }
        #if os(iOS)
        .scrollDismissesKeyboard(.interactively)
        #endif
        .navigationTitle("Image Input")
        .navigationSubtitle("Run a real multimodal request")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.image],
            onCompletion: model.importImage
        )
        .onDisappear(perform: model.cancelAll)
        .onChange(of: model.errorMessage) { _, errorMessage in
            guard errorMessage != nil else { return }
            isResultFocused = false
            isErrorFocused = true
        }
        .onChange(of: model.result?.id) { _, resultID in
            guard resultID != nil else { return }
            isErrorFocused = false
            isResultFocused = true
        }
        .sensoryFeedback(.success, trigger: model.result?.id) { oldValue, newValue in
            newValue != nil && newValue != oldValue
        }
    }

    private var runButtonHint: String {
        if model.isRunning {
            String(localized: "Cancel the current model request")
        } else if model.isImporting {
            String(localized: "Wait for the image import to finish or cancel the import")
        } else if model.selection == nil {
            String(localized: "Choose an image before running the model")
        } else if model.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            String(localized: "Enter a prompt before running the model")
        } else if model.readinessMessage != nil {
            String(localized: "The on-device model must be ready for image input before this request can run")
        } else {
            String(localized: "Send the selected image and prompt to the on-device model")
        }
    }

    private func presentImporter() {
        isImporterPresented = true
    }

    private func toggleRun() {
        if model.isRunning {
            model.cancelRun()
        } else {
            model.startRun()
        }
    }
}
#endif
