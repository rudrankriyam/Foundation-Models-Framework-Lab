#if os(macOS)
import Foundation

enum ModelCompareSource: String, Sendable {
    case base
    case adapter

    var displayName: String {
        switch self {
        case .base:
            String(localized: "Base")
        case .adapter:
            String(localized: "Adapter")
        }
    }
}
#endif
