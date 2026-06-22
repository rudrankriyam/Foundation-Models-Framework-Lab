import Foundation

struct AFMServerSentEventEncoder: Sendable {
    private let encoder: JSONEncoder

    init() {
        encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
    }

    func event<T: Encodable>(_ value: T) throws -> Data {
        event(json: try encoder.encode(value))
    }

    func event(json: Data) -> Data {
        var data = Data("data: ".utf8)
        data.append(json)
        data.append(Data("\n\n".utf8))
        return data
    }

    var done: Data {
        Data("data: [DONE]\n\n".utf8)
    }
}
