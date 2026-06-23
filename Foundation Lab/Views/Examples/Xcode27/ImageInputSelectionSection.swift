//
//  ImageInputSelectionSection.swift
//  FoundationLab
//

#if compiler(>=6.4)
import SwiftUI

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
struct ImageInputSelectionSection: View {
    @State private var isImageDetailsExpanded = false
    let selection: ImageInputSelection?
    let isImporting: Bool
    let isRunning: Bool
    let chooseImage: () -> Void
    let removeImage: () -> Void
    let cancelImport: () -> Void

    var body: some View {
        Xcode27Section(String(localized: "Image")) {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        if let selection {
            selectedImageContent(selection)
        } else if isImporting {
            ImageInputImportProgressView(retainedFileName: nil, cancel: cancelImport)
                .frame(maxWidth: .infinity, minHeight: 160)
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

            DisclosureGroup("Image Details", isExpanded: $isImageDetailsExpanded) {
                metadata(for: selection)
                    .padding(.top, Spacing.small)
            }
            .font(.callout)

            if isImporting {
                ImageInputImportProgressView(
                    retainedFileName: selection.fileName,
                    cancel: cancelImport
                )
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Spacing.small) {
                        replaceImageButton
                        Spacer()
                        removeImageButton
                    }

                    VStack(spacing: Spacing.small) {
                        replaceImageButton
                            .frame(maxWidth: .infinity)
                        removeImageButton
                            .frame(maxWidth: .infinity)
                    }
                }
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

    private var replaceImageButton: some View {
        Button("Replace Image", systemImage: "photo.badge.plus", action: chooseImage)
            .buttonStyle(.bordered)
            .controlSize(.large)
            .frame(minHeight: 44)
            .disabled(isRunning)
    }

    private var removeImageButton: some View {
        Button("Remove", systemImage: "trash", role: .destructive, action: removeImage)
            .buttonStyle(.borderless)
            .controlSize(.large)
            .frame(minHeight: 44)
            .disabled(isRunning)
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
        .frame(minHeight: 160)
    }
}
#endif
