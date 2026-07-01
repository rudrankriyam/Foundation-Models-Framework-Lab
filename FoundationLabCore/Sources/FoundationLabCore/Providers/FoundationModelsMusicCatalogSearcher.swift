import Foundation
import FoundationModelsTools
import FoundationModelsKit
#if canImport(MusicKit)
import MusicKit
#endif

public struct FoundationModelsMusicCatalogSearcher: MusicCatalogSearching {
    private let toolInvoker: FoundationModelsToolInvoker

    public init(toolInvoker: FoundationModelsToolInvoker = FoundationModelsToolInvoker()) {
        self.toolInvoker = toolInvoker
    }

    public func searchMusic(for request: SearchMusicCatalogRequest) async throws -> FoundationModelTextGenerationResult {
        let query = request.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing query")
        }

        try await validateMusicEnvironment()

        return try await toolInvoker.respond(
            to: query,
            using: MusicTool(),
            systemPrompt: request.systemPrompt,
            modelUseCase: request.modelUseCase,
            guardrails: request.guardrails
        )
    }

    private func validateMusicEnvironment() async throws {
        #if canImport(MusicKit)
        let currentStatus = MusicAuthorization.currentStatus

        switch currentStatus {
        case .authorized:
            break
        case .notDetermined:
            let status = await MusicAuthorization.request()
            guard status == .authorized else {
                throw FoundationLabCoreError.unavailableCapability(
                    "Apple Music access is required to search the catalog."
                )
            }
        case .denied:
            throw FoundationLabCoreError.unavailableCapability(
                "Apple Music access is denied. Enable Music access for Foundation Lab in Settings."
            )
        case .restricted:
            throw FoundationLabCoreError.unavailableCapability(
                "Apple Music access is restricted on this device."
            )
        @unknown default:
            throw FoundationLabCoreError.unavailableCapability(
                "Apple Music authorization is required to use this capability."
            )
        }

        do {
            let subscription = try await MusicSubscription.current
            guard subscription.canPlayCatalogContent else {
                throw FoundationLabCoreError.unavailableCapability(
                    "An active Apple Music subscription is required to search the catalog."
                )
            }
        } catch let error as FoundationLabCoreError {
            throw error
        } catch {
            throw FoundationLabCoreError.unavailableCapability(
                "Unable to verify Apple Music subscription: \(error.localizedDescription)"
            )
        }
        #else
        throw FoundationLabCoreError.unsupportedEnvironment(
            "Music catalog search requires MusicKit support."
        )
        #endif
    }
}
