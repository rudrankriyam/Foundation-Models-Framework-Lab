//
//  ImageInputPlaygroundView.swift
//  FoundationLab
//

import SwiftUI

struct ImageInputPlaygroundView: View {
    @ViewBuilder
    var body: some View {
        #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
            ImageInputLiveView()
        } else {
            ImageInputUnavailableView(
                title: String(localized: "OS 27 Required"),
                message: String(localized: "Image attachments require iOS, macOS, or visionOS 27.")
            )
        }
        #else
        ImageInputUnavailableView(
            title: String(localized: "Xcode 27 Required"),
            message: String(localized: "Build Foundation Lab with the Xcode 27 SDK to run image attachment requests.")
        )
        #endif
    }
}

#Preview {
    NavigationStack {
        ImageInputPlaygroundView()
    }
}
