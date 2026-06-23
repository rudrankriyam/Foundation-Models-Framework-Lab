//
//  TranscriptEntryDetailView.swift
//  FoundationLab
//

import SwiftUI

struct TranscriptEntryDetailView: View {
    let entry: SessionTranscriptSnapshot.Entry
    @Binding var selectedSegmentID: String?

    private var selectedSegment: SessionTranscriptSnapshot.Segment? {
        entry.segments.first { $0.id == selectedSegmentID } ?? entry.segments.first
    }

    var body: some View {
        Xcode27Section(String(localized: "Selected Entry")) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                LabeledContent(String(localized: "Framework ID")) {
                    Text(entry.frameworkID)
                        .font(.callout.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                if !entry.fields.isEmpty {
                    DisclosureGroup(String(localized: "Entry Details")) {
                        Xcode27KeyValueList(items: entry.fields.map { ($0.name, $0.value) })
                            .padding(.top, Spacing.small)
                    }
                    .font(.callout)
                }

                if entry.segments.isEmpty {
                    Text("This observed entry has no displayable segments.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    Picker(String(localized: "Segment"), selection: $selectedSegmentID) {
                        ForEach(entry.segments) { segment in
                            Text("\(segment.kind.title): \(segment.label)")
                                .tag(Optional(segment.id))
                        }
                    }

                    if let selectedSegment {
                        VStack(alignment: .leading, spacing: Spacing.small) {
                            Text(selectedSegment.label)
                                .font(.subheadline)
                                .bold()

                            Text(selectedSegment.content)
                                .font(selectedSegment.kind == .text ? .body : .body.monospaced())
                                .foregroundStyle(selectedSegment.content.isEmpty ? .secondary : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
        }
    }
}
