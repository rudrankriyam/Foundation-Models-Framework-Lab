//
//  ImageInputAvailabilityView.swift
//  FoundationLab
//

#if compiler(>=6.4)
import SwiftUI

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
struct ImageInputAvailabilityView: View {
    let message: String?

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(message == nil ? "Image input ready" : "Image input unavailable")
                    .bold()
                Text(message ?? String(localized: "The image and prompt stay on this device for this system-model request."))
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: message == nil ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(message == nil ? .green : .orange)
        }
        .font(.callout)
        .accessibilityElement(children: .combine)
    }
}
#endif
