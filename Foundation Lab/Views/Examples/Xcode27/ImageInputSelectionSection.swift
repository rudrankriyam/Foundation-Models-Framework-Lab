//
//  ImageInputSelectionSection.swift
//  FoundationLab
//

#if compiler(>=6.4)
import SwiftUI

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
struct ImageInputSelectionSection: View {
    let selection: ImageInputSelection?
    let isImporting: Bool
    let chooseImage: () -> Void
    let removeImage: () -> Void

    var body: some View {
        Xcode27Section(String(localized: "Image")) {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        if isImporting {
            ProgressView("Importing image…")
                .frame(maxWidth: .infinity, minHeight: 160)
        } else if let selection {
            selectedImageContent(selection)
        } else {
            emptyContent
        }
    }

    private func selectedImageContent(_ selection: ImageInputSelection) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Image(
                selection.previewImage,
                scale: 1,
                orientation: .up,
                label: Text("Selected image preview: \(selection.fileName)")
            )
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: 360)
            .background(.quaternary, in: .rect(cornerRadius: CornerRadius.medium))
            .clipShape(.rect(cornerRadius: CornerRadius.medium))

            metadata(for: selection)

            VStack(spacing: Spacing.small) {
                Button("Replace Image", systemImage: "photo.badge.plus", action: chooseImage)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, minHeight: 44)

                Button("Remove", systemImage: "trash", action: removeImage)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
    }

    private func metadata(for selection: ImageInputSelection) -> some View {
        VStack(spacing: Spacing.small) {
            LabeledContent("File", value: selection.fileName)
            LabeledContent("Dimensions", value: selection.pixelDimensions)
            LabeledContent("Format", value: selection.formatDescription)
            LabeledContent("File size", value: selection.fileSizeDescription)
        }
        .font(.callout)
    }

    private var emptyContent: some View {
        ContentUnavailableView {
            Label("Choose an Image", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text("Import a JPEG, HEIF, PNG, or another image format supported by this device.")
        } actions: {
            Button("Choose Image", systemImage: "photo.badge.plus", action: chooseImage)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(minHeight: 44)
        }
        .frame(minHeight: 220)
    }
}
#endif
