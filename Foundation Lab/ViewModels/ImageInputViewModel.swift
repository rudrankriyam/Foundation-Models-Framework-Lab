//
//  ImageInputViewModel.swift
//  FoundationLab
//

#if compiler(>=6.4)
import Foundation
import FoundationModels
import Observation

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
@Observable
final class ImageInputViewModel {
    private(set) var selection: ImageInputSelection?
    private(set) var result: ImageInputRunResult?
    private(set) var isImporting = false
    private(set) var isRunning = false
    private(set) var isStoppingRun = false
    var prompt = ImageInputRecipe.altText.prompt {
        didSet {
            if prompt != oldValue {
                result = nil
                errorMessage = nil
            }
        }
    }
    var recipe = ImageInputRecipe.altText {
        didSet {
            if recipe != oldValue {
                result = nil
                errorMessage = nil
            }
        }
    }
    var errorMessage: String?

    private let importer = ImageInputImporter()
    private var importTask: Task<Void, Never>?
    private var runTask: Task<Void, Never>?
    private var activeImportID: UUID?
    private var activeRunID: UUID?

    var canRun: Bool {
        selection != nil
            && !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && readinessMessage == nil
            && !isImporting
            && !isRunning
            && !isStoppingRun
    }

    var readinessMessage: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            if SystemLanguageModel.default.capabilities.contains(.vision) {
                nil
            } else {
                String(localized: "The active system model does not support image input on this device.")
            }
        case .unavailable(.deviceNotEligible):
            String(localized: "This device does not support Apple Intelligence.")
        case .unavailable(.appleIntelligenceNotEnabled):
            String(localized: "Turn on Apple Intelligence in Settings, then return to run the lab.")
        case .unavailable(.modelNotReady):
            String(localized: "The on-device model is still preparing. Try again when Apple Intelligence is ready.")
        @unknown default:
            String(localized: "The on-device system language model is currently unavailable.")
        }
    }

    func chooseRecipe(_ recipe: ImageInputRecipe) {
        self.recipe = recipe
        prompt = recipe.prompt
        errorMessage = nil
    }

    func importImage(from result: Result<URL, any Error>) {
        switch result {
        case .success(let url):
            guard !isRunning else {
                errorMessage = String(localized: "Stop the current analysis before replacing the image.")
                return
            }

            cancelImport()

            let importID = UUID()
            activeImportID = importID
            isImporting = true
            errorMessage = nil

            importTask = Task { @MainActor [weak self] in
                await self?.performImport(url: url, id: importID)
            }
        case .failure(let error):
            if (error as? CocoaError)?.code == .userCancelled {
                return
            }
            errorMessage = importFailureMessage(for: error)
        }
    }

    func removeImage() {
        guard !isRunning else { return }
        cancelImport()
        selection = nil
        result = nil
        errorMessage = nil
    }

    func startRun() {
        guard canRun, let selection else { return }

        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let runID = UUID()
        activeRunID = runID
        isRunning = true
        isStoppingRun = false
        errorMessage = nil

        runTask = Task { @MainActor [weak self] in
            await self?.performRun(prompt: trimmedPrompt, selection: selection, id: runID)
        }
    }

    func cancelRun() {
        guard isRunning, !isStoppingRun else { return }
        isStoppingRun = true
        runTask?.cancel()
    }

    func cancelImport() {
        activeImportID = nil
        importTask?.cancel()
        importTask = nil
        isImporting = false
    }

    func reset() {
        cancelImport()
        cancelRun()
        selection = nil
        result = nil
        recipe = .altText
        prompt = ImageInputRecipe.altText.prompt
        errorMessage = nil
    }

    func cancelAll() {
        cancelImport()
        cancelRun()
    }
}

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
private extension ImageInputViewModel {
    func performImport(url: URL, id: UUID) async {
        defer {
            if activeImportID == id {
                activeImportID = nil
                importTask = nil
                isImporting = false
            }
        }

        do {
            let importedSelection = try await importer.load(url)
            try Task.checkCancellation()
            guard activeImportID == id else { return }
            selection = importedSelection
            result = nil
        } catch is CancellationError {
            return
        } catch {
            guard activeImportID == id else { return }
            errorMessage = importFailureMessage(for: error, attemptedFileName: url.lastPathComponent)
        }
    }

    func importFailureMessage(for error: any Error, attemptedFileName: String? = nil) -> String {
        guard let retainedFileName = selection?.fileName else {
            return error.localizedDescription
        }

        if let attemptedFileName {
            return String(
                localized: "Couldn't import \(attemptedFileName). Keeping \(retainedFileName). \(error.localizedDescription)"
            )
        }
        return String(localized: "Couldn't open a replacement image. Keeping \(retainedFileName). \(error.localizedDescription)")
    }

    func performRun(prompt: String, selection: ImageInputSelection, id: UUID) async {
        defer {
            if activeRunID == id {
                activeRunID = nil
                runTask = nil
                isRunning = false
                isStoppingRun = false
            }
        }

        guard SystemLanguageModel.default.isAvailable else {
            guard activeRunID == id else { return }
            errorMessage = readinessMessage
            return
        }
        guard SystemLanguageModel.default.capabilities.contains(.vision) else {
            guard activeRunID == id else { return }
            errorMessage = String(localized: "The active system model does not support image input on this device.")
            return
        }

        do {
            let cgImage = try await importer.fullResolutionImage(from: selection.data)
            try Task.checkCancellation()

            let attachment = Attachment<ImageAttachmentContent>(
                cgImage,
                orientation: selection.orientation
            )
            .label("selected-image")
            let session = LanguageModelSession()
            let clock = ContinuousClock()
            let startedAt = clock.now
            let response = try await session.respond {
                prompt
                attachment
            }
            let finishedAt = clock.now

            try Task.checkCancellation()
            guard activeRunID == id, self.selection?.id == selection.id else { return }

            result = ImageInputRunResult(
                response: response.content,
                prompt: prompt,
                imageName: selection.fileName,
                inputTokens: response.usage.input.totalTokenCount,
                cachedInputTokens: response.usage.input.cachedTokenCount,
                outputTokens: response.usage.output.totalTokenCount,
                reasoningTokens: response.usage.output.reasoningTokenCount,
                totalTokens: response.usage.totalTokenCount,
                transcriptEntryCount: session.transcript.count,
                attachmentSegmentCount: Self.attachmentSegmentCount(in: session.transcript),
                duration: startedAt.duration(to: finishedAt)
            )
        } catch is CancellationError {
            return
        } catch {
            guard activeRunID == id, self.selection?.id == selection.id else { return }
            errorMessage = error.localizedDescription
        }
    }

    static func attachmentSegmentCount(in transcript: Transcript) -> Int {
        var count = 0
        for entry in transcript {
            guard case .prompt(let prompt) = entry else { continue }
            for segment in prompt.segments {
                if case .attachment = segment {
                    count += 1
                }
            }
        }
        return count
    }
}
#endif
