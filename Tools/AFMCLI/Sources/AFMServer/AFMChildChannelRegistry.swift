import Foundation
import NIOCore
import NIOHTTP1

final class AFMChildChannelRegistry: @unchecked Sendable {
    private let lock = NSLock()
    private var channels: [ObjectIdentifier: any Channel] = [:]
    private var isShuttingDown = false

    func insert(_ channel: any Channel) {
        lock.lock()
        if isShuttingDown {
            lock.unlock()
            channel.close(promise: nil)
            return
        }
        channels[ObjectIdentifier(channel)] = channel
        lock.unlock()
    }

    func remove(_ channel: any Channel) {
        lock.lock()
        channels.removeValue(forKey: ObjectIdentifier(channel))
        lock.unlock()
    }

    func beginShutdown() -> [any Channel] {
        lock.lock()
        isShuttingDown = true
        let openChannels = Array(channels.values)
        channels.removeAll()
        lock.unlock()
        return openChannels
    }
}

final class AFMChildChannelLifecycleHandler: ChannelInboundHandler, @unchecked Sendable {
    typealias InboundIn = HTTPServerRequestPart

    private let registry: AFMChildChannelRegistry

    init(registry: AFMChildChannelRegistry) {
        self.registry = registry
    }

    func channelActive(context: ChannelHandlerContext) {
        registry.insert(context.channel)
        context.fireChannelActive()
    }

    func channelInactive(context: ChannelHandlerContext) {
        registry.remove(context.channel)
        context.fireChannelInactive()
    }
}
