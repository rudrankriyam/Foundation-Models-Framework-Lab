import Foundation

public enum FMFBenchJSONValue: Codable, Equatable, Sendable {
    case string(String)
    case integer(Int)
    case number(Double)
    case boolean(Bool)
}

public enum FMFBenchCheck: Codable, Sendable {
    case contains(String)
    case containsAny([String])
    case excludes(String)
    case minimumWords(Int)
    case maximumWords(Int)
    case jsonEquals(path: String, value: FMFBenchJSONValue)
    case jsonContains(path: String, values: [String])
    case jsonContainsAny(path: String, groups: [[String]])
    case toolCalled(String)
    case toolArgumentEquals(tool: String, argument: String, value: FMFBenchJSONValue)
    case toolArgumentContains(tool: String, argument: String, value: String)
    case toolCallSequence([String], allowsAdditionalCalls: Bool)
    case toolNotCalled(String)
    case stateEquals(path: String, value: FMFBenchJSONValue)
    case stateContains(path: String, value: String)

    public var label: String {
        switch self {
        case .contains(let value):
            return "Contains “\(value)”"
        case .containsAny(let values):
            return "Contains any of \(values.joined(separator: ", "))"
        case .excludes(let value):
            return "Excludes “\(value)”"
        case .minimumWords(let count):
            return "At least \(count) words"
        case .maximumWords(let count):
            return "At most \(count) words"
        case .jsonEquals(let path, let value):
            return "\(path) equals \(value.description)"
        case .jsonContains(let path, let values):
            return "\(path) contains \(values.joined(separator: ", "))"
        case .jsonContainsAny(let path, let groups):
            let labels = groups.map { $0.joined(separator: " or ") }
            return "\(path) contains alternatives \(labels.joined(separator: ", "))"
        case .toolCalled(let name):
            return "Calls \(name)"
        case .toolArgumentEquals(let tool, let argument, let value):
            return "\(tool).\(argument) equals \(value.description)"
        case .toolArgumentContains(let tool, let argument, let value):
            return "\(tool).\(argument) contains \(value)"
        case .toolCallSequence(let tools, let allowsAdditionalCalls):
            let qualifier = allowsAdditionalCalls ? "in order" : "exactly in order"
            return "Calls \(tools.joined(separator: " → ")) \(qualifier)"
        case .toolNotCalled(let name):
            return "Does not call \(name)"
        case .stateEquals(let path, let value):
            return "Final state \(path) equals \(value.description)"
        case .stateContains(let path, let value):
            return "Final state \(path) contains \(value)"
        }
    }

    public var isToolCheck: Bool {
        switch self {
        case .toolCalled, .toolArgumentEquals, .toolArgumentContains, .toolCallSequence,
            .toolNotCalled:
            true
        case .contains, .containsAny, .excludes, .minimumWords, .maximumWords, .jsonEquals,
            .jsonContains, .jsonContainsAny, .stateEquals, .stateContains:
            false
        }
    }
}

extension FMFBenchJSONValue {
    fileprivate var description: String {
        switch self {
        case .string(let value):
            value
        case .integer(let value):
            String(value)
        case .number(let value):
            String(value)
        case .boolean(let value):
            String(value)
        }
    }
}
