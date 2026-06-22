import Foundation
import FoundationLabCore

struct RuntimeDryRunPayload: Encodable {
    let status = "dry_run"
    let command: String
    let model: String?
}

func modelIdentifier(for runtime: FoundationLabModelRuntime) -> String {
    runtime == .onDevice ? "system" : "pcc"
}

func modelDisplayName(for runtime: FoundationLabModelRuntime) -> String {
    runtime == .onDevice ? "System" : "PCC"
}

func runtimeReasonDescription(_ reason: ModelRuntimeUnavailableReason?) -> String {
    switch reason {
    case .deviceNotEligible:
        return "device is not eligible"
    case .appleIntelligenceNotEnabled:
        return "Apple Intelligence is disabled"
    case .modelNotReady:
        return "model assets are not ready"
    case .systemNotReady:
        return "PCC is not ready"
    case .unsupportedOperatingSystem:
        return "requires macOS 27 or later"
    case .unsupportedToolchain:
        return "requires an Xcode 27-built afm"
    case .missingEntitlement:
        return "current process lacks the managed PCC entitlement"
    case .unknown, .none:
        return "unknown reason"
    }
}
