//
//  ReasoningLevelComparisonView.swift
//  FoundationLab
//

import SwiftUI

struct ReasoningLevelComparisonView: View {
    var body: some View {
        #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
            ReasoningLevelComparisonLiveView()
        } else {
            unsupportedView
        }
        #else
        unsupportedView
        #endif
    }

    private var unsupportedView: some View {
        ContentUnavailableView(
            "OS 27 Required",
            systemImage: "brain.head.profile.slash",
            description: Text("Live reasoning levels require the Xcode 27 SDK and an OS 27 runtime.")
        )
        .navigationTitle("Reasoning Levels")
    }
}

#Preview {
    NavigationStack {
        ReasoningLevelComparisonView()
    }
}
