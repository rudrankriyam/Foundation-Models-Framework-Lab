//
//  SpeechSynthesizer.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 10/27/25.
//

import AVFoundation
import Foundation
import OSLog

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Speech Synthesis Service Protocol

/// Protocol defining the interface for text-to-speech functionality
@MainActor
protocol SpeechSynthesisService: AnyObject {
    /// Whether speech synthesis is currently active
    var isSpeaking: Bool { get }

    /// Any current error state
    var error: SpeechSynthesizerError? { get }

    /// Handler invoked whenever speaking state changes
    var speakingStateHandler: ((Bool) -> Void)? { get set }

    /// Handler invoked when an unrecoverable error occurs
    var errorHandler: ((SpeechSynthesizerError) -> Void)? { get set }

    /// Convert text to speech and speak it directly
    /// - Parameter text: The text to synthesize and speak
    /// - Throws: SpeechSynthesizerError if synthesis fails
    func synthesizeAndSpeak(text: String) async throws

    /// Cancel any in-flight speech ASAP
    func cancelSpeaking()
}

// MARK: - Error Types

enum SpeechSynthesizerError: LocalizedError {
    case invalidInput
    case alreadySpeaking
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return String(localized: "There’s no response text to speak.")
        case .alreadySpeaking:
            return String(localized: "A response is already being spoken.")
        case .cancelled:
            return String(localized: "Speech playback was stopped.")
        }
    }
}

// MARK: - Speech Synthesizer Implementation

/// A service class that handles text-to-speech synthesis
/// Follows the single responsibility principle with one public method
@MainActor
final class SpeechSynthesizer: NSObject, SpeechSynthesisService {

    static let shared = SpeechSynthesizer()

    var isSpeaking = false
    var error: SpeechSynthesizerError?

    private let logger = VoiceLogging.synthesis
    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?
    private var pendingContinuation: CheckedContinuation<Void, Error>?
    private var isSynthesisInFlight = false
    private var cancellationRequested = false
    var speakingStateHandler: ((Bool) -> Void)?
    var errorHandler: ((SpeechSynthesizerError) -> Void)?

    private let volume: Float

    private init(volume: Float = 1.0) {
        self.volume = max(0.0, min(1.0, volume))

        super.init()

        synthesizer.delegate = self
    }

    func synthesizeAndSpeak(text: String) async throws {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SpeechSynthesizerError.invalidInput
        }

        guard !Task.isCancelled else {
            throw SpeechSynthesizerError.cancelled
        }

        guard !isSpeaking, !isSynthesisInFlight else {
            throw SpeechSynthesizerError.alreadySpeaking
        }

        // Prevent concurrent continuation overwrites - if a continuation is pending,
        // another synthesis call is in-flight and we should reject this one
        guard pendingContinuation == nil else {
            throw SpeechSynthesizerError.alreadySpeaking
        }

        isSynthesisInFlight = true
        cancellationRequested = false
        defer {
            isSynthesisInFlight = false
            cancellationRequested = false
        }

        let playbackSessionWasActivated = await configurePlaybackSession()
        guard !Task.isCancelled, !cancellationRequested else {
            await deactivatePlaybackSession(ifActivated: playbackSessionWasActivated)
            throw SpeechSynthesizerError.cancelled
        }

