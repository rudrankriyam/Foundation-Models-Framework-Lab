//
//  SecurityBoundaryRow.swift
//  FoundationLab
//

import SwiftUI

struct SecurityBoundaryRow: View {
    let title: String
    let detail: String
    let systemImage: String
    var tint: Color = .blue

    var body: some View {
        Xcode27InfoRow(title: title, detail: detail, systemImage: systemImage, tint: tint)
            .padding(.vertical, Spacing.medium)
    }
}
