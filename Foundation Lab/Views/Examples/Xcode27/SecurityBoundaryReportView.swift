//
//  SecurityBoundaryReportView.swift
//  FoundationLab
//

import SwiftUI

struct SecurityBoundaryReportView: View {
    let report: SecurityBoundaryReport

    var body: some View {
        Xcode27Section(String(localized: "Boundary inspection")) {
            VStack(spacing: 0) {
                SecurityBoundaryRow(
                    title: String(localized: "User request"),
                    detail: report.requestBoundary,
                    systemImage: "person.text.rectangle"
                )
                Divider()
                SecurityBoundaryRow(
                    title: String(localized: "Retrieved content"),
                    detail: report.contextBoundary,
                    systemImage: "doc.text.magnifyingglass"
                )
                Divider()
                SecurityBoundaryRow(
                    title: String(localized: "Tool exposure"),
                    detail: report.toolBoundary,
                    systemImage: "hammer"
                )
                Divider()
                SecurityBoundaryRow(
                    title: report.actionIsProtected
                        ? String(localized: "Action boundary present")
                        : String(localized: "Action boundary missing"),
                    detail: report.actionBoundary,
                    systemImage: report.actionIsProtected ? "hand.raised.fill" : "exclamationmark.triangle.fill",
                    tint: report.actionIsProtected ? .green : .red
                )
            }
        }
    }
}
