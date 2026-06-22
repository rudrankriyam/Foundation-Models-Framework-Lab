import ArgumentParser

struct BridgeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "bridge",
        abstract: "Use a signed Foundation Lab host from agents and automation.",
        discussion: """
        Agent Bridge does not require a TTY. Foundation Lab remains the signed host
        for system and PCC requests while afm connects through an authenticated local endpoint.
        """,
        subcommands: [
            BridgePrepareCommand.self,
            BridgeEnsureCommand.self,
            BridgeStatusCommand.self,
            BridgeModelsCommand.self,
            BridgeChatCommand.self
        ]
    )
}
