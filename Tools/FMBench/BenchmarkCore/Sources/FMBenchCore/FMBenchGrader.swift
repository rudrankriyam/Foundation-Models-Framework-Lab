import Foundation

public struct FMBenchCheckResult: Codable, Sendable {
    public let label: String
    public let passed: Bool
    public let detail: String?
}

public struct FMBenchGrade: Codable, Sendable {
    public let checks: [FMBenchCheckResult]

    public var passedChecks: Int {
        checks.count(where: \.passed)
    }

    public var totalChecks: Int {
        checks.count
    }

    public var score: Double {
        guard !checks.isEmpty else { return 1 }
        return Double(passedChecks) / Double(checks.count)
    }

    public var promptPassed: Bool {
        checks.allSatisfy(\.passed)
    }
}

public struct FMBenchToolCall: Codable, Sendable {
    public let name: String
    public let arguments: [String: FMBenchJSONValue]

    public init(name: String, arguments: [String: FMBenchJSONValue]) {
        self.name = name
        self.arguments = arguments
    }
}

public enum FMBenchGrader {
    public static func grade(
        response: String,
        checks: [FMBenchCheck],
        toolCalls: [FMBenchToolCall] = []
    ) -> FMBenchGrade {
        let json = parseJSONObject(from: response)
        let results = checks.map { check in
            evaluate(check, response: response, json: json, toolCalls: toolCalls)
        }
        return FMBenchGrade(checks: results)
    }

    private static func evaluate(
        _ check: FMBenchCheck,
        response: String,
        json: Any?,
        toolCalls: [FMBenchToolCall]
    ) -> FMBenchCheckResult {
        let passed: Bool
        let detail: String?

        switch check {
        case .contains(let value):
            passed = response.localizedCaseInsensitiveContains(value)
            detail = passed ? nil : "Missing required text."
        case .excludes(let value):
            passed = !response.localizedCaseInsensitiveContains(value)
            detail = passed ? nil : "Found forbidden text."
        case .minimumWords(let minimum):
            let count = wordCount(response)
            passed = count >= minimum
            detail = passed ? nil : "Found \(count) words."
        case .maximumWords(let maximum):
            let count = wordCount(response)
            passed = count <= maximum
            detail = passed ? nil : "Found \(count) words."
        case .jsonEquals(let path, let expected):
            let actual = value(at: path, in: json)
            passed = matches(actual, expected: expected)
            detail = passed ? nil : "Actual value: \(describe(actual))."
        case .jsonContains(let path, let expectedValues):
            let actual = value(at: path, in: json)
            let flattened = strings(from: actual)
            passed = expectedValues.allSatisfy { expected in
                flattened.contains { $0.localizedCaseInsensitiveContains(expected) }
            }
            detail = passed ? nil : "Actual values: \(flattened.joined(separator: ", "))."
        case .toolCalled(let name):
            passed = toolCalls.contains { $0.name == name }
            detail =
                passed ? nil : "Observed tools: \(toolCalls.map(\.name).joined(separator: ", "))."
        case .toolArgumentEquals(let tool, let argument, let expected):
            let actual = toolCalls.first(where: { $0.name == tool })?.arguments[argument]
            passed = actual == expected
            detail = passed ? nil : "Actual value: \(String(describing: actual))."
        }

        return FMBenchCheckResult(label: check.label, passed: passed, detail: detail)
    }

    private static func parseJSONObject(from response: String) -> Any? {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidate: String
        if trimmed.hasPrefix("```"), let firstLineEnd = trimmed.firstIndex(of: "\n") {
            let body = trimmed[trimmed.index(after: firstLineEnd)...]
            candidate = body.replacing("```", with: "").trimmingCharacters(
                in: .whitespacesAndNewlines)
        } else {
            candidate = trimmed
        }

        guard let data = candidate.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data)
    }

    private static func value(at path: String, in json: Any?) -> Any? {
        path.split(separator: ".").reduce(json) { current, component in
            (current as? [String: Any])?[String(component)]
        }
    }

    private static func matches(_ actual: Any?, expected: FMBenchJSONValue) -> Bool {
        switch expected {
        case .string(let value):
            guard let actual = actual as? String else { return false }
            return actual.compare(value, options: [.caseInsensitive, .diacriticInsensitive])
                == .orderedSame
        case .integer(let value):
            return (actual as? NSNumber)?.intValue == value
        case .number(let value):
            guard let number = actual as? NSNumber else { return false }
            return abs(number.doubleValue - value) < 0.000_001
        case .boolean(let value):
            return (actual as? NSNumber)?.boolValue == value
        }
    }

    private static func strings(from value: Any?) -> [String] {
        if let strings = value as? [String] {
            return strings
        }
        if let dictionaries = value as? [[String: Any]] {
            return dictionaries.flatMap { dictionary in
                dictionary.values.compactMap { $0 as? String }
            }
        }
        if let string = value as? String {
            return [string]
        }
        return []
    }

    private static func wordCount(_ text: String) -> Int {
        text.split(whereSeparator: \.isWhitespace).count
    }

    private static func describe(_ value: Any?) -> String {
        value.map { String(describing: $0) } ?? "missing"
    }
}
