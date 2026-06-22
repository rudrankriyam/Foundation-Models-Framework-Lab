import ArgumentParser
import Foundation

enum AFMJSONDuplicateKeyPreflight {
    static func validate(_ text: String, source: String) throws {
        do {
            var scanner = JSONScanner(text)
            guard let duplicate = try scanner.scanDocument() else {
                return
            }
            throw ValidationError(
                "Could not decode \(source) as JSON: Duplicate object key "
                    + "\(duplicate.key.debugDescription) at JSON pointer '\(duplicate.pointer)'."
            )
        } catch let error as ExcessiveNesting {
            throw ValidationError(
                "Could not decode \(source) as JSON: JSON nesting exceeds the supported depth "
                    + "at JSON pointer '\(error.pointer)'."
            )
        } catch is MalformedJSON {
            // JSONDecoder remains the source of syntax and type diagnostics.
        }
    }
}

private extension AFMJSONDuplicateKeyPreflight {
    struct DuplicateKey {
        let key: String
        let pointer: String
    }

    struct MalformedJSON: Error {}

    struct ExcessiveNesting: Error {
        let pointer: String
    }

    struct JSONScanner {
        private let bytes: [UInt8]
        private var index = 0
        private var firstDuplicate: DuplicateKey?

        init(_ text: String) {
            bytes = Array(text.utf8)
        }

        mutating func scanDocument() throws -> DuplicateKey? {
            skipWhitespace()
            try scanValue(pointer: "", depth: 0)
            skipWhitespace()
            guard index == bytes.count else {
                throw MalformedJSON()
            }
            return firstDuplicate
        }

        private mutating func scanValue(pointer: String, depth: Int) throws {
            guard depth < 256 else {
                throw ExcessiveNesting(pointer: pointer.isEmpty ? "/" : pointer)
            }
            skipWhitespace()
            guard let byte = currentByte else {
                throw MalformedJSON()
            }

            switch byte {
            case ascii("{"):
                try scanObject(pointer: pointer, depth: depth)
            case ascii("["):
                try scanArray(pointer: pointer, depth: depth)
            case ascii("\""):
                _ = try scanString()
            case ascii("t"):
                try scanLiteral("true")
            case ascii("f"):
                try scanLiteral("false")
            case ascii("n"):
                try scanLiteral("null")
            case ascii("-"), ascii("0")...ascii("9"):
                try scanNumber()
            default:
                throw MalformedJSON()
            }
        }

        private mutating func scanObject(pointer: String, depth: Int) throws {
            try consume(ascii("{"))
            skipWhitespace()
            if consumeIfPresent(ascii("}")) {
                return
            }

            var keys: Set<String> = []
            while true {
                skipWhitespace()
                let key = try scanString()
                let keyPointer = afmJSONPointer(appending: key, to: pointer)
                if !keys.insert(key).inserted, firstDuplicate == nil {
                    firstDuplicate = DuplicateKey(key: key, pointer: keyPointer)
                }

                skipWhitespace()
                try consume(ascii(":"))
                try scanValue(pointer: keyPointer, depth: depth + 1)
                skipWhitespace()
                if consumeIfPresent(ascii("}")) {
                    return
                }
                try consume(ascii(","))
            }
        }

        private mutating func scanArray(pointer: String, depth: Int) throws {
            try consume(ascii("["))
            skipWhitespace()
            if consumeIfPresent(ascii("]")) {
                return
            }

            var elementIndex = 0
            while true {
                try scanValue(
                    pointer: afmJSONPointer(appending: String(elementIndex), to: pointer),
                    depth: depth + 1
                )
                elementIndex += 1
                skipWhitespace()
                if consumeIfPresent(ascii("]")) {
                    return
                }
                try consume(ascii(","))
            }
        }

        private mutating func scanString() throws -> String {
            let start = index
            try consume(ascii("\""))

            while let byte = currentByte {
                switch byte {
                case ascii("\""):
                    index += 1
                    return try decodedString(startingAt: start)
                case ascii("\\"):
                    try scanEscape()
                case 0x00...0x1F:
                    throw MalformedJSON()
                default:
                    index += 1
                }
            }
            throw MalformedJSON()
        }

        private func decodedString(startingAt start: Int) throws -> String {
            let data = Data(bytes[start..<index])
            do {
                return try JSONDecoder().decode(String.self, from: data)
            } catch {
                throw MalformedJSON()
            }
        }

        private mutating func scanEscape() throws {
            index += 1
            guard let escaped = currentByte else {
                throw MalformedJSON()
            }
            guard escaped == ascii("u") else {
                guard escapeBytes.contains(escaped) else {
                    throw MalformedJSON()
                }
                index += 1
                return
            }

            index += 1
            for _ in 0..<4 {
                guard let hexadecimal = currentByte, isHexadecimal(hexadecimal) else {
                    throw MalformedJSON()
                }
                index += 1
            }
        }

        private mutating func scanNumber() throws {
            _ = consumeIfPresent(ascii("-"))
            guard let firstDigit = currentByte else {
                throw MalformedJSON()
            }
            if firstDigit == ascii("0") {
                index += 1
                if let next = currentByte, isDigit(next) {
                    throw MalformedJSON()
                }
            } else {
                guard isNonzeroDigit(firstDigit) else {
                    throw MalformedJSON()
                }
                consumeDigits()
            }

            if consumeIfPresent(ascii(".")) {
                guard let digit = currentByte, isDigit(digit) else {
                    throw MalformedJSON()
                }
                consumeDigits()
            }
            if consumeIfPresent(ascii("e")) || consumeIfPresent(ascii("E")) {
                _ = consumeIfPresent(ascii("+")) || consumeIfPresent(ascii("-"))
                guard let digit = currentByte, isDigit(digit) else {
                    throw MalformedJSON()
                }
                consumeDigits()
            }
        }

        private mutating func scanLiteral(_ literal: StaticString) throws {
            for byte in literal.withUTF8Buffer({ Array($0) }) {
                try consume(byte)
            }
        }

        private mutating func consumeDigits() {
            while let byte = currentByte, isDigit(byte) {
                index += 1
            }
        }

        private mutating func skipWhitespace() {
            while let byte = currentByte, whitespaceBytes.contains(byte) {
                index += 1
            }
        }

        private mutating func consume(_ byte: UInt8) throws {
            guard consumeIfPresent(byte) else {
                throw MalformedJSON()
            }
        }

        private mutating func consumeIfPresent(_ byte: UInt8) -> Bool {
            guard currentByte == byte else {
                return false
            }
            index += 1
            return true
        }

        private var currentByte: UInt8? {
            index < bytes.count ? bytes[index] : nil
        }
    }

    static func ascii(_ character: Character) -> UInt8 {
        character.asciiValue ?? 0
    }

    static func isDigit(_ byte: UInt8) -> Bool {
        ascii("0")...ascii("9") ~= byte
    }

    static func isNonzeroDigit(_ byte: UInt8) -> Bool {
        ascii("1")...ascii("9") ~= byte
    }

    static func isHexadecimal(_ byte: UInt8) -> Bool {
        isDigit(byte)
            || ascii("a")...ascii("f") ~= byte
            || ascii("A")...ascii("F") ~= byte
    }

    static let whitespaceBytes: Set<UInt8> = [0x20, 0x09, 0x0A, 0x0D]
    static let escapeBytes: Set<UInt8> = [
        ascii("\""), ascii("\\"), ascii("/"), ascii("b"), ascii("f"), ascii("n"), ascii("r"), ascii("t")
    ]
}
