import ArgumentParser

func executeBridgeCommand(
    output: CLIOutputOptions,
    operation: () async throws -> Void
) async throws {
    do {
        try await operation()
    } catch {
        CLIOutput.emitError(error, format: output.format)
        if error is ValidationError {
            throw ExitCode.validationFailure
        }
        throw ExitCode.failure
    }
}

func performBridgeRequest<Response: Sendable>(
    paths: ResolvedBridgePaths,
    retryAfterDescriptorRotation: Bool = true,
    operation: (AFMBridgeCommandConnection) async throws -> Response
) async throws -> (host: AFMBridgeCommandConnection, response: Response) {
    let firstHost = try AFMBridgeCommandConnection.connect(paths: paths)
    do {
        return (firstHost, try await operation(firstHost))
    } catch is CancellationError {
        throw CancellationError()
    } catch {
        try Task.checkCancellation()
        guard retryAfterDescriptorRotation,
              let replacementDescriptor = try? paths.readDescriptor(),
              replacementDescriptor.launchIdentifier != firstHost.descriptor.launchIdentifier,
              let replacementHost = try? AFMBridgeCommandConnection.connect(paths: paths) else {
            throw error
        }
        return (replacementHost, try await operation(replacementHost))
    }
}
