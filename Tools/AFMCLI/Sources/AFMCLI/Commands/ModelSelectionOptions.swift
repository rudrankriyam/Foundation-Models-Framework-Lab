import ArgumentParser
import Foundation
import FoundationLabCore

struct ModelSelectionOptions: ParsableArguments {
    enum Model: String, CaseIterable, ExpressibleByArgument, Encodable {
        case system
        case pcc

        var runtime: FoundationLabModelRuntime {
            switch self {
            case .system:
                return .onDevice
            case .pcc:
                return .privateCloudCompute
            }
        }
    }

    @Option(
        name: [.short, .long],
        help: "Model to inspect (system or pcc). Inspects both when omitted."
    )
    var model: Model?

    var runtimes: [FoundationLabModelRuntime] {
        model.map { [$0.runtime] } ?? FoundationLabModelRuntime.allCases
    }
}
