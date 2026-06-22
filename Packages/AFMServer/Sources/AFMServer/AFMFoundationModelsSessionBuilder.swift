import FoundationModels

public typealias AFMFoundationModelsSessionBuilder = @Sendable (
    _ requestedModelIdentifier: String,
    _ transcript: Transcript
) throws -> LanguageModelSession
