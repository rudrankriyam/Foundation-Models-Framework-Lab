import SwiftUI

struct AdapterStudioInspector: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Comparison")
                    .font(.headline)

                LabeledContent("Models", value: "2")
                LabeledContent("Sessions", value: "Fresh")
                LabeledContent("Inference", value: "Local")
            }

            Divider()

            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Comparison Rules")
                    .font(.headline)

#if os(macOS)
                Label(
                    "Both models receive the same prompt in fresh sessions.",
                    systemImage: "equal.circle.fill"
                )
                Label(
                    "One model failing does not cancel the other response.",
                    systemImage: "arrow.triangle.branch"
                )
                Label(
                    "Concurrent timing is diagnostic, not a benchmark result.",
                    systemImage: "speedometer"
                )
#else
                Label(
                    "Open Foundation Lab on macOS to load custom adapters.",
                    systemImage: "macbook"
                )
#endif
            }
            .font(.callout)
        }
        .padding(Spacing.large)
    }
}

#Preview {
    AdapterStudioInspector()
        .frame(width: 320)
}
