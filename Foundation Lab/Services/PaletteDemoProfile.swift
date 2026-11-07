//
//  PaletteDemoProfile.swift
//  FoundationLab
//

import FoundationModels

@available(iOS 27.2, macOS 27.2, visionOS 27.2, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct PaletteDemoProfile: LanguageModelSession.DynamicProfile {
    let onDataEntry: @MainActor @Sendable (Transcript.DataEntry) throws -> Void

    var body: some LanguageModelSession.DynamicProfile {
        #if canImport(FoundationModels, _version: 2.2)
        if #available(iOS 27.3, macOS 27.3, visionOS 27.3, *) {
            profile
                .onDataEntry { entry in
                    try onDataEntry(entry)
                }
        } else {
            profile
        }
        #else
        profile
        #endif
    }

    private var profile: some LanguageModelSession.DynamicProfile {
        LanguageModelSession.Profile {
            Instructions("Return the complement of the attached color swatch.")
        }
        .model(PaletteDemoLanguageModel())
    }
}
