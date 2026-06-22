import Foundation
import NIOHTTP1

struct AFMHTTPResponse {
    let status: HTTPResponseStatus
    let headers: HTTPHeaders
    let body: Data

    init(status: HTTPResponseStatus, headers: HTTPHeaders = .init(), body: Data) {
        self.status = status
        self.headers = headers
        self.body = body
    }

    static func json<T: Encodable>(
        status: HTTPResponseStatus = .ok,
        headers: HTTPHeaders = .init(),
        body: T
    ) -> Self {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(body) else {
            return internalEncodingFailure()
        }
        return .init(status: status, headers: headers, body: data)
    }

    static func apiError(
        status: HTTPResponseStatus,
        message: String,
        code: String,
        type: String = "invalid_request_error",
        headers: HTTPHeaders = .init()
    ) -> Self {
        json(
            status: status,
            headers: headers,
            body: AFMErrorEnvelope(
                error: .init(message: message, type: type, parameter: nil, code: code)
            )
        )
    }

    private static func internalEncodingFailure() -> Self {
        let body = Data(
            #"{"error":{"code":"internal_error","message":"The response could not be encoded.","param":null,"type":"server_error"}}"#.utf8
        )
        return .init(status: .internalServerError, body: body)
    }
}

private struct AFMErrorEnvelope: Encodable {
    struct Detail: Encodable {
        let message: String
        let type: String
        let parameter: String?
        let code: String

        enum CodingKeys: String, CodingKey {
            case message
            case type
            case parameter = "param"
            case code
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(message, forKey: .message)
            try container.encode(type, forKey: .type)
            try container.encodeNil(forKey: .parameter)
            try container.encode(code, forKey: .code)
        }
    }

    let error: Detail
}
