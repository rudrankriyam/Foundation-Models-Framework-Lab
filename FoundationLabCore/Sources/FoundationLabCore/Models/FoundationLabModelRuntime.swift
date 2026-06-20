import Foundation

public enum FoundationLabModelRuntime: String, CaseIterable, Sendable, Hashable, Codable {
    case onDevice
    case privateCloudCompute

    public var displayName: String {
        switch self {
        case .onDevice:
            return String(localized: "On Device")
        case .privateCloudCompute:
            return String(localized: "Private Cloud Compute")
        }
    }

    public var shortName: String {
        switch self {
        case .onDevice:
            return String(localized: "On-device")
        case .privateCloudCompute:
            return "PCC"
        }
    }

    public var systemImage: String {
        switch self {
        case .onDevice:
            return "iphone"
        case .privateCloudCompute:
            return "icloud"
        }
    }

    public var requiresNewSessionOnSelection: Bool {
        true
    }
}
