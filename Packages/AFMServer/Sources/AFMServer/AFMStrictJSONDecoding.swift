import Foundation

struct AFMJSONKey: CodingKey, Hashable {
    let stringValue: String
    let intValue: Int?

    init(_ stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }

    init?(stringValue: String) {
        self.init(stringValue)
    }

    init?(intValue: Int) {
        stringValue = String(intValue)
        self.intValue = intValue
    }
}

func rejectUnknownFields(
    in container: KeyedDecodingContainer<AFMJSONKey>,
    allowed: Set<String>,
    decoder: Decoder
) throws {
    if let unknownKey = container.allKeys
        .filter({ !allowed.contains($0.stringValue) })
        .sorted(by: { $0.stringValue < $1.stringValue })
        .first {
        throw AFMChatRequestValidationError.unknownField(
            parameterPath(decoder.codingPath, field: unknownKey.stringValue)
        )
    }
}

func rejectUnsupportedFields(
    _ fields: [String],
    in container: KeyedDecodingContainer<AFMJSONKey>,
    decoder: Decoder
) throws {
    for field in fields {
        let key = AFMJSONKey(field)
        if container.contains(key), try !container.decodeNil(forKey: key) {
            throw AFMChatRequestValidationError.unsupportedField(
                parameterPath(decoder.codingPath, field: field)
            )
        }
    }
}

func parameterPath(_ codingPath: [any CodingKey], field: String? = nil) -> String {
    var keys = codingPath
    if let field {
        keys.append(AFMJSONKey(field))
    }
    return keys.reduce(into: "") { result, key in
        if let index = key.intValue {
            result += "[\(index)]"
        } else if result.isEmpty {
            result = key.stringValue
        } else {
            result += ".\(key.stringValue)"
        }
    }
}

extension AFMChatRequestValidationError {
    init(decodingError: DecodingError) {
        switch decodingError {
        case .keyNotFound(let key, let context):
            self = .missingField(parameterPath(context.codingPath, field: key.stringValue))
        case .typeMismatch(_, let context), .valueNotFound(_, let context):
            let parameter = parameterPath(context.codingPath)
            if parameter.isEmpty {
                self = .malformedJSON
            } else {
                self = .invalidField(
                    parameter,
                    message: "Field '\(parameter)' has an invalid JSON type."
                )
            }
        case .dataCorrupted(let context):
            let parameter = parameterPath(context.codingPath)
            if parameter.isEmpty {
                self = .malformedJSON
            } else {
                self = .invalidField(parameter, message: "Field '\(parameter)' contains invalid data.")
            }
        @unknown default:
            self = .malformedJSON
        }
    }
}
