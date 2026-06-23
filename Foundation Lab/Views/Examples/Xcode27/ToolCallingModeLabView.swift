//
//  ToolCallingModeLabView.swift
//  FoundationLab
//

import SwiftUI

struct ToolCallingModeLabView: View {
    var body: some View {
        #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
            ToolCallingModeLabLiveView()
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
            systemImage: "wrench.and.screwdriver.fill",
            description: Text("Live tool-calling modes require the Xcode 27 SDK and an OS 27 runtime.")
        )
        .navigationTitle("Tool Calling Modes")
    }
}

#Preview {
    NavigationStack {
        ToolCallingModeLabView()
    }
}
