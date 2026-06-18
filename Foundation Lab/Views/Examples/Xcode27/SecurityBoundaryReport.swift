//
//  SecurityBoundaryReport.swift
//  FoundationLab
//

import Foundation

struct SecurityBoundaryReport {
    let requestBoundary: String
    let contextBoundary: String
    let toolBoundary: String
    let actionBoundary: String
    let actionIsProtected: Bool

    static func inspect(
        request: String,
        untrustedContent: String,
        toolAccess: SecurityToolAccess,
        requiresApproval: Bool
    ) -> SecurityBoundaryReport {
        let requestCount = request.trimmingCharacters(in: .whitespacesAndNewlines).count
        let context = untrustedContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "No retrieved content is included."
            : "Retrieved text is labeled as untrusted data and kept separate from the user request."

        let action: String
        let isProtected: Bool
        if toolAccess.hasSideEffect {
            isProtected = requiresApproval
            action = requiresApproval
                ? "The tool must stop for app-owned user approval before sending."
                : "No approval gate is configured; the tool implementation could perform the side effect."
        } else {
            isProtected = true
            action = "No side-effecting tool is available in this request."
        }

        return SecurityBoundaryReport(
            requestBoundary: "The app sends a \(requestCount)-character user request as prompt content.",
            contextBoundary: context,
            toolBoundary: toolAccess.detail,
            actionBoundary: action,
            actionIsProtected: isProtected
        )
    }
}
