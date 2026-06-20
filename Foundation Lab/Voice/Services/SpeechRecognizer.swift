//
//  SpeechRecognizer.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 10/27/25.
//

import Foundation
import Speech
import AVFoundation
import Accelerate
import OSLog

// MARK: - Recognition State

enum SpeechRecognitionState {
    case idle
    case listening(partialText: String = "")
    case completed(finalText: String)
    case error(SpeechRecognitionError)

    var isListening: Bool {
        if case .listening = self {
            return true
        }
        return false
    }

    var partialText: String {
        if case .listening(let text) = self {
            return text
        }
        return ""
    }

    var finalText: String {
        if case .completed(let text) = self {
            return text
        }
        return ""
    }

    var error: SpeechRecognitionError? {
        if case .error(let error) = self {
            return error
        }
        return nil
    }
}

// MARK: - Recognition Errors

enum SpeechRecognitionError: LocalizedError, Equatable {
    case notAuthorized
    case recognizerNotAvailable
    case audioSessionFailed
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return String(localized: "Speech recognition is not authorized. Please enable it in Settings.")
        case .recognizerNotAvailable:
            return String(localized: "Speech recognition is not available on this device.")
        case .audioSessionFailed:
            return String(localized: "Failed to configure audio session for speech recognition.")
        case .recognitionFailed(let message):
            return String(localized: "Speech recognition failed: \(message)")
        }
    }

    static func == (lhs: SpeechRecognitionError, rhs: SpeechRecognitionError) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthorized, .notAuthorized):
            return true
        case (.recognizerNotAvailable, .recognizerNotAvailable):
            return true
        case (.audioSessionFailed, .audioSessionFailed):
            return true
        case (.recognitionFailed(let lhsMessage), .recognitionFailed(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

// MARK: - Speech Recognition Service Protocol

/// Protocol defining the interface for speech recognition functionality
@MainActor
protocol SpeechRecognitionService: AnyObject {
    /// Current recognition state
    var state: SpeechRecognitionState { get }

    /// Register a handler for recognition state updates
    @discardableResult
    func addStateChangeHandler(_ handler: @escaping (SpeechRecognitionState) -> Void) -> UUID

    /// Remove a previously registered state change handler
    func removeStateChangeHandler(_ token: UUID)

    /// Whether the service has microphone permission
    var hasPermission: Bool { get }

    /// Current audio amplitude for visual feedback
    var currentAmplitude: Double { get }

    /// Request microphone permission for speech recognition
    /// - Returns: True if permission granted, false otherwise
    func requestPermission() async -> Bool

    /// Start speech recognition
    /// - Throws: SpeechRecognitionError if recognition cannot be started
    func startRecognition() async throws

    /// Stop speech recognition and return to idle state
    func stopRecognition()
}

@Observable
@MainActor
class SpeechRecognizer: NSObject, SpeechRecognitionService {
    var state: SpeechRecognitionState = .idle {
        didSet { notifyStateHandlers() }
    }

    /// Async sequence of state changes for Swift concurrency
    var stateValues: AsyncStream<SpeechRecognitionState> {
        AsyncStream { [weak self] continuation in
            guard let self = self else {
                continuation.finish()
                return
            }

            let token = addStateChangeHandler { state in
                continuation.yield(state)
            }
            continuation.onTermination = { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    self.removeStateChangeHandler(token)
                }
            }
        }
    }

    var hasPermission = false
    var currentAmplitude: Double = 0

    let logger = VoiceLogging.recognition
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    private var stateHandlers: [UUID: (SpeechRecognitionState) -> Void] = [:]
    var audioBufferCount = 0

    // Simple flag to prevent double processing
    var hasProcessedFinalResult = false

    // Amplitude monitoring parameters
    var amplitudeHistory: [Double] = []
    let historySize = 10
    let smoothingFactor = 0.8

    override init() {
        super.init()
        speechRecognizer?.delegate = self

        // Check initial permission status
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        hasPermission = authStatus == .authorized
    }

    @discardableResult
    func addStateChangeHandler(_ handler: @escaping (SpeechRecognitionState) -> Void) -> UUID {
        let token = UUID()
        stateHandlers[token] = handler
        handler(state)
        return token
    }

    func removeStateChangeHandler(_ token: UUID) {
        stateHandlers[token] = nil
    }

    func requestPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
                Task { @MainActor in
                    switch authStatus {
                    case .authorized:
                        self?.hasPermission = true
                        continuation.resume(returning: true)
                    case .denied, .restricted:
                        self?.hasPermission = false
                        self?.state = .error(.notAuthorized)
                        continuation.resume(returning: false)
                    case .notDetermined:
                        self?.hasPermission = false
                        continuation.resume(returning: false)
                    @unknown default:
                        self?.hasPermission = false
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }

    func startRecognition() async throws {
        logger.info("START RECOGNITION CALLED")

        try validateAuthorization()
        try ensureRecognizerAvailable()
        cleanUpIfCurrentlyListening()
        try await configureAudioSessionIfNeeded()
        try Task.checkCancellation()

        let request = prepareRecognitionRequest()
        recognitionRequest = request
        hasProcessedFinalResult = false

        configureRecognitionTask(with: request)
        try prepareAudioEngine()

        state = .listening()
        logger.info("START RECOGNITION COMPLETED SUCCESSFULLY")
    }

    func stopRecognition() {
        logger.info("STOP RECOGNITION CALLED")

        // If we're listening and have partial text, complete with that text
        if case .listening(let partialText) = state,
           !partialText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if VoiceLogging.isVerboseEnabled {
                logger.debug("Completing with partial text: \(partialText, privacy: .public)")
            }
            state = .completed(finalText: partialText)
        } else {
            logger.debug("No partial text to use, setting to idle")
            state = .idle
        }

        currentAmplitude = 0

        // Clean up resources
        cleanupRecognition()

        // Deactivate audio session to allow speech synthesis
#if os(iOS)
        Task { @MainActor in
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                logger.debug("Deactivated audio session after speech recognition")
            } catch {
                logger.error("Failed to deactivate audio session: \(error.localizedDescription, privacy: .public)")
            }
        }
#endif
    }

    // MARK: - Private Helper Methods

    private func validateAuthorization() throws {
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        logger.debug("Authorization status: \(authStatus.rawValue)")

        guard authStatus == .authorized else {
            hasPermission = false
            let error = SpeechRecognitionError.notAuthorized
            state = .error(error)
            logger.error("Authorization failed")
            throw error
        }

        hasPermission = true
    }

    private func ensureRecognizerAvailable() throws {
        let isAvailable = speechRecognizer?.isAvailable ?? false
        logger.debug("Speech recognizer available: \(isAvailable)")

        guard isAvailable else {
            let error = SpeechRecognitionError.recognizerNotAvailable
            state = .error(error)
            logger.error("Speech recognizer not available")
            throw error
        }
    }

    private func cleanUpIfCurrentlyListening() {
        guard case .listening = state else {
            logger.debug("Not currently listening, skipping cleanup")
            return
        }

        logger.debug("Currently listening, performing basic cleanup")

        if let task = recognitionTask {
            task.cancel()
            recognitionTask = nil
        }

        if let request = recognitionRequest {
            request.endAudio()
            recognitionRequest = nil
        }

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        let inputNode = audioEngine.inputNode
        if inputNode.numberOfInputs > 0 {
            inputNode.removeTap(onBus: 0)
        }

        hasProcessedFinalResult = true
        state = .idle
        currentAmplitude = 0
    }

    private func cleanupRecognition() {
        logger.debug("CLEANUP RECOGNITION")

        if let task = recognitionTask {
            task.cancel()
            recognitionTask = nil
        }

        if let request = recognitionRequest {
            request.endAudio()
            recognitionRequest = nil
        }

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        let inputNode = audioEngine.inputNode
        if inputNode.numberOfInputs > 0 {
            inputNode.removeTap(onBus: 0)
        }

        hasProcessedFinalResult = true

        logger.debug("CLEANUP COMPLETED")
    }

    private func notifyStateHandlers() {
        // Copy handlers to avoid "Dictionary was modified during iteration" crash
        let handlers = Array(stateHandlers.values)
        for handler in handlers {
            handler(state)
        }
    }
}

