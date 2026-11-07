//
//  DataContentLabView.swift
//  FoundationLab
//

import SwiftUI

struct DataContentLabView: View {
    var body: some View {
        if #available(iOS 27.2, macOS 27.2, visionOS 27.2, *) {
            DataContentLabLiveView()
        } else {
            ContentUnavailableView(
                "OS 27.2 Required",
                systemImage: "shippingbox",
                description: Text("Data attachments and data entries require iOS, macOS, or visionOS 27.2.")
            )
            .navigationTitle("Data Content")
        }
    }
}

#Preview {
    NavigationStack {
        DataContentLabView()
    }
}
