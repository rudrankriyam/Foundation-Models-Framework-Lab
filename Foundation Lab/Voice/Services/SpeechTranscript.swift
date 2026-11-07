//
//  SpeechTranscript.swift
//  Foundation Lab
//

import Foundation

/// Joins the text of consecutive recognition requests within one listening session.
nonisolated struct SpeechTranscript: Equatable {
    enum Outcome: Equatable {
        case listening
        case restartRequest
        case fail
    }

    private(set) var text = ""
    private var committedText = ""
    private var requestText = ""
    private var requestDeliveredResult = false
    private var requestReceivedAudio = false

    mutating func beginRequest() {
        requestText = ""
        requestDeliveredResult = false
        requestReceivedAudio = false
    }

    mutating func receiveAudio() {
        requestReceivedAudio = true
    }

    /// A result that is final or ends an utterance retires its request.
    mutating func receiveResult(_ transcription: String, isFinal: Bool, endsUtterance: Bool) -> Outcome {
        requestDeliveredResult = true
        if !transcription.isEmpty {
            requestText = transcription
        }
        guard isFinal || endsUtterance else {
            text = Self.join(committedText, requestText)
            return .listening
        }
        commitRequestText()
        return .restartRequest
    }

    /// A request that never produced a result fails the session, unless it only heard silence.
    mutating func receiveError(isNoSpeech: Bool) -> Outcome {
        guard requestDeliveredResult || (isNoSpeech && requestReceivedAudio) else {
            return .fail
        }
        commitRequestText()
        return .restartRequest
    }

    private mutating func commitRequestText() {
        committedText = Self.join(committedText, requestText)
        requestText = ""
        text = committedText
    }

    private static func join(_ first: String, _ second: String) -> String {
        let first = first.trimmingCharacters(in: .whitespacesAndNewlines)
        let second = second.trimmingCharacters(in: .whitespacesAndNewlines)
        if first.isEmpty { return second }
        if second.isEmpty { return first }
        return first + " " + second
    }
}
