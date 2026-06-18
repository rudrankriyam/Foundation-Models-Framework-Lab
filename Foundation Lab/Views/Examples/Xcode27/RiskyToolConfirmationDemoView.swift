//
//  RiskyToolConfirmationDemoView.swift
//  FoundationLab
//

import SwiftUI

struct RiskyToolConfirmationDemoView: View {
    private static let defaultPrompt = "Send the invoice reminder to the client."

    @State private var currentPrompt = defaultPrompt
    @State private var decision = ToolApprovalDecision.notPrepared

    var body: some View {
        ExampleViewBase(
            title: "Tool Authorization",
            description: "Keep side-effect authorization inside app-owned tool code",
            defaultPrompt: Self.defaultPrompt,
            currentPrompt: $currentPrompt,
            codeExample: ToolApprovalCodeExample.source,
            onRun: prepareReview,
            onReset: reset
        ) {
            VStack(spacing: Spacing.large) {
                ToolApprovalNotice()
                ToolApprovalReview(decision: decision, approve: approve, deny: deny)
                ToolAuthorizationResponsibilities()
            }
            .onChange(of: currentPrompt) { decision = .notPrepared }
        }
    }

    private func prepareReview() {
        decision = .awaitingUser
    }

    private func approve() {
        decision = .approvedForDemo
    }

    private func deny() {
        decision = .denied
    }

    private func reset() {
        currentPrompt = Self.defaultPrompt
        decision = .notPrepared
    }
}

#Preview {
    NavigationStack {
        RiskyToolConfirmationDemoView()
    }
}
