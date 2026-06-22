import Foundation

public struct AFMBridgeClientConfiguration: Sendable, Equatable {
    public static let defaultRequestTimeout: TimeInterval = 130
    public static let defaultMaximumResponseByteCount = 8 * 1_024 * 1_024

    public let requestTimeout: TimeInterval
    public let maximumResponseByteCount: Int

    public init(
        requestTimeout: TimeInterval = Self.defaultRequestTimeout,
        maximumResponseByteCount: Int = Self.defaultMaximumResponseByteCount
    ) {
        self.requestTimeout = requestTimeout
        self.maximumResponseByteCount = maximumResponseByteCount
    }

    func validated() throws -> Self {
        guard requestTimeout.isFinite, requestTimeout > 0 else {
            throw AFMBridgeClientError.invalidConfiguration(field: "requestTimeout")
        }
        guard maximumResponseByteCount > 0 else {
            throw AFMBridgeClientError.invalidConfiguration(field: "maximumResponseByteCount")
        }
        return self
    }
}
