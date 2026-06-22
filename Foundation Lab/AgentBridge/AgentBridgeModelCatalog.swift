#if os(macOS)
import AFMServer
import FoundationModels

nonisolated struct AgentBridgeModelCatalog: AFMModelCatalog {
    func models() -> [AFMServerModel] {
        var models: [AFMServerModel] = []
        if case .available = SystemLanguageModel.default.availability {
            models.append(AFMServerModel(id: "system", isAvailable: true))
        }

        #if compiler(>=6.4)
        if #available(macOS 27.0, *),
           AgentBridgePrivateCloudAuthorization.isGranted,
           PrivateCloudComputeLanguageModel().isAvailable {
            models.append(AFMServerModel(id: "pcc", isAvailable: true))
        }
        #endif

        return models
    }
}
#endif
