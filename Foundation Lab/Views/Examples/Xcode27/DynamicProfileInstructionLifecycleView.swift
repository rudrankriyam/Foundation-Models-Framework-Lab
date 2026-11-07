//
//  DynamicProfileInstructionLifecycleView.swift
//  FoundationLab
//

import SwiftUI

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct DynamicProfileInstructionLifecycleView: View {
    let events: [DynamicProfileInstructionEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Instruction Lifecycle")
                .font(.subheadline)
                .bold()

            if #available(iOS 27.2, macOS 27.2, visionOS 27.2, *) {
                Text(
                    """
                    Each stage groups its instructions with DynamicInstructions.Group. The framework calls onActivate and \
                    onDeactivate when the resolved profile includes or drops a group.
                    """
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

                if events.isEmpty {
                    Text("No lifecycle events recorded yet.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(events) { event in
                        eventRow(event)
                    }
                }
            } else {
                Text("Instruction lifecycle callbacks require iOS 27.2, macOS 27.2, or visionOS 27.2.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func eventRow(_ event: DynamicProfileInstructionEvent) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Text(event.sequence.formatted())
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            Label(event.kind.title, systemImage: event.kind.systemImage)
            Spacer(minLength: Spacing.small)
            Text(verbatim: "\(event.stage.title) · \(event.runtime.apiName)")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .font(.callout)
        .accessibilityElement(children: .combine)
    }
}
