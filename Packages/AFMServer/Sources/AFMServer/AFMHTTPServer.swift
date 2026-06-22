import Foundation
import NIOCore
import NIOHTTP1
import NIOPosix

public enum AFMServerBoundAddress: Sendable, Equatable, CustomStringConvertible {
    case tcp(host: String, port: Int)
    case unixSocket(path: String)

    public var description: String {
        switch self {
        case .tcp(let host, let port):
            let renderedHost = host.contains(":") && !host.hasPrefix("[") ? "[\(host)]" : host
            return "http://\(renderedHost):\(port)"
        case .unixSocket(let path):
            return path
        }
    }
}

public enum AFMHTTPServerStateError: Error, LocalizedError {
    case alreadyStarted
    case notStarted
    case missingLocalAddress

    public var errorDescription: String? {
        switch self {
        case .alreadyStarted:
            "The server has already started."
        case .notStarted:
            "The server has not started."
        case .missingLocalAddress:
            "The server started without a local address."
        }
    }
}

public actor AFMHTTPServer {
    private let configuration: AFMServerConfiguration
    private let router: AFMRequestRouter
    private let childChannels = AFMChildChannelRegistry()
    private var group: MultiThreadedEventLoopGroup?
    private var channel: (any Channel)?
    private var socketLease: AFMUnixSocketLease?
    private var hasStarted = false

    public init(
        configuration: AFMServerConfiguration = .init(),
        catalog: any AFMModelCatalog,
        clock: any AFMServerClock = AFMSystemServerClock(),
        generator: any AFMChatCompletionGenerating
    ) throws {
        let configuration = try configuration.validated()
        self.configuration = configuration
        let chatCompletions = AFMChatCompletionService(
            catalog: catalog,
            generator: generator,
            clock: clock,
            policy: configuration.generation
        )
        router = AFMRequestRouter(
            configuration: configuration,
            catalog: catalog,
            clock: clock,
            chatCompletions: chatCompletions
        )
    }

    public func start() async throws -> AFMServerBoundAddress {
        guard !hasStarted else { throw AFMHTTPServerStateError.alreadyStarted }
        hasStarted = true

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.group = group
        let bootstrap = makeBootstrap(group: group)

        do {
            switch configuration.endpoint {
            case .tcp(let host, let port):
                let channel = try await bootstrap.bind(host: host, port: port).get()
                guard let boundPort = channel.localAddress?.port else {
                    try await channel.close().get()
                    throw AFMHTTPServerStateError.missingLocalAddress
                }
                self.channel = channel
                return .tcp(host: host, port: boundPort)
            case .unixSocket(let path):
                try AFMUnixSocketManager.prepare(path: path)
                let boundSocket = try AFMUnixSocketManager.makeBoundSocket(path: path)
                do {
                    let channel = try await bootstrap.withBoundSocket(boundSocket.descriptor).get()
                    socketLease = boundSocket.lease
                    self.channel = channel
                    return .unixSocket(path: path)
                } catch {
                    do {
                        try AFMUnixSocketManager.cleanupAfterFailedAdoption(boundSocket)
                    } catch {
                        socketLease = boundSocket.lease
                    }
                    throw error
                }
            }
        } catch {
            self.channel = nil
            let socketCleanupError = cleanupSocket()
            let groupShutdownError = await shutdownEventLoopGroup()
            hasStarted = socketCleanupError != nil || groupShutdownError != nil
            throw error
        }
    }

    public func waitUntilClosed() async throws {
        guard let channel else { throw AFMHTTPServerStateError.notStarted }
        try await channel.closeFuture.get()
    }

    public func stop() async throws {
        let listeningChannelError = await closeListeningChannel()
        let childChannelError = await closeChildChannels()
        let socketCleanupError = cleanupSocket()
        let groupShutdownError = await shutdownEventLoopGroup()

        let errors = [listeningChannelError, childChannelError, socketCleanupError, groupShutdownError]
        if let firstError = errors.compactMap({ $0 }).first {
            throw firstError
        }
        childChannels.finishShutdown()
        hasStarted = false
    }

    private func closeListeningChannel() async -> Error? {
        guard let channel else { return nil }
        guard channel.isActive else {
            self.channel = nil
            return nil
        }
        do {
            try await channel.close().get()
            self.channel = nil
            return nil
        } catch {
            return error
        }
    }

    private func closeChildChannels() async -> Error? {
        var firstError: Error?
        for childChannel in childChannels.beginShutdown() {
            guard childChannel.isActive else {
                childChannels.remove(childChannel)
                continue
            }
            do {
                try await childChannel.close().get()
                childChannels.remove(childChannel)
            } catch {
                if firstError == nil { firstError = error }
            }
        }
        return firstError
    }

    private func cleanupSocket() -> Error? {
        guard let socketLease else { return nil }
        do {
            try socketLease.cleanup()
            self.socketLease = nil
            return nil
        } catch {
            return error
        }
    }

    private func shutdownEventLoopGroup() async -> Error? {
        guard let group else { return nil }
        do {
            try await group.shutdownGracefully()
            self.group = nil
            return nil
        } catch {
            return error
        }
    }

    private func makeBootstrap(group: MultiThreadedEventLoopGroup) -> ServerBootstrap {
        var decoderLimits = NIOHTTPDecoderLimitConfiguration()
        decoderLimits.maxHeaderFieldSize = configuration.limits.maximumHeaderFieldBytes
        decoderLimits.maxHeaderListSize = configuration.limits.maximumHeaderBytes
        decoderLimits.maxHeaderFieldCount = configuration.limits.maximumHeaderCount
        let configuredDecoderLimits = decoderLimits

        let router = router
        let limits = configuration.limits
        let childChannels = childChannels
        return ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .childChannelOption(ChannelOptions.allowRemoteHalfClosure, value: false)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline(
                    withPipeliningAssistance: false,
                    withErrorHandling: false,
                    withDecoderLimitConfiguration: configuredDecoderLimits
                ).flatMap {
                    channel.pipeline.addHandlers(
                        AFMChildChannelLifecycleHandler(registry: childChannels),
                        AFMHTTPHandler(router: router, limits: limits)
                    )
                }
            }
    }
}
