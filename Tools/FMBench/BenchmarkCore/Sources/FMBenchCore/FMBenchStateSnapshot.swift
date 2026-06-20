import Foundation

public struct FMBenchStateSnapshot: Codable, Equatable, Sendable {
    public let values: [String: FMBenchJSONValue]

    public init(values: [String: FMBenchJSONValue]) {
        self.values = values
    }
}
