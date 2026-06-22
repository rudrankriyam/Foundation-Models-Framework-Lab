import Foundation

public enum AFMChatToolChoice: Sendable, Equatable {
    case auto
    case none
    case required
    case function(name: String)

    var requiresInvocation: Bool {
        switch self {
        case .required, .function:
            true
        case .auto, .none:
            false
        }
    }
}

extension AFMChatToolChoice: Decodable {
    private static let allowedFields: Set<String> = ["type", "function"]

    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer()
        if let string = try? value.decode(String.self) {
            switch string {
            case "auto":
                self = .auto
            case "none":
                self = .none
            case "required":
                self = .required
            default:
                throw AFMChatRequestValidationError.invalidField(
                    parameterPath(decoder.codingPath),
                    message: "tool_choice must be 'auto', 'none', 'required', or a named function."
                )
            }
            return
        }

        let container = try decoder.container(keyedBy: AFMJSONKey.self)
        try rejectUnknownFields(in: container, allowed: Self.allowedFields, decoder: decoder)
        let type = try container.decode(String.self, forKey: .init("type"))
        guard type == "function" else {
            throw AFMChatRequestValidationError.invalidField(
                parameterPath(decoder.codingPath, field: "type"),
                message: "Only named function tool choices are supported."
            )
        }
        let function = try container.decode(NamedFunction.self, forKey: .init("function"))
        self = .function(name: function.name)
    }
}

private struct NamedFunction: Decodable {
    let name: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AFMJSONKey.self)
        try rejectUnknownFields(in: container, allowed: ["name"], decoder: decoder)
        name = try container.decode(String.self, forKey: .init("name"))
    }
}
