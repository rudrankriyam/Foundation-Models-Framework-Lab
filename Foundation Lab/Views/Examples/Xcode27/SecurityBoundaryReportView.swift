//
//  SecurityBoundaryReportView.swift
//  FoundationLab
//

import SwiftUI

struct SecurityBoundaryReportView: View {
    let report: SecurityBoundaryReport

    var body: some View {
        Xcode27Section("Boundary inspection") {
            VStack(spacing: 0) {
                SecurityBoundaryRow(
                    title: "User request",
                    detail: report.requestBoundary,
                    systemImage: "person.text.rectangle"
                )
                Divider()
                SecurityBoundaryRow(
                    title: "Retrieved content",
                    detail: report.contextBoundary,
                    systemImage: "doc.text.magnifyingglass"
                )
                Divider()
                SecurityBoundaryRow(
                    title: "Tool exposure",
                    detail: report.toolBoundary,
                    systemImage: "hammer"
                )
                Divider()
                SecurityBoundaryRow(
                    title: report.actionIsProtected ? "Action boundary present" : "Action boundary missing",
                    detail: report.actionBoundary,
                    systemImage: report.actionIsProtected ? "hand.raised.fill" : "exclamationmark.triangle.fill",
                    tint: report.actionIsProtected ? .green : .red
                )
            }
        }
    }
}