// MARK: - SFSpeechRecognitionTaskDelegate
extension SpeechRecognizer: SFSpeechRecognitionTaskDelegate {
    nonisolated func speechRecognitionTask(
        _ task: SFSpeechRecognitionTask,
        didFinishRecognition recognitionResult: SFSpeechRecognitionResult
    ) {
        guard VoiceLogging.isVerboseEnabled else { return }
        let transcript = recognitionResult.bestTranscription.formattedString
        VoiceLogging.recognition.debug("Task delegate final result: \(transcript, privacy: .public)")
    }

    nonisolated func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {
        guard VoiceLogging.isVerboseEnabled else { return }
        VoiceLogging.recognition.debug("Task delegate: finished reading audio")
    }

    nonisolated func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
        guard VoiceLogging.isVerboseEnabled else { return }
        VoiceLogging.recognition.debug("Task delegate: task cancelled")
    }

    nonisolated func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        guard VoiceLogging.isVerboseEnabled else { return }
        VoiceLogging.recognition.debug("Task delegate finished successfully=\(successfully)")
    }
}

// MARK: - SFSpeechRecognizerDelegate
extension SpeechRecognizer: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            if !available {
                VoiceLogging.recognition.error("Speech recognizer availability changed to false")
                self.state = .error(.recognizerNotAvailable)
                self.stopRecognition()
            }
        }
    }
}
