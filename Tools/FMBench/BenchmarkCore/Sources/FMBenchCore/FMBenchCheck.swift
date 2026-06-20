import Foundation

public enum FMBenchJSONValue: Codable, Equatable, Sendable {
    case string(String)
    case integer(Int)
    case number(Double)
    case boolean(Bool)
}

public enum FMBenchCheck: Codable, Sendable {
    case contains(String)
    case excludes(String)
    case minimumWords(Int)
    case maximumWords(Int)
    case jsonEquals(path: String, value: FMBenchJSONValue)
    case jsonContains(path: String, values: [String])
    case toolCalled(String)
    case toolArgumentEquals(tool: String, argument: String, value: FMBenchJSONValue)

    public var label: String {
        switch self {
        case .contains(let value):
            "Contains “\(value)”"
        case .excludes(let value):
            "Excludes “\(value)”"
        case .minimumWords(let count):
            "At least \(count) words"
        case .maximumWords(let count):
            "At most \(count) words"
        case .jsonEquals(let path, let value):
            "\(path) equals \(value.description)"
        case .jsonContains(let path, let values):
            "\(path) contains \(values.joined(separator: ", "))"
        case .toolCalled(let name):
            "Calls \(name)"
        case .toolArgumentEquals(let tool, let argument, let value):
            "\(tool).\(argument) equals \(value.description)"
        }
    }

    public var isToolCheck: Bool {
        switch self {
        case .toolCalled, .toolArgumentEquals:
            true
        default:
            false
        }
    }
}

extension FMBenchJSONValue {
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
