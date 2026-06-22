import Foundation
import Testing
@testable import AFMServer

@Test("Bridge bearer tokens are unique 32-byte base64url values")
func bridgeBearerTokenEntropyAndShape() throws {
    let tokens = try (0..<128).map { _ in try AFMBridgeBearerTokenGenerator.generate() }

    #expect(Set(tokens).count == tokens.count)
    for token in tokens {
        #expect(token.utf8.count == 43)
        #expect(token.utf8.allSatisfy { byte in
            switch byte {
            case 45, 48...57, 65...90, 95, 97...122:
                true
            default:
                false
            }
        })
        let standardBase64 = token
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/") + "="
        #expect(Data(base64Encoded: standardBase64)?.count == 32)
    }
}
