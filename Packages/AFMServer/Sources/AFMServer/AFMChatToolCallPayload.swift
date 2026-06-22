import Foundation

struct AFMChatToolCallPayload: Encodable {
    struct Function: Encodable {
        let name: String
        let arguments: String
    }

    let id: String
    let type = "function"
    let function: Function

    init(_ call: AFMChatToolCall) {
        id = call.id
        function = .init(name: call.name, arguments: call.arguments)
    }
}

struct AFMChatToolCallDeltaPayload: Encodable {
    struct Function: Encodable {
        let name: String
        let arguments: String
    }

    let index: Int
    let id: String
    let type = "function"
    let function: Function

    init(index: Int, call: AFMChatToolCall) {
        self.index = index
        id = call.id
        function = .init(name: call.name, arguments: call.arguments)
    }
}
