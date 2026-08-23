//
//  ToolMutationApprovalSheet.swift
//  FoundationLab
//

import FoundationModelsTools
import SwiftUI

struct ToolMutationApprovalSheet: View {
    @Bindable var coordinator: ToolMutationApprovalCoordinator

    var body: some View {
        Group {
            if let request = coordinator.currentRequest {
                ToolMutationApprovalView(
                    request: request,
                    approve: coordinator.approveCurrentRequest,
                    deny: coordinator.denyCurrentRequest
                )
                // A queued request must never reuse the preceding approval view.
                .id(request.id)
            }
        }
    }
}
