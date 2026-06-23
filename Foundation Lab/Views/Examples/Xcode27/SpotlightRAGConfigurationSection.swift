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

    var body: some View {
        Xcode27Section(String(localized: "Tool Configuration")) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Picker("Search guidance", selection: $model.guidance) {
                    ForEach(SpotlightRAGGuidance.allCases) { guidance in
                        Text(guidance.title).tag(guidance)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("Use compact result formatting", isOn: $model.usesCompactFormat)

                Text(
                    """
                    Dynamic guidance enables text, semantic, date, and content-type search while excluding irrelevant people and \
                    numeric operators. Compact formatting preserves more of the model's context window.
                    """
                )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .disabled(model.isRunning)
        }
    }
}
#endif
