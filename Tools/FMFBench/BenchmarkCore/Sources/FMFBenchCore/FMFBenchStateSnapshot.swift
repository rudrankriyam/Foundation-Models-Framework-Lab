import Foundation

public struct FMFBenchStateSnapshot: Codable, Equatable, Sendable {
    public let values: [String: FMFBenchJSONValue]

    public init(values: [String: FMFBenchJSONValue]) {
        self.values = values
    }
}
