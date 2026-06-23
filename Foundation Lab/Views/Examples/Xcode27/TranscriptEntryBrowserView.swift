//
//  TranscriptEntryBrowserView.swift
//  FoundationLab
//

import SwiftUI

struct TranscriptEntryBrowserView: View {
    let entries: [SessionTranscriptSnapshot.Entry]
    let selectedEntryID: String?
    let onSelect: (String?) -> Void

    var body: some View {
        Xcode27Section(String(localized: "Observed Transcript")) {
            VStack(spacing: 0) {
                ForEach(entries) { entry in
                    Button(action: { onSelect(entry.id) }, label: {
                        HStack(alignment: .top, spacing: Spacing.medium) {
                            Text(entry.ordinal, format: .number)
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 24, alignment: .trailing)

                            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                                Label(entry.kind.title, systemImage: entry.kind.systemImage)
                                    .font(.subheadline)
                                    .bold()

                                Text(entry.summary)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                            }

                            Spacer(minLength: Spacing.small)

                            Image(systemName: entry.id == selectedEntryID ? "checkmark.circle.fill" : "chevron.right")
                                .foregroundStyle(entry.id == selectedEntryID ? Color.accentColor : .secondary)
                                .accessibilityHidden(true)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .padding(.horizontal, Spacing.small)
                        .padding(.vertical, Spacing.small)
                        .contentShape(.rect)
                        .background(
                            entry.id == selectedEntryID ? Color.accentColor.opacity(0.08) : .clear,
                            in: .rect(cornerRadius: CornerRadius.small)
                        )
                    })
                    .buttonStyle(.plain)
                    .accessibilityLabel("Entry \(entry.ordinal), \(entry.kind.title), \(entry.summary)")
                    .accessibilityValue(entry.id == selectedEntryID ? "Selected" : "")

                    if entry.id != entries.last?.id {
                        Divider()
                            .padding(.leading, Spacing.xxLarge)
                    }
                }
            }
        }
    }
}
