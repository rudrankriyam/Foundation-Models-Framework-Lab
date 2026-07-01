import Foundation
import FoundationModelsKit

/// Compares tool calls captured from a session transcript with an explicitly declared path.
public struct FoundationLabToolTrajectoryEvaluation: Equatable, Sendable {
    public struct Call: Equatable, Identifiable, Sendable {
        public let id: String
        public let name: String
        public let arguments: String

        public init(id: String, name: String, arguments: String) {
            self.id = id
            self.name = name
            self.arguments = Self.canonicalJSON(arguments)
        }

        private static func canonicalJSON(_ source: String) -> String {
            guard let data = source.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: data),
                  JSONSerialization.isValidJSONObject(object),
                  let normalized = try? JSONSerialization.data(
                    withJSONObject: object,
                    options: [.sortedKeys]
                  ),
                  let result = String(data: normalized, encoding: .utf8) else {
                return source.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            return result
        }
    }

    public struct Mismatch: Equatable, Identifiable, Sendable {
        public enum Kind: Equatable, Sendable {
            case toolName
            case arguments
        }

        public let position: Int
        public let kind: Kind
        public let expected: Call
        public let observed: Call

        public var id: String {
            "\(position)-\(kind)"
        }
    }

    public enum Verdict: Equatable, Sendable {
        case exactMatch
        case differentPath
        case forbiddenCall
    }

    public let expected: [Call]
    public let observed: [Call]
    public let forbiddenCalls: [Call]
    public let missingCalls: [Call]
    public let extraCalls: [Call]
    public let mismatches: [Mismatch]
    public let verdict: Verdict

    public init(
        expected: [Call],
        observed: [Call],
        forbiddenToolNames: Set<String>
    ) {
        self.expected = expected
        self.observed = observed
        self.forbiddenCalls = observed.filter { forbiddenToolNames.contains($0.name) }

        let pairedCount = min(expected.count, observed.count)
        var differences: [Mismatch] = []
        for index in 0..<pairedCount {
            let expectedCall = expected[index]
            let observedCall = observed[index]

            if expectedCall.name != observedCall.name {
                differences.append(
                    Mismatch(
                        position: index,
                        kind: .toolName,
                        expected: expectedCall,
                        observed: observedCall
                    )
                )
            } else if expectedCall.arguments != observedCall.arguments {
                differences.append(
                    Mismatch(
                        position: index,
                        kind: .arguments,
                        expected: expectedCall,
                        observed: observedCall
                    )
                )
            }
        }

        self.mismatches = differences
        self.missingCalls = expected.count > pairedCount ? Array(expected[pairedCount...]) : []
        self.extraCalls = observed.count > pairedCount ? Array(observed[pairedCount...]) : []

        if !forbiddenCalls.isEmpty {
            self.verdict = .forbiddenCall
        } else if differences.isEmpty && missingCalls.isEmpty && extraCalls.isEmpty {
            self.verdict = .exactMatch
        } else {
            self.verdict = .differentPath
        }
    }
}
