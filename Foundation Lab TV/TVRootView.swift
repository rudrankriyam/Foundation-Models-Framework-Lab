//
//  TVRootView.swift
//  Foundation Lab TV
//

import SwiftUI

struct TVRootView: View {
    var body: some View {
        #if canImport(FoundationModels, _version: 2.2)
        if #available(tvOS 27.3, *) {
            TVLabView()
        } else {
            ContentUnavailableView(
                "Requires tvOS 27.3",
                systemImage: "appletv",
                description: Text("Foundation Models is available on Apple TV starting with tvOS 27.3.")
            )
        }
        #else
        ContentUnavailableView(
            "Foundation Models Unavailable",
            systemImage: "hammer",
            description: Text("This build lacks tvOS Foundation Models because it was built with an SDK before Xcode 27.3.")
        )
        #endif
    }
}
