import Foundation

public enum AFMBridgeEndpoint: Sendable, Codable, Equatable {
    case unixSocket(path: String)
    case loopbackTCP(host: String, port: Int)

    public func validated() throws -> Self {
        switch self {
        case .unixSocket(let path):
            guard path.hasPrefix("/"), !path.contains("\0") else {
                throw AFMBridgeDescriptorError.invalidField("endpoint.unixSocket.path")
            }
        case .loopbackTCP(let host, let port):
            guard host == "127.0.0.1" || host == "::1" else {
                throw AFMBridgeDescriptorError.invalidField("endpoint.loopbackTCP.host")
            }
            guard (1...65_535).contains(port) else {
                throw AFMBridgeDescriptorError.invalidField("endpoint.loopbackTCP.port")
            }
        }
        return self
    }
}
