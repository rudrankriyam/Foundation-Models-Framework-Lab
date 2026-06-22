import Foundation
import NIOHTTP1

enum AFMHostPolicy {
    static func isLoopbackBinding(_ host: String) -> Bool {
        let normalized = host.lowercased()
        if normalized == "localhost" || normalized == "::1" || normalized == "[::1]" {
            return true
        }

        let components = normalized.split(separator: ".", omittingEmptySubsequences: false)
        guard components.count == 4,
              components[0] == "127",
              components.dropFirst().allSatisfy({ UInt8($0) != nil }) else {
            return false
        }
        return true
    }

    static func validatesLoopbackHostHeader(_ headers: HTTPHeaders, bindingHost: String) -> Bool {
        let values = headers["host"]
        guard values.count == 1, let host = normalizedHost(from: values[0]) else {
            return false
        }

        let allowed = [bindingHost, "localhost", "127.0.0.1", "::1"]
            .map { normalizedHost(from: $0) }
        return allowed.contains(host)
    }

    private static func normalizedHost(from value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("[") {
            guard let closingBracket = trimmed.firstIndex(of: "]") else { return nil }
            let addressStart = trimmed.index(after: trimmed.startIndex)
            let address = String(trimmed[addressStart..<closingBracket])
            let suffix = trimmed[trimmed.index(after: closingBracket)...]
            guard suffix.isEmpty || (suffix.first == ":" && UInt16(suffix.dropFirst()) != nil) else {
                return nil
            }
            return address
        }

        let colonCount = trimmed.reduce(into: 0) { count, character in
            if character == ":" { count += 1 }
        }
        if colonCount == 1, let separator = trimmed.lastIndex(of: ":") {
            let hostname = String(trimmed[..<separator])
            guard !hostname.isEmpty, UInt16(trimmed[trimmed.index(after: separator)...]) != nil else {
                return nil
            }
            return hostname
        }

        return trimmed
    }
}
