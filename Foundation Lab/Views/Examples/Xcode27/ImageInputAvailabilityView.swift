//
//  ImageInputAvailabilityView.swift
//  FoundationLab
//

#if compiler(>=6.4)
import SwiftUI

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
struct ImageInputAvailabilityView: View {
    let message: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("Image input unavailable")
                    .bold()
                Text(message)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
        }
        .font(.callout)
        .accessibilityElement(children: .combine)
    }
}
#endif
