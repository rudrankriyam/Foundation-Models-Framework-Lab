//
//  DynamicProfileWorkflowIssueView.swift
//  FoundationLab
//

#if compiler(>=6.4)
import SwiftUI

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct DynamicProfileWorkflowIssueView: View {
    let title: String?
    let message: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                if let title {
                    Text(title)
                        .bold()
                }
                Text(message)
                    .foregroundStyle(title == nil ? .primary : .secondary)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
        }
        .font(.callout)
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: .rect(cornerRadius: CornerRadius.medium))
        .accessibilityElement(children: .combine)
    }
}
#endif
