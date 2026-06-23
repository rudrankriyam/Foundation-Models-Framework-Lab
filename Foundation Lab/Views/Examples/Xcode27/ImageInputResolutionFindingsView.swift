//
//  ImageInputResolutionFindingsView.swift
//  FoundationLab
//
//  Created by Codex on 6/14/26.
//

import SwiftUI

struct ImageInputResolutionFindingsView: View {
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup("Measured Resolution Notes", isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text(
                    """
                    Apple does not publish a maximum pixel size, megapixel count, file size, or aspect ratio for Foundation Models \
                    image attachments.
                    """
                )
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

                Label(
                    """
                    The interactive picker caps encoded files at 64 MB and estimated decoded buffers at 256 MB. \
                    Use ImageInputProbe for boundary tests.
                    """,
                    systemImage: "shield.checkered"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)

                Label(
                    "Observed June 14, 2026 on macOS 27.0 beta build 26A5353q using the system model and a Display P3 JPEG.",
                    systemImage: "macbook"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 220), spacing: Spacing.small)],
                    spacing: Spacing.small
                ) {
                    ImageInputResolutionFinding(
                        ratio: "1:1",
                        largestCorrect: "23168x23168",
                        firstIncorrect: "23169x23169"
                    )

                    ImageInputResolutionFinding(
                        ratio: "16:9",
                        largestCorrect: "30892x17377",
                        firstIncorrect: "30893x17377"
                    )

                    ImageInputResolutionFinding(
                        ratio: "9:16",
                        largestCorrect: "17376x30891",
                        firstIncorrect: "17377x30892"
                    )

                    ImageInputResolutionFinding(
                        ratio: "4:3",
                        largestCorrect: "26753x20065",
                        firstIncorrect: "26754x20066"
                    )
                }

                Divider()

                Xcode27InfoRow(
                    title: String(localized: "Semantic failure"),
                    detail: String(localized: """
                    Requests above the boundary still completed successfully, but the model consistently changed a yellow diamond \
                    on a blue background into a circle on black.
                    """),
                    systemImage: "exclamationmark.triangle.fill",
                    tint: .orange
                )

                Divider()

                Xcode27InfoRow(
                    title: String(localized: "Inferred 2 GiB boundary"),
                    detail: String(localized: """
                    The measured flips align with a 4-byte BGRA decode buffer, using a 16-byte-aligned row stride, crossing 2^31 bytes. \
                    This is an implementation inference, not an official Apple limit.
                    """),
                    systemImage: "memorychip",
                    tint: .purple
                )

                Text("decodedBytes = ceil((width * 4) / 16) * 16 * height")
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                Divider()

                Xcode27InfoRow(
                    title: String(localized: "Reproduce it"),
                    detail: String(localized: """
                    Run Tools/ImageInputProbe/image_input_probe.py with known expected terms to measure transport and semantic correctness \
                    on the current OS and model build.
                    """),
                    systemImage: "terminal",
                    tint: .blue
                )
            }
            .padding(.top, Spacing.small)
        }
        .font(.callout)
    }
}
