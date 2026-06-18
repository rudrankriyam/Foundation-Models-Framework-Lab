#if os(macOS)
import SwiftUI

struct AdapterStudioMetadataView: View {
    let metadata: AdapterMetadata

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LabeledContent("Name", value: metadata.fileName)
                .padding(.vertical, Spacing.small)

            Divider()

            LabeledContent(
                "Size",
                value: ByteCountFormatter.string(
                    fromByteCount: Int64(metadata.fileSize),
                    countStyle: .file
                )
            )
            .padding(.vertical, Spacing.small)

            if let modifiedAt = metadata.modifiedAt {
                Divider()

                LabeledContent {
                    Text(modifiedAt, style: .relative)
                } label: {
                    Text("Modified")
                }
                .padding(.vertical, Spacing.small)
            }

            if !metadata.creatorDefinedMetadata.isEmpty {
                ForEach(
                    metadata.creatorDefinedMetadata.keys.sorted(),
                    id: \.self
                ) { key in
                    Divider()

                    LabeledContent(
                        key,
                        value: metadata.creatorDefinedMetadata[key] ?? ""
                    )
                    .padding(.vertical, Spacing.small)
                }
            }
        }
    }
}
#endif
