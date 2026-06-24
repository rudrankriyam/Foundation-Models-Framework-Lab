import SwiftUI

struct WorkspacePhaseHeader: View {
    let workspace: Workspace
    let stage: WorkspaceStage

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.large) {
                titleAndSummary
                Spacer(minLength: Spacing.large)
                phasePosition
            }

            VStack(alignment: .leading, spacing: Spacing.small) {
                titleAndSummary
                phasePosition
            }
        }
    }

    private var titleAndSummary: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Label(workspace.title(for: stage), systemImage: workspace.systemImage(for: stage))
                .font(.title2.bold())

            Text(workspace.summary)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var phasePosition: some View {
        Text(
            String(
                localized: "Phase \(stage.ordinal) of \(WorkspaceStage.allCases.count)"
            )
        )
        .font(.callout)
        .foregroundStyle(.secondary)
        .monospacedDigit()
    }
}

#Preview {
    WorkspacePhaseHeader(workspace: .adapterComparison, stage: .runs)
        .padding()
}
