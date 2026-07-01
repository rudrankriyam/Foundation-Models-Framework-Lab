import Foundation
import FoundationModelsKit
public struct QueryHealthDataRequest: FoundationModelCapabilityRequest, Sendable {
    public let query: String
    public let systemPrompt: String?
    public let modelUseCase: FoundationModelUseCase
    public let guardrails: FoundationModelGuardrails?
    public let referenceDate: Date
    public let timeZoneIdentifier: String
    public let context: FoundationModelInvocationContext

    public init(
        query: String,
        systemPrompt: String? = nil,
        modelUseCase: FoundationModelUseCase = .general,
        guardrails: FoundationModelGuardrails? = nil,
        referenceDate: Date = .now,
        timeZoneIdentifier: String = TimeZone.current.identifier,
        context: FoundationModelInvocationContext
    ) {
        self.query = query
        self.systemPrompt = systemPrompt
        self.modelUseCase = modelUseCase
        self.guardrails = guardrails
        self.referenceDate = referenceDate
        self.timeZoneIdentifier = timeZoneIdentifier
        self.context = context
    }
}
