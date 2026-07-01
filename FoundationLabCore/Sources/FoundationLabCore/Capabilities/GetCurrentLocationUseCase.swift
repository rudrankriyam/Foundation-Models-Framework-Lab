import Foundation
import FoundationModelsKit

public struct GetCurrentLocationUseCase: FoundationModelCapabilityUseCase {
    public static let descriptor = FoundationModelCapabilityDescriptor(
        id: "foundation-models.get-current-location",
        displayName: "Get Current Location",
        summary: "Gets the user's current location using a shared Foundation Models capability."
    )

    private let responder: any LocationResponding

    public init(responder: any LocationResponding = FoundationModelsLocationResponder()) {
        self.responder = responder
    }

    public func execute(_ request: GetCurrentLocationRequest) async throws -> FoundationModelTextGenerationResult {
        try await responder.getCurrentLocation(for: request)
    }
}
