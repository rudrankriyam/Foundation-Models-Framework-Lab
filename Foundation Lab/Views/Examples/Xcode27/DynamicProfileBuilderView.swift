//
//  DynamicProfileBuilderView.swift
//  FoundationLab
//
import SwiftUI

struct DynamicProfileBuilderView: View {
    var body: some View {
        #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
            DynamicProfileBuilderLiveView()
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
            systemImage: "slider.horizontal.below.rectangle",
            description: Text("Live dynamic profiles require the Xcode 27 SDK and an OS 27 runtime.")
        )
        .navigationTitle("Session Profile Builder")
    }
}

#Preview {
    NavigationStack {
        DynamicProfileBuilderView()
    }
}
