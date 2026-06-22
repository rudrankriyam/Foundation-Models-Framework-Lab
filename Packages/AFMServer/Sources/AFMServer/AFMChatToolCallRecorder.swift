import Foundation

actor AFMChatToolCallRecorder {
    struct RecordedCall: Sendable {
        let sequence: Int
        let name: String
        let arguments: String
    }

    struct Snapshot: Sendable {
        let calls: [RecordedCall]
        let exceededLimit: Bool
        let invalidArguments: Bool
    }

    private var calls: [RecordedCall] = []
    private var exceededLimit = false
    private var invalidArguments = false
    private var totalArgumentBytes = 0

    func record(name: String, arguments: String) {
        guard let canonicalArguments = Self.canonicalJSONObject(arguments) else {
            invalidArguments = true
            return
        }
        let argumentBytes = canonicalArguments.utf8.count
        let (newTotal, overflowed) = totalArgumentBytes.addingReportingOverflow(argumentBytes)
        guard calls.count < AFMChatToolLimits.maximumCapturedCalls,
              argumentBytes <= AFMChatToolLimits.maximumArgumentsBytes,
              !overflowed,
              newTotal <= AFMChatToolLimits.maximumTotalArgumentsBytes else {
            exceededLimit = true
            return
        }
        calls.append(
            .init(
                sequence: calls.count,
                name: name,
                arguments: canonicalArguments
            )
        )
        totalArgumentBytes = newTotal
    }

    func snapshot() -> Snapshot {
        Snapshot(
            calls: calls,
            exceededLimit: exceededLimit,
            invalidArguments: invalidArguments
        )
    }

    private static func canonicalJSONObject(_ value: String) -> String? {
        guard let data = value.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              object is [String: Any],
              let canonical = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]) else {
            return nil
        }
        return String(data: canonical, encoding: .utf8)
    }
}
