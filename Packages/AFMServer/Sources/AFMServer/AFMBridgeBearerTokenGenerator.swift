import Foundation
import Security

public enum AFMBridgeBearerTokenGenerator {
    static let encodedByteCount = 43
    private static let randomByteCount = 32

    public static func generate() throws -> String {
        var bytes = [UInt8](repeating: 0, count: randomByteCount)
        let status = bytes.withUnsafeMutableBytes { buffer in
            SecRandomCopyBytes(kSecRandomDefault, buffer.count, buffer.baseAddress!)
        }
        guard status == errSecSuccess else {
            throw AFMBridgeTokenError.randomGenerationFailed(status)
        }

        return Data(bytes)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
