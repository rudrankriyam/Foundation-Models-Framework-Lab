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
                    chooseImage: presentImporter,
                    removeImage: model.removeImage
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
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(.red)
                        .padding(Spacing.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.red.opacity(0.08), in: .rect(cornerRadius: CornerRadius.medium))
                        .accessibilityLabel("Error: \(errorMessage)")
                }

                if let result = model.result {
                    ImageInputResultSection(result: result)
                        .id("image-input-result")
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
        .sensoryFeedback(.success, trigger: model.result != nil) { oldValue, newValue in
            !oldValue && newValue
        }
    }

    private var runButtonHint: String {
        if model.isRunning {
            String(localized: "Cancel the current model request")
        } else if model.selection == nil {
            String(localized: "Choose an image before running the model")
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
