import FoundationModelsTools
import SwiftUI

struct ToolMutationApprovalView: View {
    let request: ToolMutationRequest
    let approve: () -> Void
    let deny: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(request.summary)
                        .font(.body)

                    LabeledContent("Tool", value: request.toolName)
                    LabeledContent("Action", value: request.action)

                    if let resourceID = request.resourceID {
                        LabeledContent("Resource ID", value: resourceID)
                    }
                }

                if !request.details.isEmpty {
                    Section("Details:") {
                        ForEach(Array(request.details.enumerated()), id: \.offset) { _, detail in
                            LabeledContent(detail.label, value: detail.value)
                        }
                    }
                }

                if request.isDestructive {
                    Section {
                        Label(
                            "This action deletes data and cannot be undone.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(.red)
                    }
                }
            }
            .textSelection(.enabled)
            .navigationTitle("Proposed tool action")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Deny", role: .cancel, action: deny)
                }

                ToolbarItem(placement: .confirmationAction) {
                    if request.isDestructive {
                        Button("Approve", role: .destructive, action: approve)
                    } else {
                        Button("Approve", action: approve)
                    }
                }
            }
        }
        .interactiveDismissDisabled()
#if os(iOS)
        .presentationDetents([.medium, .large])
#else
        .frame(minWidth: 420, minHeight: 360)
#endif
    }
}
