//
//  SpotlightRAGConfigurationSection.swift
//  FoundationLab
//

#if compiler(>=6.4) && arch(arm64)
import SwiftUI

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct SpotlightRAGConfigurationSection: View {
    @Bindable var model: SpotlightRAGViewModel

    @State private var showsSettings = false

    var body: some View {
        DisclosureGroup(isExpanded: $showsSettings) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Picker("Search guidance", selection: $model.guidance) {
                    ForEach(SpotlightRAGGuidance.allCases) { guidance in
                        Text(guidance.title).tag(guidance)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("Use compact result formatting", isOn: $model.usesCompactFormat)

                Text(model.guidance.explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .disabled(model.isRunning)
            .padding(.top, Spacing.small)
        } label: {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("Search Settings")
                    .font(.headline)
                Text("\(model.guidance.title) guidance · \(model.usesCompactFormat ? "Compact" : "Structured") output")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Spacing.small)
    }
}
#endif
