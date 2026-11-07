//
//  ImageInputPlaygroundView.swift
//  FoundationLab
//

import SwiftUI

struct ImageInputPlaygroundView: View {
    @ViewBuilder
    var body: some View {
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
            ImageInputLiveView()
        } else {
            ImageInputUnavailableView(
                title: String(localized: "OS 27 Required"),
                message: String(localized: "Image attachments require iOS, macOS, or visionOS 27.")
            )
        }
    }
}

#Preview {
    NavigationStack {
        ImageInputPlaygroundView()
    }
}
