import Foundation
import FoundationLabCore
import FoundationModelsKit
import FoundationModels

extension ChatViewModel {
    func tearDown() {
        cancelGeneration()
        suspendVoiceMode()
    }

    /// Releases microphone and speech resources without canceling an active text response.
    func suspendVoiceMode() {
        activeVoiceStartID = nil
        stopSpeechObservation()
        speechRecognizer?.stopRecognition()
        speechRecognizer = nil
        speechSynthesizer.cancelSpeaking()
        voiceState = .idle
    }

    func startVoiceMode() async {
        guard let startID = beginVoiceStart() else { return }

        let granted = await permissionManager.requestAllPermissions()
        guard canContinueVoiceStart(startID) else { return }
        guard granted else {
            handleVoiceError(permissionManager.permissionAlertMessage)
            return
        }

        await activateVoiceRecognizer(for: startID)
    }

    private func beginVoiceStart() -> UUID? {
        guard !isLoading, !session.isResponding else { return nil }

        if case .error = voiceState {
            errorMessage = nil
            showError = false
            voiceState = .idle
        } else if voiceState.isActive {
            return nil
        }

        let startID = UUID()
        activeVoiceStartID = startID
        voiceState = .preparing
        return startID
    }

    private func activateVoiceRecognizer(for startID: UUID) async {
        conversationEngine.prewarm()
        stopSpeechObservation()
        speechRecognizer?.stopRecognition()
        speechRecognizer = nil

        let recognizer: SpeechRecognizer
        do {
            recognizer = try await makeStartedSpeechRecognizer()
        } catch is CancellationError {
            abandonVoiceStart(startID)
            return
        } catch {
            guard activeVoiceStartID == startID else { return }
            handleVoiceError(error.localizedDescription)
            return
        }

        guard canContinueVoiceStart(startID) else {
            recognizer.stopRecognition()
            return
        }
        speechRecognizer = recognizer
        activeVoiceStartID = nil
        voiceState = .listening(partialText: "")
        startSpeechObservation()
    }

    private func canContinueVoiceStart(_ startID: UUID) -> Bool {
        if Task.isCancelled {
            abandonVoiceStart(startID)
            return false
        }
        guard activeVoiceStartID == startID, case .preparing = voiceState else { return false }
        return true
    }

    private func abandonVoiceStart(_ startID: UUID) {
        guard activeVoiceStartID == startID else { return }
        activeVoiceStartID = nil
        voiceState = .idle
    }

    func cancelVoiceMode() {
        suspendVoiceMode()
        errorMessage = nil
        showError = false
    }

    func stopSpeaking() {
        guard case .speaking = voiceState else { return }
        speechSynthesizer.cancelSpeaking()
    }

    func stopVoiceModeAndSend() async -> (prompt: String, response: String)? {
        guard case .listening(let text) = voiceState else { return nil }
        guard !isLoading, !session.isResponding else { return nil }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            cancelVoiceMode()
            return nil
        }

        guard let recognizer = speechRecognizer else {
            handleVoiceError("Speech recognizer not initialized")
            return nil
        }
        recognizer.stopRecognition()
        voiceState = .processing
        isLoading = true

        do {
            let response = try await conversationEngine.sendMessage(
                trimmedText,
                generationOptions: generationOptions
            )
            isLoading = false
            syncConversationState()
            guard case .processing = voiceState else {
                return (trimmedText, response)
            }
            voiceState = .speaking(response: response)
            await speak(response)
            return (trimmedText, response)
        } catch is CancellationError {
            isLoading = false
            voiceState = .idle
            return nil
        } catch {
            isLoading = false
            handleVoiceError(message(for: error))
            return nil
        }
    }
}

extension ChatViewModel {
    func speak(_ response: String) async {
        do {
            try await speechSynthesizer.synthesizeAndSpeak(text: response)
            guard case .speaking = voiceState else { return }
            await restartListening()
        } catch let synthError as SpeechSynthesizerError {
            if case .cancelled = synthError {
                guard case .speaking = voiceState else { return }
                await restartListening()
                return
            }
            handleVoiceError(synthError.localizedDescription)
        } catch {
            handleVoiceError(error.localizedDescription)
        }
    }

    func makeStartedSpeechRecognizer() async throws -> SpeechRecognizer {
        let recognizer = SpeechRecognizer()
        do {
            try await recognizer.startRecognition()
            return recognizer
        } catch {
            recognizer.stopRecognition()
            throw error
        }
    }

    func startSpeechObservation() {
        stopSpeechObservation()
        speechObservationTask = Task { @MainActor [weak self] in
            await self?.observeSpeechState()
        }
    }

    func stopSpeechObservation() {
        speechObservationTask?.cancel()
        speechObservationTask = nil
    }

    func restartListening() async {
        guard let recognizer = speechRecognizer else {
            handleVoiceError("Speech recognizer not initialized")
            return
        }

        do {
            try await recognizer.startRecognition()
            try Task.checkCancellation()
            voiceState = .listening(partialText: "")
        } catch is CancellationError {
            return
        } catch {
            handleVoiceError(error.localizedDescription)
        }
    }

    func handleVoiceError(_ message: String) {
        activeVoiceStartID = nil
        stopSpeechObservation()
        speechRecognizer?.stopRecognition()
        speechRecognizer = nil
        errorMessage = message
        showError = true
        voiceState = .error(message: message)
    }

    func message(for error: Error) -> String {
        let handledMessage = FoundationModelsErrorHandler.handleError(error)
        let opaqueFailure = handledMessage.contains("GenerationError error -1")
            || handledMessage.contains("LanguageModel-Error error -1")
            || error.localizedDescription.contains("GenerationError error -1")
            || error.localizedDescription.contains("LanguageModel-Error error -1")

        if selectedModelRuntime == .onDevice {
            if opaqueFailure {
                return String(
                    localized: """
                    The on-device model could not start. Make sure Apple Intelligence is enabled \
                    and ready, then try again.
                    """
                )
            }
            return handledMessage
        }

        if handledMessage.hasPrefix("PCC ") {
            return handledMessage
        }
        if opaqueFailure {
            return String(
                localized: """
                PCC request failed. Private Cloud Compute is available, but this app may be missing \
                the PCC entitlement or a matching provisioning profile.

                Confirm com.apple.developer.private-cloud-compute is present, then try again. \
                Details: \(handledMessage)
                """
            )
        }
        return String(localized: "The Private Cloud Compute request failed. \(handledMessage)")
    }

    func observeSpeechState() async {
        guard let recognizer = speechRecognizer else { return }

        for await state in recognizer.stateValues {
            switch state {
            case .listening(let partialText):
                if case .listening = voiceState {
                    voiceState = .listening(partialText: partialText)
                }
            case .completed(let finalText):
                if case .listening = voiceState {
                    voiceState = .listening(partialText: finalText)
                }
            case .error(let speechError):
                handleVoiceError(speechError.localizedDescription)
            case .idle:
                break
            }
        }
    }
}
