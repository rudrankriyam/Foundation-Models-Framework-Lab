//
//  GeminiVideoInputViewModel.swift
//  FoundationLab
//
//  Created by Codex on 6/15/26.
//

import Foundation
import FoundationModels
import Observation
import UniformTypeIdentifiers

#if compiler(>=6.4)
@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
@Observable
final class GeminiVideoInputViewModel {
    static let modelName = "gemini-3.5-flash"
    static let defaultPrompt = """
    Return exactly three concise bullets: (1) describe the cracked terrain and distant horizon, (2) describe how \
    the storm clouds and rain shafts move and how the light changes, and (3) summarize the color palette and mood \
    shift. Report only clearly visible details. Do not identify the location or name any optical phenomenon.
    """

    var apiKey: String
    var prompt = defaultPrompt
    var videoURL: URL?
    var result = ""
    var resultIsSuccess = false
    var errorMessage: String?
    var isRunning = false

    private var analysisTask: Task<Void, Never>?
    private var activeAnalysisID: UUID?

    init(
        bundle: Bundle = .main,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        let environmentAPIKey = environment["GEMINI_API_KEY"] ?? ""
        apiKey = environmentAPIKey
        videoURL = bundle.url(
            forResource: "AlvordDesertSunset",
            withExtension: "mp4",
            subdirectory: "Resources"
        ) ?? bundle.url(forResource: "AlvordDesertSunset", withExtension: "mp4")
    }

    var videoName: String {
        videoURL?.lastPathComponent ?? "No video selected"
    }

    var videoSize: String {
        guard let videoURL else {
            return "Unknown size"
        }

        let accessed = videoURL.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                videoURL.stopAccessingSecurityScopedResource()
            }
        }

        guard let values = try? videoURL.resourceValues(forKeys: [.fileSizeKey]),
              let bytes = values.fileSize else {
            return "Unknown size"
        }

        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension GeminiVideoInputViewModel {
    var codeExample: String {
        """
        let video = VideoSegment(data: data, mimeType: "video/mp4")
        let model = GeminiDeveloperVideoLanguageModel(
            apiKey: apiKey,
            modelName: "\(Self.modelName)"
        )
        let session = LanguageModelSession(model: model)
        let response = try await session.respond {
            video
            prompt
        }
        """
    }

    func selectVideo(_ url: URL) {
        cancelAnalysis()
        videoURL = url
        result = ""
        errorMessage = nil
    }

    func startAnalysis() {
        guard let videoURL else {
            errorMessage = "Choose a video before running the analysis."
            return
        }

        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            errorMessage = "Enter a prompt before running the experiment."
            return
        }

        if apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = GeminiDeveloperAPIError.apiKeyMissing.localizedDescription
            return
        }

        cancelAnalysis()

        let request = GeminiVideoAnalysisRequest(
            videoURL: videoURL,
            prompt: trimmedPrompt,
            apiKey: apiKey
        )
        let analysisID = UUID()
        activeAnalysisID = analysisID
        isRunning = true
        errorMessage = nil
        result = ""
        resultIsSuccess = false

        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.performAnalysis(request, id: analysisID)
        }
        analysisTask = task
    }

    func cancelAnalysis() {
        activeAnalysisID = nil
        analysisTask?.cancel()
        analysisTask = nil
        isRunning = false
    }

    func reset() {
        cancelAnalysis()
        prompt = Self.defaultPrompt
        result = ""
        errorMessage = nil
        resultIsSuccess = false
    }
}

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension GeminiVideoInputViewModel {
    func performAnalysis(_ request: GeminiVideoAnalysisRequest, id: UUID) async {
        defer {
            if activeAnalysisID == id {
                activeAnalysisID = nil
                analysisTask = nil
                isRunning = false
            }
        }

        do {
            let loadedVideo = try await Self.loadVideo(from: request.videoURL)
            try Task.checkCancellation()

            let video = VideoSegment(
                data: loadedVideo.data,
                mimeType: loadedVideo.mimeType
            )
            let content = try await runCustomWrapper(
                video: video,
                prompt: request.prompt,
                apiKey: request.apiKey
            )
            try Task.checkCancellation()

            guard activeAnalysisID == id else { return }
            result = content
            resultIsSuccess = !content.isEmpty
        } catch is CancellationError {
            return
        } catch {
            guard activeAnalysisID == id else { return }
            errorMessage = error.localizedDescription
        }
    }

    func runCustomWrapper(video: VideoSegment, prompt: String, apiKey: String) async throws -> String {
        try Task.checkCancellation()
        let model = GeminiDeveloperVideoLanguageModel(
            apiKey: apiKey,
            modelName: Self.modelName
        )
        let session = LanguageModelSession(model: model)
        try Task.checkCancellation()
        let response = try await session.respond {
            video
            prompt
        }
        try Task.checkCancellation()

        return response.content
    }

    @concurrent
    nonisolated static func loadVideo(from url: URL) async throws -> LoadedVideo {
        try Task.checkCancellation()

        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let mimeType = try mimeType(for: url)
        let file = try FileHandle(forReadingFrom: url)
        defer {
            try? file.close()
        }

        var data = Data()
        while let chunk = try file.read(upToCount: 1_048_576), !chunk.isEmpty {
            try Task.checkCancellation()
            data.append(chunk)
        }
        try Task.checkCancellation()

        return LoadedVideo(data: data, mimeType: mimeType)
    }

    nonisolated static func mimeType(for url: URL) throws -> String {
        let resourceType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType
        let fileType = resourceType ?? UTType(filenameExtension: url.pathExtension)

        guard let fileType,
              fileType.conforms(to: .movie),
              let mimeType = fileType.preferredMIMEType else {
            throw GeminiVideoInputError.unsupportedVideoFormat(url.pathExtension)
        }

        return mimeType
    }
}

private struct GeminiVideoAnalysisRequest: Sendable {
    let videoURL: URL
    let prompt: String
    let apiKey: String
}

private struct LoadedVideo: Sendable {
    let data: Data
    let mimeType: String
}

private enum GeminiVideoInputError: LocalizedError {
    case unsupportedVideoFormat(String)

    var errorDescription: String? {
        switch self {
        case let .unsupportedVideoFormat(pathExtension):
            let format = pathExtension.isEmpty ? "unknown" : pathExtension.uppercased()
            return "The selected \(format) file does not have a recognized video MIME type."
        }
    }
}
#endif
