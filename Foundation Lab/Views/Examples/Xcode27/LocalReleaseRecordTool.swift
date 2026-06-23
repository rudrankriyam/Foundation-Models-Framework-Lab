//
//  LocalReleaseRecordTool.swift
//  FoundationLab
//

#if compiler(>=6.4)
import Foundation
import FoundationModels

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct LocalReleaseRecordTool: Tool {
    let name = "read_local_release_record"
    let description = "Reads a deterministic, read-only sample record bundled with Foundation Lab."
    let recorder: LocalReleaseRecordExecutionRecorder

    @concurrent
    func call(arguments: LocalReleaseRecordQuery) async throws -> String {
        let recordID = arguments.recordID.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let output: String

        if recordID == "foundation-lab" {
            output = "Local fixture foundation-lab: macOS generic build passed; iOS generic build passed; review status is ready."
        } else {
            output = "Local fixture has no record with identifier \(arguments.recordID)."
        }

        await recorder.record(output)
        return output
    }
}
#endif
