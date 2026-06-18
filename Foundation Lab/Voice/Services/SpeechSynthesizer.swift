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

    /// Available voices organized by language
    var voicesByLanguage: [String: [AVSpeechSynthesisVoice]] { get }

    /// All available languages
    var availableLanguages: [String] { get }

    /// Currently selected voice
    var selectedVoice: AVSpeechSynthesisVoice? { get set }

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
            return "Invalid input text"
        case .alreadySpeaking:
            return "Speech synthesis already in progress"
        case .cancelled:
            return "Speech synthesis was cancelled"
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
    var speakingStateHandler: ((Bool) -> Void)?
    var errorHandler: ((SpeechSynthesizerError) -> Void)?

    var selectedVoice: AVSpeechSynthesisVoice?
    var availableVoices: [AVSpeechSynthesisVoice] = []
    var voicesByLanguage: [String: [AVSpeechSynthesisVoice]] = [:]
    var availableLanguages: [String] = []
    private let volume: Float

    private init(volume: Float = 1.0) {
        self.volume = max(0.0, min(1.0, volume))

        super.init()

        synthesizer.delegate = self
        loadAvailableVoices()
        preWarmSynthesizer()
    }

    func synthesizeAndSpeak(text: String) async throws {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SpeechSynthesizerError.invalidInput
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
        defer { isSynthesisInFlight = false }

        let playbackSessionWasActivated = await configurePlaybackSession()
        do {
            try Task.checkCancellation()
        } catch {
            await deactivatePlaybackSessionAfterCancelledStartup(ifActivated: playbackSessionWasActivated)
            throw error
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.pendingContinuation = continuation

            let utterance = self.createUtterance(from: text)
            self.startSynthesis(utterance: utterance)
        }
    }

    private func preWarmSynthesizer() {
        // Don't pre-warm automatically - it can cause audio engine conflicts
        // We'll initialize on first use instead
        logger.debug("Speech synthesizer ready for first use")
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

    private func deactivatePlaybackSessionAfterCancelledStartup(ifActivated: Bool) async {
        #if os(iOS)
        guard ifActivated else { return }

        do {
            try await Self.deactivatePlaybackSession()
            logger.debug("Deactivated audio session after cancelled speech startup")
        } catch {
            logger.error("Failed to deactivate audio session after cancelled startup: \(error.localizedDescription, privacy: .public)")
        }
        #endif
    }

    #if os(iOS)
    /// `setActive` is synchronous, so keep it off the main actor to avoid blocking UI work.
    private nonisolated static func activatePlaybackSession() async throws {
        try await Task.detached(priority: .userInitiated) {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true, options: [])
        }.value
    }

    private nonisolated static func deactivatePlaybackSession() async throws {
        try await Task.detached(priority: .utility) {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        }.value
    }
    #endif

    func loadAvailableVoices() {
        Task { @MainActor in
            let allVoices = AVSpeechSynthesisVoice.speechVoices()
            let speechVoices = filterSpeechVoices(from: allVoices)
            var voicesGroupedByLanguage = groupVoicesByLanguage(speechVoices)
            voicesGroupedByLanguage = sortVoicesWithinLanguages(voicesGroupedByLanguage)

            voicesByLanguage = voicesGroupedByLanguage
            availableLanguages = sortLanguages(Set(voicesGroupedByLanguage.keys))

            let englishVoices = filterAndSortEnglishVoices(from: speechVoices, allVoices: allVoices)
            availableVoices = englishVoices

            selectedVoice = selectPreferredVoice(from: englishVoices)

            if VoiceLogging.isVerboseEnabled, let voice = selectedVoice {
                logger.debug(
                    """
                    Selected voice: \(voice.name, privacy: .public) \
                    (\(voice.language, privacy: .public)) quality=\(voice.quality.rawValue)
                    """
                )
                let summaries = availableVoices.map { "\($0.name) (Q:\($0.quality.rawValue))" }.joined(separator: ", ")
                logger.debug("Available voices: \(summaries, privacy: .public)")
            }
        }
    }

    private func createUtterance(from text: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = selectedVoice ?? AVSpeechSynthesisVoice(language: "en-US")
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

    private func resetState() {
        isSpeaking = false
        currentUtterance = nil
        pendingContinuation = nil
    }

    private func handleSuccess() {
        logger.info("Speech synthesis completed successfully")

        #if os(iOS)
        Task { @MainActor in
            do {
                try await Self.deactivatePlaybackSession()
                logger.debug("Deactivated audio session after speech synthesis")
            } catch {
                logger.error("Failed to deactivate audio session: \(error.localizedDescription, privacy: .public)")
            }
        }
        #endif

        if let continuation = pendingContinuation {
            continuation.resume()
            pendingContinuation = nil
        }

        resetState()
        speakingStateHandler?(false)
    }

    private func handleError(_ synthError: SpeechSynthesizerError) {
        error = synthError
        errorHandler?(synthError)

#if os(iOS)
        Task { @MainActor in
            do {
                try await Self.deactivatePlaybackSession()
                logger.debug("Deactivated audio session after speech synthesis error")
            } catch {
                logger.error("Failed to deactivate audio session after error: \(error.localizedDescription, privacy: .public)")
            }
        }
#endif

        if let continuation = pendingContinuation {
            continuation.resume(throwing: synthError)
            pendingContinuation = nil
        }

        resetState()
        speakingStateHandler?(false)
    }

    func cancelSpeaking() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SpeechSynthesizer: AVSpeechSynthesizerDelegate {

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.handleSuccess()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.handleError(.cancelled)
        }
    }
}
