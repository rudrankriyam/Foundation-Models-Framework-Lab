//
//  SpotlightRAGExplorerView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct SpotlightRAGExplorerView: View {
    var body: some View {
        #if compiler(>=6.4) && arch(arm64)
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
            SpotlightRAGLiveView()
        } else {
            SpotlightRAGUnavailableView(
                message: String(localized: "The live Spotlight RAG lab requires an OS 27 runtime.")
            )
        }
        #elseif compiler(>=6.4)
        SpotlightRAGUnavailableView(
            message: String(localized: "The live Spotlight RAG lab requires Apple silicon.")
        )
        #else
        SpotlightRAGUnavailableView(
            message: String(localized: "The live Spotlight RAG lab requires the Xcode 27 SDK.")
        )
        #endif
    }
}

#Preview {
    NavigationStack {
        SpotlightRAGExplorerView()
    }
}
