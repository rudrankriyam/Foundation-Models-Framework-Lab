import ArgumentParser
import Foundation

struct RootStatusPayload: Encodable {
    let name: String
    let summary: String
    let commands: [String]
}

struct AFMRootCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "afm",
        abstract: "A powerful command-line interface for Foundation Models on Apple platforms.",
        discussion: HelpText.root,
        version: "0.1.0",
        subcommands: [
            ModelCommand.self,
            TokenCountCommand.self,
            TagCommand.self,
            SessionCommand.self,
            SchemaCommand.self,
            ToolCommand.self,
            TranscriptCommand.self,
            FeedbackCommand.self
        ]
    )

    @OptionGroup var options: GlobalCommandOptions

    mutating func run() async throws {
        let resolvedOutput = try options.resolvedOutput()
        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(command: "afm"),
                human: "[dry-run] afm",
                options: resolvedOutput
            )
            return
        }

        let payload = RootStatusPayload(
            name: Self.configuration.commandName ?? "afm",
            summary: "Workflow-first CLI for Foundation Models sessions, schemas, tools, transcripts, and feedback.",
            commands: ["model", "token-count", "tag", "session", "schema", "tool", "transcript", "feedback"]
        )
        let human: String
        if options.verbose {
            human = """
            \(HelpText.root)

            Version: \(Self.configuration.version)
            Command count: \(payload.commands.count)
            """
        } else {
            human = HelpText.root
        }

        try CLIOutput.emit(
            payload: payload,
            human: human,
            options: resolvedOutput
        )
    }
}
