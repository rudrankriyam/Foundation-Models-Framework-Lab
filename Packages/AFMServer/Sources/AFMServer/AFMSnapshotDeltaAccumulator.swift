import Foundation

struct AFMSnapshotDeltaAccumulator: Sendable {
    enum AccumulationError: Error, Equatable {
        case nonMonotonicSnapshot
    }

    private(set) var content = ""

    mutating func append(snapshot: String) throws -> String {
        guard snapshot.hasPrefix(content) else {
            throw AccumulationError.nonMonotonicSnapshot
        }
        let delta = String(snapshot.dropFirst(content.count))
        content = snapshot
        return delta
    }
}
