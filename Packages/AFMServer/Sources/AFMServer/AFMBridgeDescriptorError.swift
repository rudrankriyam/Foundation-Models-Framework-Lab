import Foundation

public enum AFMBridgeDescriptorError: Error, Sendable, Equatable, LocalizedError {
    case invalidPath
    case invalidFileName
    case directoryMissing
    case descriptorMissing
    case unexpectedObject(expected: String, actual: String)
    case ownerMismatch
    case permissionsMismatch(expected: UInt16, actual: UInt16)
    case pathChanged
    case tooManyLinks
    case descriptorTooLarge
    case invalidField(String)
    case unsupportedVersion(Int)
    case encodingFailed
    case decodingFailed
    case posix(operation: String, code: Int32)

    public var errorDescription: String? {
        switch self {
        case .invalidPath:
            "The bridge path must be an absolute path without null bytes."
        case .invalidFileName:
            "The bridge descriptor file name must be a single safe path component."
        case .directoryMissing:
            "The bridge directory does not exist."
        case .descriptorMissing:
            "The bridge connection descriptor does not exist."
        case .unexpectedObject(let expected, let actual):
            "Expected \(expected), but found \(actual)."
        case .ownerMismatch:
            "The bridge filesystem object is not owned by the current user."
        case .permissionsMismatch(let expected, let actual):
            "The bridge filesystem object has mode \(Self.octal(actual)); expected \(Self.octal(expected))."
        case .pathChanged:
            "The bridge filesystem path changed during a safety check."
        case .tooManyLinks:
            "The bridge descriptor has more than one filesystem link."
        case .descriptorTooLarge:
            "The bridge connection descriptor exceeds the safe size limit."
        case .invalidField(let field):
            "The bridge connection descriptor has an invalid \(field) field."
        case .unsupportedVersion(let version):
            "Bridge connection descriptor version \(version) is not supported."
        case .encodingFailed:
            "The bridge connection descriptor could not be encoded."
        case .decodingFailed:
            "The bridge connection descriptor could not be decoded."
        case .posix(let operation, let code):
            "Could not \(operation): \(String(cString: strerror(code)))."
        }
    }

    private static func octal(_ mode: UInt16) -> String {
        String(mode, radix: 8)
    }
}