        do {
            try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    guard !Task.isCancelled, !self.cancellationRequested else {
                        continuation.resume(throwing: SpeechSynthesizerError.cancelled)
                        return
                    }

                    self.pendingContinuation = continuation

                    let utterance = self.createUtterance(from: text)
                    self.startSynthesis(utterance: utterance)
                }
            } onCancel: { [weak self] in
                Task { @MainActor [weak self] in
                    self?.requestCancellation()
                }
            }
        } catch {
            await deactivatePlaybackSession(ifActivated: playbackSessionWasActivated)
            throw error
        }

        await deactivatePlaybackSession(ifActivated: playbackSessionWasActivated)
        guard !Task.isCancelled else {
            throw SpeechSynthesizerError.cancelled
        }
    }

    private func configurePlaybackSession() async -> Bool {
        #if os(iOS)
        do {
            try await Self.activatePlaybackSession()
            logger.debug("Configured audio session for speech synthesis playback")
            return true
        } catch {
            logger.error("Failed to configure audio session for playback: \(error.localizedDescription, privacy: .public)")
            return false
        }
        #else
        return false
        #endif
    }

    private func deactivatePlaybackSession(ifActivated: Bool) async {
        #if os(iOS)
        guard ifActivated else { return }

        do {
            try await Self.deactivatePlaybackSession()
            logger.debug("Deactivated speech playback session")
        } catch {
            logger.error("Failed to deactivate speech playback session: \(error.localizedDescription, privacy: .public)")
        }
        #endif
    }

    #if os(iOS)
    /// `setActive` is synchronous, so keep it off the main actor to avoid blocking UI work.
    @concurrent
    private nonisolated static func activatePlaybackSession() async throws {
        try Task.checkCancellation()
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
        try audioSession.setActive(true, options: [])
    }

    @concurrent
    private nonisolated static func deactivatePlaybackSession() async throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    }
    #endif

    private func createUtterance(from text: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.volume = max(0.0, min(1.0, volume))

        if VoiceLogging.isVerboseEnabled {
            let voiceName = utterance.voice?.name ?? "default"
            let rate = String(format: "%.2f", utterance.rate)
            let pitch = String(format: "%.2f", utterance.pitchMultiplier)
            let volume = String(format: "%.2f", utterance.volume)
            logger.debug("Created utterance voice=\(voiceName, privacy: .public) rate=\(rate) pitch=\(pitch) volume=\(volume)")
        }

        return utterance
    }

    private func startSynthesis(utterance: AVSpeechUtterance) {
        currentUtterance = utterance
        isSpeaking = true
        speakingStateHandler?(true)
        error = nil

        logger.info("Starting speech synthesis")
        synthesizer.speak(utterance)
    }

    func cancelSpeaking() {
        requestCancellation()
    }
}

private extension SpeechSynthesizer {
    func handleSuccess(for utteranceID: ObjectIdentifier) {
        logger.info("Speech synthesis completed successfully")
        finishSynthesis(for: utteranceID, result: .success(()))
    }

    func handleError(_ synthError: SpeechSynthesizerError, for utteranceID: ObjectIdentifier) {
        finishSynthesis(for: utteranceID, result: .failure(synthError))
    }

    func finishSynthesis(
        for utteranceID: ObjectIdentifier,
        result: Result<Void, SpeechSynthesizerError>,
        stopSpeaking: Bool = false
    ) {
        guard let activeUtterance = currentUtterance,
              ObjectIdentifier(activeUtterance) == utteranceID else { return }

        let continuation = pendingContinuation
        pendingContinuation = nil
        currentUtterance = nil
        isSpeaking = false

        if stopSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        switch result {
        case .success:
            continuation?.resume()
        case .failure(let synthError):
            error = synthError
            errorHandler?(synthError)
            continuation?.resume(throwing: synthError)
        }

        speakingStateHandler?(false)
    }

    func requestCancellation() {
        guard isSynthesisInFlight || currentUtterance != nil || synthesizer.isSpeaking else { return }
        cancellationRequested = true

        guard let currentUtterance else {
            if synthesizer.isSpeaking {
                synthesizer.stopSpeaking(at: .immediate)
            }
            return
        }

        finishSynthesis(
            for: ObjectIdentifier(currentUtterance),
            result: .failure(.cancelled),
            stopSpeaking: true
        )
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SpeechSynthesizer: AVSpeechSynthesizerDelegate {

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        let utteranceID = ObjectIdentifier(utterance)
        Task { @MainActor in
            guard self.currentUtterance.map(ObjectIdentifier.init) == utteranceID else { return }
            self.isSpeaking = true
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let utteranceID = ObjectIdentifier(utterance)
        Task { @MainActor in
            self.handleSuccess(for: utteranceID)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let utteranceID = ObjectIdentifier(utterance)
        Task { @MainActor in
            self.handleError(.cancelled, for: utteranceID)
        }
    }
}
