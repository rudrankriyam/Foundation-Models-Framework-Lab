import Foundation
import FoundationModels
import Testing
@testable import AFMServer

@Test("Foundation Models generator forwards the requested model identifier to its session builder")
func foundationModelsGeneratorForwardsRequestedModel() async throws {
    let probe = AFMSessionBuilderProbe()
    let generator = AFMFoundationModelsChatGenerator { modelIdentifier, _ in
        probe.record(modelIdentifier)
        throw AFMSessionBuilderTestError.expected
    }
    let request = AFMChatGenerationRequest(
        model: "pcc",
        messages: [.init(role: .user, contentSegments: ["Hello"])]
    )

    await #expect(throws: AFMSessionBuilderTestError.expected) {
        try await generator.generate(request)
    }
    #expect(probe.modelIdentifier == "pcc")
}

private final class AFMSessionBuilderProbe: @unchecked Sendable {
    private let lock = NSLock()
    private var recordedModelIdentifier: String?

    var modelIdentifier: String? {
        lock.withLock { recordedModelIdentifier }
    }

    func record(_ modelIdentifier: String) {
        lock.withLock { recordedModelIdentifier = modelIdentifier }
    }
}

private enum AFMSessionBuilderTestError: Error {
    case expected
}
