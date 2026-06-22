import FoundationModels

public typealias AFMFoundationModelsSessionBuilder = @Sendable (
    _ requestedModelIdentifier: String,
    _ transcript: Transcript
) throws -> LanguageModelSession

public typealias AFMFoundationModelsToolSessionBuilder = @Sendable (
    _ requestedModelIdentifier: String,
    _ tools: [any Tool],
    _ transcript: Transcript
) throws -> LanguageModelSession
