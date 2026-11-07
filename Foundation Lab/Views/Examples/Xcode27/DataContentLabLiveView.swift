//
//  DataContentLabLiveView.swift
//  FoundationLab
//

import SwiftUI
import UniformTypeIdentifiers

@available(iOS 27.2, macOS 27.2, visionOS 27.2, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct DataContentLabLiveView: View {
    @State private var model = DataContentLabViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xLarge) {
                demoModelNotice

                Xcode27Section(String(localized: "Data Attachment")) {
                    ColorSwatchStrip(swatch: model.swatch)
                    Xcode27KeyValueList(items: [
                        (String(localized: "Content type"), UTType.foundationLabColorSwatch.identifier),
                        (String(localized: "Content"), String(localized: "\(model.swatch.rgbData.count) bytes")),
                        (String(localized: "Metadata"), "name: \(model.swatch.name)")
                    ])
                }

                Button(
                    model.isRunning ? "Running…" : "Send to Demo Model",
                    systemImage: model.isRunning ? "hourglass" : "play.fill"
                ) {
                    Task { await model.run() }
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity, minHeight: FoundationLabLayout.minimumTouchTarget)
                .disabled(model.isRunning)

                if let errorMessage = model.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(.red)
                }

                if let responseText = model.responseText {
                    results(responseText: responseText)
                }

                CodeDisclosure(code: Self.code)
            }
            .frame(maxWidth: FoundationLabLayout.readableContentWidth, alignment: .leading)
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Data Content")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .navigationSubtitle("Custom attachments and data entries")
        #endif
    }

    private var demoModelNotice: some View {
        Label {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("Local demo model")
                    .bold()
                Text(
                    """
                    This lab runs PaletteDemoLanguageModel, a deterministic LanguageModel defined in this app. It is not \
                    Apple's model and does not generate language. It inverts the attached colors and emits them as a data entry.
                    """
                )
                .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: "info.circle")
                .foregroundStyle(.blue)
        }
        .font(.callout)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func results(responseText: String) -> some View {
        Xcode27Section(String(localized: "Data Entries")) {
            ForEach(model.observedPalettes.indices, id: \.self) { index in
                ColorSwatchStrip(swatch: model.observedPalettes[index].swatch)
            }
            Xcode27KeyValueList(items: [
                (String(localized: "Data entries"), "\(model.observedPalettes.count)"),
                (String(localized: "Observed through"), model.observationSource ?? "-"),
                (String(localized: "Response text"), responseText)
            ])
        }

        Xcode27Section(String(localized: "Session Transcript")) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                ForEach(model.entryKinds.indices, id: \.self) { index in
                    Text(verbatim: "\(index + 1). \(model.entryKinds[index])")
                        .font(.callout.monospaced())
                        .textSelection(.enabled)
                }
            }
        }

        if let roundTrip = model.roundTrip {
            Xcode27Section(String(localized: "Codable Round Trip")) {
                if let palette = roundTrip.decodedPalette {
                    ColorSwatchStrip(swatch: palette.swatch)
                }
                Xcode27KeyValueList(items: [
                    (String(localized: "Encoded JSON"), String(localized: "\(roundTrip.encodedByteCount) bytes")),
                    (
                        String(localized: "Type, bytes, and metadata preserved"),
                        roundTrip.payloadsPreserved ? String(localized: "Yes") : String(localized: "No")
                    )
                ])
            }
        }
    }
}

@available(iOS 27.2, macOS 27.2, visionOS 27.2, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension DataContentLabLiveView {
    static let code = """
    extension UTType {
        static let colorSwatch = UTType(exportedAs: "com.example.color-swatch", conformingTo: .data)
        static let colorPalette = UTType(exportedAs: "com.example.color-palette", conformingTo: .data)
    }

    struct ColorSwatch: DataAttachmentRepresentable {
        init(_ attachment: Transcript.DataAttachment) throws { /* Decode RGB bytes. */ }
        var transcriptRepresentation: Transcript.DataAttachment {
            .init(contentType: .colorSwatch, content: rgbData,
                  metadata: GeneratedContent(properties: ["name": name]))
        }
    }

    struct ColorPalette: DataEntryRepresentable {
        init(_ entry: Transcript.DataEntry) throws { /* Decode RGB bytes. */ }
        var transcriptRepresentation: Transcript.DataEntry { /* Encode RGB bytes. */ }
    }

    struct PaletteDemoLanguageModel: LanguageModel {
        func supportsDataAttachmentType(_ type: UTType) async throws -> Bool { type == .colorSwatch }
        func supportsDataEntryType(_ type: UTType) async throws -> Bool { type == .colorPalette }
    }

    // Executor: read the .data attachment, then emit a .data entry.
    if case let .attachment(segment) = promptSegment,
       case let .data(attachment) = segment.content {
        swatch = try ColorSwatch(attachment)
    }
    await channel.send(.data(action: .update(
        contentType: .colorPalette, content: complement.rgbData, metadata: metadata
    )))

    // App: attach, observe, and round-trip.
    // onDataEntry needs the Xcode 27.3 SDK and OS 27.3. Without it, read .data entries from session.transcript.
    let profile = LanguageModelSession.Profile { Instructions("...") }
        .model(PaletteDemoLanguageModel())
        .onDataEntry { entry in palettes.append(try ColorPalette(entry)) }
    let session = LanguageModelSession(profile: profile)
    try await session.respond {
        "Suggest a complementary palette."
        Attachment(swatch).label("brand-swatch")
    }
    for case let .data(entry) in session.transcript { _ = try ColorPalette(entry) }
    let json = try JSONEncoder().encode(session.transcript)
    let restored = try JSONDecoder().decode(Transcript.self, from: json)
    for case let .data(entry) in restored { _ = try ColorPalette(entry) }
    """
}
