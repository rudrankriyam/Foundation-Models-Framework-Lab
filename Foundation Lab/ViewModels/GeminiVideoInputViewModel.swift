//
//  GeminiVideoInputViewModel.swift
//  FoundationLab
//
//  Created by Codex on 6/15/26.
//

import Foundation
import FoundationModels
import Observation

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
        videoURL = url
        result = ""
        errorMessage = nil
    }

    func analyzeVideo() async {
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

        isRunning = true
        errorMessage = nil
        result = ""
        resultIsSuccess = false

        defer {
            isRunning = false
        }

        do {
            let loadedVideo = try await Task.detached(priority: .userInitiated) {
                try Self.loadVideo(from: videoURL)
            }.value
            let video = VideoSegment(
                data: loadedVideo.data,
                mimeType: loadedVideo.mimeType
            )

            try await runCustomWrapper(video: video, prompt: trimmedPrompt)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reset() {
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
    func runCustomWrapper(video: VideoSegment, prompt: String) async throws {
        let model = GeminiDeveloperVideoLanguageModel(
            apiKey: apiKey,
            modelName: Self.modelName
        )
        let session = LanguageModelSession(model: model)
        let response = try await session.respond {
            video
            prompt
        }

        result = response.content
        resultIsSuccess = !response.content.isEmpty
    }

    nonisolated static func loadVideo(from url: URL) throws -> LoadedVideo {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let file = try FileHandle(forReadingFrom: url)
        defer {
            try? file.close()
        }

        return LoadedVideo(
            data: try file.readToEnd() ?? Data(),
            mimeType: mimeType(for: url)
        )
    }

    nonisolated static func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "mov":
            return "video/quicktime"
        case "m4v":
            return "video/x-m4v"
        default:
            return "video/mp4"
        }
    }
}

private struct LoadedVideo: Sendable {
    let data: Data
    let mimeType: String
}
