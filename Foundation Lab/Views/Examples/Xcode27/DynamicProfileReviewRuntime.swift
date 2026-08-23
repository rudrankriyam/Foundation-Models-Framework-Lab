//
//  DynamicProfileReviewRuntime.swift
//  FoundationLab
//

#if compiler(>=6.4)
import Foundation

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
nonisolated enum DynamicProfileReviewRuntime: String, CaseIterable, Identifiable, Sendable {
    case onDevice
    case privateCloudCompute

    var id: String { rawValue }

    var title: String {
        switch self {
        case .onDevice: String(localized: "On Device")
        case .privateCloudCompute: String(localized: "Private Cloud Compute")
        }
    }

    var apiName: String {
        switch self {
        case .onDevice: "SystemLanguageModel"
        case .privateCloudCompute: "PrivateCloudComputeLanguageModel"
        }
    }

    var unavailableTitle: String {
        switch self {
        case .onDevice: String(localized: "System model unavailable")
        case .privateCloudCompute: String(localized: "Private Cloud Compute unavailable")
        }
    }
}
#endif
