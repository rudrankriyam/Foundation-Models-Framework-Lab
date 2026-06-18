//
//  TranscriptDisplayEntry.swift
//  FoundationLab
//

import FoundationModels

struct TranscriptDisplayEntry: Identifiable {
    let transcriptIndex: Int
    let entry: Transcript.Entry

    var id: String {
        "\(transcriptIndex)-\(entry.id)"
    }

    init(transcriptIndex: Int, entry: Transcript.Entry) {
        self.transcriptIndex = transcriptIndex
        self.entry = entry
    }
}
