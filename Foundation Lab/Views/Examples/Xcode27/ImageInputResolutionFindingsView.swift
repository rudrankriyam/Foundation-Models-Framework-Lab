//
//  ImageInputResolutionFindingsView.swift
//  FoundationLab
//
//  Created by Codex on 6/14/26.
//

import SwiftUI

struct ImageInputResolutionFindingsView: View {
    var body: some View {
        Xcode27Section("Resolution Probe") {
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
                    title: "Semantic failure",
                    detail: """
                    Requests above the boundary still completed successfully, but the model consistently changed a yellow diamond \
                    on a blue background into a circle on black.
                    """,
                    systemImage: "exclamationmark.triangle.fill",
                    tint: .orange
                )

                Divider()

                Xcode27InfoRow(
                    title: "Inferred 2 GiB boundary",
                    detail: """
                    The measured flips align with a 4-byte BGRA decode buffer, using a 16-byte-aligned row stride, crossing 2^31 bytes. \
                    This is an implementation inference, not an official Apple limit.
                    """,
                    systemImage: "memorychip",
                    tint: .purple
                )

                Text("decodedBytes = ceil((width * 4) / 16) * 16 * height")
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                Divider()

                Xcode27InfoRow(
                    title: "Reproduce it",
                    detail: """
                    Run Tools/ImageInputProbe/image_input_probe.py with known expected terms to measure transport and semantic correctness \
                    on the current OS and model build.
                    """,
                    systemImage: "terminal",
                    tint: .blue
                )
            }
        }
    }
}
