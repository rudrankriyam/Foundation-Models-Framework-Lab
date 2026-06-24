//
//  LocalReleaseRecordQuery.swift
//  FoundationLab
//

#if compiler(>=6.4)
import FoundationModels
import FoundationModelsKit

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@Generable
struct LocalReleaseRecordQuery: RuntimeCompatibleGenerable {
    @Guide(description: "The record identifier. Use foundation-lab for this experiment.")
    let recordID: String
}
#endif
