#if os(macOS)
import AFMServer
import FoundationModels

nonisolated enum AgentBridgeSessionBuilder {
    static func makeSession(
        requestedModelIdentifier: String,
        transcript: Transcript
    ) throws -> LanguageModelSession {
        switch requestedModelIdentifier {
        case "system":
            let model = SystemLanguageModel.default
            guard case .available = model.availability else {
                throw AFMChatGenerationError.modelUnavailable
            }
            return LanguageModelSession(model: model, transcript: transcript)
        case "pcc":
            return try makePrivateCloudSession(transcript: transcript)
        default:
            throw AFMChatGenerationError.modelUnavailable
        }
    }

    private static func makePrivateCloudSession(transcript: Transcript) throws -> LanguageModelSession {
        #if compiler(>=6.4)
        if #available(macOS 27.0, *) {
            guard AgentBridgePrivateCloudAuthorization.isGranted else {
                throw AFMChatGenerationError.modelUnavailable
            }
            let model = PrivateCloudComputeLanguageModel()
            guard model.isAvailable else {
                throw AFMChatGenerationError.modelUnavailable
            }
            guard !model.quotaUsage.isLimitReached else {
                throw AFMChatGenerationError.rateLimited
            }
            return LanguageModelSession(model: model, transcript: transcript)
        }
        #endif

        throw AFMChatGenerationError.modelUnavailable
    }
}
#endif
