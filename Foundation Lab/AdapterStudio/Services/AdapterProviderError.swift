#if os(macOS)
import Foundation

enum AdapterProviderError: LocalizedError {
    case directoryCreationFailed(String)
    case directoryNotWritable(String)
    case invalidFileExtension(URL)
    case copyFailed(String)
    case loadFailed(String)
    case fileTooLarge(UInt64)
    case sizeCalculationFailed(URL, String)

    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed(let message):
            String(localized: "Failed to prepare the adapter directory: \(message)")
        case .directoryNotWritable(let path):
            String(localized: "The adapter directory is not writable: \(path)")
        case .invalidFileExtension(let url):
            String(localized: "\"\(url.lastPathComponent)\" is not an .fmadapter package.")
        case .copyFailed(let message):
            String(localized: "Could not import the adapter: \(message)")
        case .loadFailed(let message):
            String(localized: "Could not load the adapter: \(message)")
        case .fileTooLarge(let size):
            String(
                localized: "The adapter is too large (\(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)))."
            )
        case .sizeCalculationFailed(let url, let message):
            String(localized: "Could not measure \"\(url.lastPathComponent)\": \(message)")
        }
    }
}
#endif
