//
//  SessionStateLabView.swift
//  FoundationLab
//

import FoundationModels
import SwiftUI

struct SessionStateLabView: View {
    var body: some View {
        #if canImport(FoundationModels, _version: 2.2)
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
            SessionStateLabLiveView()
        } else {
            unavailableView(description: "Session state property wrappers require an OS 27 runtime.")
        }
        #else
        unavailableView(description: "Session state property wrappers require the Xcode 27.3 SDK.")
        #endif
    }

    private func unavailableView(description: LocalizedStringKey) -> some View {
        ContentUnavailableView(
            "Session State Unavailable",
            systemImage: "memorychip",
            description: Text(description)
        )
        .navigationTitle("Session State")
    }
}

#Preview {
    NavigationStack {
        SessionStateLabView()
    }
}
