//
//  ImageInputImportProgressView.swift
//  FoundationLab
//

#if compiler(>=6.4)
import SwiftUI

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
struct ImageInputImportProgressView: View {
    let retainedFileName: String?
    let cancel: () -> Void

    var body: some View {
        VStack(spacing: Spacing.medium) {
            ProgressView()

            VStack(spacing: Spacing.xSmall) {
                Text(retainedFileName == nil ? "Importing image…" : "Importing replacement…")
                    .bold()

                if let retainedFileName {
                    Text("Keeping \(retainedFileName) selected unless the replacement succeeds.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Button("Cancel Import", systemImage: "xmark", action: cancel)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(minHeight: 44)
        }
        .font(.callout)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }
}
#endif
