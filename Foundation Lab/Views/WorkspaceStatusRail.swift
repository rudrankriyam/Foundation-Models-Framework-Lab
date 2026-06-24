import SwiftUI

struct WorkspaceStatusRail: View {
    let title: String
    let context: String
    let systemImage: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: Spacing.small) {
            if isActive {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel(title)
            } else {
                Image(systemName: systemImage)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }

            Text(title)
                .lineLimit(1)
                .help(title)

            Spacer(minLength: Spacing.medium)

            Text(context)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .font(.callout)
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.xSmall)
        .background(.bar)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    WorkspaceStatusRail(
        title: "Comparison complete",
        context: "Results",
        systemImage: "checkmark.circle",
        isActive: false
    )
}
