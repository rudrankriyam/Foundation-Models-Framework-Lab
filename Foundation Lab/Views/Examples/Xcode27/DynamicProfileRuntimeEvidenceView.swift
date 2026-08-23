//
//  DynamicProfileRuntimeEvidenceView.swift
//  FoundationLab
//

#if compiler(>=6.4)
import SwiftUI

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct DynamicProfileRuntimeEvidenceView: View {
    let runtime: DynamicProfileReviewRuntime

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                Text("Runtime")
                Spacer(minLength: Spacing.small)
                apiName
            }

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("Runtime")
                apiName
            }
        }
        .font(.callout)
        .padding(.vertical, Spacing.small)
        .accessibilityElement(children: .combine)
    }

    private var apiName: some View {
        Text(runtime.apiName)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
    }
}
#endif
