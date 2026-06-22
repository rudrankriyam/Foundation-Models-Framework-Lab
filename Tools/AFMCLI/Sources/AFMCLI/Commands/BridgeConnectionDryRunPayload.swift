struct BridgeConnectionDryRunPayload: Encodable {
    let status = "dry_run"
    let command: String
    let descriptor: String

    init(command: String, paths: ResolvedBridgePaths) {
        self.command = command
        descriptor = paths.descriptorPath
    }
}
