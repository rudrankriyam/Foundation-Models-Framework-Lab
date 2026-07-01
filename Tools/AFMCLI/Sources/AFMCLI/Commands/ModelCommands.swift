import ArgumentParser
import Foundation
import FoundationModelsKit

struct ModelCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "model",
        abstract: "Inspect model readiness and supported languages.",
        subcommands: [
            ModelStatusCommand.self,
            ModelLanguagesCommand.self,
            ModelUseCasesCommand.self,
            ModelGuardrailsCommand.self
        ]
    )
}

struct ModelStatusPayload: Encodable {
    let status: String
    let isAvailable: Bool
    let reason: String
    let provider: String?
    let useCase: String
}

struct ModelStatusCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Check whether Apple Intelligence is available and ready."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var useCaseFlags: ModelUseCaseFlags

    mutating func run() async throws {
        let resolvedOutput = try options.resolvedOutput()
        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(command: "model status", useCase: useCaseFlags.useCase.rawValue),
                human: "[dry-run] afm model status",
                options: resolvedOutput
            )
            return
        }

        let availability = FoundationModelAvailabilityUseCase().execute(useCase: useCaseFlags.useCase)
        let payload = ModelStatusPayload(
            status: availability.isAvailable ? "available" : "unavailable",
            isAvailable: availability.isAvailable,
            reason: availabilityReasonDescription(availability),
            provider: availability.metadata.provider,
            useCase: useCaseFlags.useCase.rawValue
        )
        var lines = [
            "Foundation Models",
            "Use case: \(useCaseFlags.useCase.rawValue)",
            "Status: \(availability.isAvailable ? "Available" : "Unavailable")",
            "Reason: \(availabilityReasonDescription(availability))"
        ]
        if options.verbose, let provider = availability.metadata.provider {
            lines.append("Provider: \(provider)")
        }
        let human = lines.joined(separator: "\n")

        try CLIOutput.emit(payload: payload, human: human, options: resolvedOutput)
    }
}

struct ModelLanguagesPayload: Encodable {
    struct Language: Encodable {
        let identifier: String
        let displayName: String
    }

    let useCase: String
    let currentLanguage: String
    let languages: [Language]
}

struct ModelLanguagesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "languages",
        abstract: "List the languages supported by the current model runtime."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var useCaseFlags: ModelUseCaseFlags

    mutating func run() async throws {
        let resolvedOutput = try options.resolvedOutput()
        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(command: "model languages", useCase: useCaseFlags.useCase.rawValue),
                human: "[dry-run] afm model languages",
                options: resolvedOutput
            )
            return
        }

        let result = FoundationModelSupportedLanguagesUseCase().execute(useCase: useCaseFlags.useCase, locale: .current)
        let currentLanguage = currentSupportedLanguageDisplayName(from: result.languages)
        let payload = ModelLanguagesPayload(
            useCase: useCaseFlags.useCase.rawValue,
            currentLanguage: currentLanguage,
            languages: result.languages.map { language in
                .init(identifier: language.identifier, displayName: language.displayName(in: .current))
            }
        )
        var lines = [
            "Use case: \(useCaseFlags.useCase.rawValue)",
            "Current language: \(currentLanguage)",
            "",
            result.languages.map { $0.displayName(in: .current) }.joined(separator: "\n")
        ]
        if options.verbose {
            lines.append("")
            lines.append("Supported language count: \(result.languages.count)")
        }
        let human = lines.joined(separator: "\n")

        try CLIOutput.emit(payload: payload, human: human, options: resolvedOutput)
    }
}

struct ModelUseCasesPayload: Encodable {
    struct Entry: Encodable {
        let id: String
        let summary: String
    }

    let useCases: [Entry]
}

struct ModelUseCasesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "use-cases",
        abstract: "List the Foundation Models system use cases exposed by afm."
    )

    @OptionGroup var options: GlobalCommandOptions

    mutating func run() async throws {
        let resolvedOutput = try options.resolvedOutput()
        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(command: "model use-cases"),
                human: "[dry-run] afm model use-cases",
                options: resolvedOutput
            )
            return
        }

        let payload = ModelUseCasesPayload(
            useCases: [
                .init(id: FoundationModelUseCase.general.rawValue, summary: "General-purpose prompting and text generation."),
                .init(
                    id: FoundationModelUseCase.contentTagging.rawValue,
                    summary: "Specialized tagging use case that returns categorizing tags."
                )
            ]
        )
        let human = """
        general
          General-purpose prompting and text generation.

        content-tagging
          Specialized tagging use case that returns categorizing tags.
        """
        try CLIOutput.emit(payload: payload, human: human, options: resolvedOutput)
    }
}

struct ModelGuardrailsPayload: Encodable {
    struct Entry: Encodable {
        let id: String
        let summary: String
    }

    let guardrails: [Entry]
}

struct ModelGuardrailsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "guardrails",
        abstract: "List the Foundation Models guardrail modes exposed by afm."
    )

    @OptionGroup var options: GlobalCommandOptions

    mutating func run() async throws {
        let resolvedOutput = try options.resolvedOutput()
        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(command: "model guardrails"),
                human: "[dry-run] afm model guardrails",
                options: resolvedOutput
            )
            return
        }

        let payload = ModelGuardrailsPayload(
            guardrails: [
                .init(
                    id: FoundationModelGuardrails.default.afmArgumentValue,
                    summary: "Default guardrails that block unsafe content in prompts and responses."
                ),
                .init(
                    id: FoundationModelGuardrails.permissiveContentTransformations.afmArgumentValue,
                    summary: "Permissive transformations for String generation while keeping structured generation strict."
                )
            ]
        )
        let human = """
        default
          Default guardrails that block unsafe content in prompts and responses.

        permissive-content-transformations
          Permissive transformations for String generation while keeping structured generation strict.
        """
        try CLIOutput.emit(payload: payload, human: human, options: resolvedOutput)
    }
}
