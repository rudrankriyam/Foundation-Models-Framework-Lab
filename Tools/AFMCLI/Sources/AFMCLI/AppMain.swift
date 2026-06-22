import Foundation

@main
struct AFMEntryPoint {
    static func main() async {
        let arguments = CommandLine.arguments
        if let failure = suggestionFailure(for: arguments) {
            fputs("Error: \(failure)\n", stderr)
            Foundation.exit(64)
        }

        await AFMRootCommand.main()
    }

    private static func suggestionFailure(for arguments: [String]) -> String? {
        guard arguments.count > 1 else { return nil }

        let firstArgument = arguments[1]
        guard !firstArgument.hasPrefix("-") else { return nil }

        let rootCommands = [
            "model", "token-count", "tag", "session", "schema", "tool", "transcript", "feedback", "serve",
            "help", "version"
        ]
        if !rootCommands.contains(firstArgument) {
            if let suggestion = suggestRootCommand(for: firstArgument) {
                return "Unknown command '\(firstArgument)'. Did you mean '\(suggestion)'?"
            }
            return nil
        }

        guard arguments.count > 2 else { return nil }
        let secondArgument = arguments[2]
        guard !secondArgument.hasPrefix("-") else { return nil }

        let subcommands: [String: [String]] = [
            "model": ["status", "languages", "use-cases", "guardrails"],
            "tag": ["run"],
            "session": ["respond", "stream", "chat"],
            "schema": ["list", "run"],
            "tool": ["inspect", "validate", "call"],
            "transcript": ["export"],
            "feedback": ["export"]
        ]

        guard let knownSubcommands = subcommands[firstArgument],
              !knownSubcommands.contains(secondArgument),
              let suggestion = suggestCommand(secondArgument, in: knownSubcommands) else {
            return nil
        }

        return "Unknown command '\(firstArgument) \(secondArgument)'. Did you mean '\(firstArgument) \(suggestion)'?"
    }
}
