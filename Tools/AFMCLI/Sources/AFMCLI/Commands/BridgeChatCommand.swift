import ArgumentParser
import Foundation
import FoundationModelsKit

struct BridgeChatCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "chat",
        abstract: "Send one prompt through the signed Foundation Lab bridge host."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var connection: BridgeConnectionOptions
    @OptionGroup var promptInput: PromptInputOptions

    @Option(name: .long, help: "Bridge model identifier. Defaults to system.")
    var model = "system"

    @Option(name: .long, help: "Sampling temperature between 0 and 1.")
    var temperature: Double?

    @Option(name: .customLong("max-tokens"), help: "Maximum number of response tokens.")
    var maximumTokens: Int?

    @Option(name: .customLong("top-p"), help: "Nucleus sampling threshold greater than 0 and at most 1.")
    var topP: Double?

    mutating func run() async throws {
        let output = try options.resolvedOutput()
        try await executeBridgeCommand(output: output) {
            let paths = try connection.resolve()
            let prompt = try requiredResolvedInput(promptInput.resolve())
            let request = try resolvedRequest(prompt: prompt.value)

            if options.dryRun {
                try CLIOutput.emit(
                    payload: BridgeChatDryRunPayload(request: request, prompt: prompt, paths: paths),
                    human: "[dry-run] afm bridge chat\nModel: \(request.model)\nPrompt: \(prompt.value)",
                    options: output
                )
                return
            }

            let body = try JSONEncoder().encode(request)
            let result = try await performBridgeRequest(paths: paths) { try await $0.chat(body: body) }
            guard let choice = result.response.choices.sorted(by: { $0.index < $1.index }).first,
                  let renderedResponse = nonemptyBridgeResponse(choice.message) else {
                throw AFMBridgeCommandError.invalidResponse(endpoint: result.host.endpointDescription)
            }
            var lines = [renderedResponse]
            if options.verbose {
                lines.append("")
                lines.append("Model: \(result.response.model)")
                lines.append("Finish reason: \(choice.finishReason)")
                lines.append(
                    "Tokens: \(result.response.usage.totalTokens) (\(result.response.usage.measurement.rawValue))"
                )
            }
            try CLIOutput.emit(
                payload: BridgeChatPayload(response: result.response, choice: choice),
                human: lines.joined(separator: "\n"),
                options: output
            )
        }
    }

    private func resolvedRequest(prompt: String) throws -> BridgeChatRequest {
        let resolvedModel = try validatedNonEmpty(model, optionName: "--model")
        if let temperature, !temperature.isFinite || !(0...1).contains(temperature) {
            throw ValidationError("--temperature must be between 0 and 1")
        }
        if let maximumTokens, maximumTokens <= 0 {
            throw ValidationError("--max-tokens must be greater than 0")
        }
        if let topP, !topP.isFinite || topP <= 0 || topP > 1 {
            throw ValidationError("--top-p must be greater than 0 and at most 1")
        }
        return BridgeChatRequest(
            model: resolvedModel,
            messages: [.init(role: "user", content: prompt)],
            temperature: temperature,
            topP: topP,
            maximumCompletionTokens: maximumTokens
        )
    }
}

private struct BridgeChatRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    let model: String
    let messages: [Message]
    let temperature: Double?
    let topP: Double?
    let maximumCompletionTokens: Int?

    private enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case topP = "top_p"
        case maximumCompletionTokens = "max_completion_tokens"
    }
}

private struct BridgeChatDryRunPayload: Encodable {
    let status = "dry_run"
    let command = "bridge chat"
    let descriptor: String
    let model: String
    let prompt: String
    let promptFile: String?
    let temperature: Double?
    let topP: Double?
    let maximumCompletionTokens: Int?

    init(request: BridgeChatRequest, prompt: ResolvedTextInput, paths: ResolvedBridgePaths) {
        descriptor = paths.descriptorPath
        model = request.model
        self.prompt = prompt.value
        promptFile = prompt.file
        temperature = request.temperature
        topP = request.topP
        maximumCompletionTokens = request.maximumCompletionTokens
    }
}

private struct BridgeChatPayload: Encodable {
    let command = "bridge chat"
    let id: String
    let model: String
    let response: String?
    let refusal: String?
    let finishReason: String
    let tokenUsage: ModelTokenUsage

    init(response: AFMBridgeChatResponse, choice: AFMBridgeChatResponse.Choice) {
        id = response.id
        model = response.model
        self.response = choice.message.content
        refusal = choice.message.refusal
        finishReason = choice.finishReason
        tokenUsage = response.usage.tokenUsage
    }
}

private func nonemptyBridgeResponse(_ message: AFMBridgeChatResponse.Choice.Message) -> String? {
    for candidate in [message.content, message.refusal] {
        if let candidate {
            let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
    }
    return nil
}
