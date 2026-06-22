import Foundation
import NIOHTTP1

enum AFMHTTPEmission: Sendable {
    case fixed(AFMHTTPResponse)
    case streamHead(status: HTTPResponseStatus, headers: HTTPHeaders)
    case streamBody(Data)
    case streamEnd
}
