//
//  SpotlightRAGExplorerView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct SpotlightRAGExplorerView: View {
    var body: some View {
        #if arch(arm64)
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
            SpotlightRAGLiveView()
        } else {
            SpotlightRAGUnavailableView(
                message: String(localized: "The live Spotlight RAG lab requires an OS 27 runtime.")
            )
        }
        #else
        SpotlightRAGUnavailableView(
            message: String(localized: "The live Spotlight RAG lab requires Apple silicon.")
        )
        #endif
    }
}

#Preview {
    NavigationStack {
        SpotlightRAGExplorerView()
    }
}
