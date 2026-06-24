#if os(macOS)
import SwiftUI

struct AdapterStudioResponseComparisonView: View {
    let baseSubtitle: String
    let adapterSubtitle: String
    let baseColumn: AdapterStudioColumnState
    let adapterColumn: AdapterStudioColumnState
    let isActive: Bool

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: Spacing.large) {
                AdapterStudioResponseColumn(
                    title: String(localized: "Base Model"),
                    subtitle: baseSubtitle,
                    column: baseColumn,
                    isActive: isActive
                )

                Divider()

                AdapterStudioResponseColumn(
                    title: String(localized: "Custom Adapter"),
                    subtitle: adapterSubtitle,
                    column: adapterColumn,
                    isActive: isActive
                )
            }

            VStack(spacing: Spacing.large) {
                AdapterStudioResponseColumn(
                    title: String(localized: "Base Model"),
                    subtitle: baseSubtitle,
                    column: baseColumn,
                    isActive: isActive
                )

                Divider()

                AdapterStudioResponseColumn(
                    title: String(localized: "Custom Adapter"),
                    subtitle: adapterSubtitle,
                    column: adapterColumn,
                    isActive: isActive
                )
            }
        }
    }
}
#endif
