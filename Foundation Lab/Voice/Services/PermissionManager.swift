//
//  PermissionManager.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 10/27/25.
//

import Foundation
import FoundationLabCore
import Speech

#if os(iOS)
import AVFoundation
import UIKit
#elseif os(macOS)
import AppKit
import AVFoundation
#endif

enum SpeechAuthorizationRequester {
    nonisolated static func request() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}

// MARK: - Microphone Permission Type

#if os(iOS)
typealias MicrophonePermissionStatus = AVAudioApplication.recordPermission
#else
enum MicrophonePermissionStatus {
    case undetermined
    case denied
    case granted
}
#endif

// MARK: - Permission Service Protocol

/// Protocol defining the interface for permission management
@MainActor
protocol PermissionServiceProtocol: AnyObject {
    /// Microphone permission status
    var microphonePermissionStatus: MicrophonePermissionStatus { get }

    /// Speech recognition permission status
    var speechPermissionStatus: SFSpeechRecognizerAuthorizationStatus { get }

    /// Whether all required permissions are granted
    var allPermissionsGranted: Bool { get }

    /// Whether to show permission alert
    var showPermissionAlert: Bool { get }

    /// Message for permission alert
    var permissionAlertMessage: String { get }

    /// Check current status of all permissions
    func checkAllPermissions()

    /// Request all required permissions
    /// - Returns: True if all permissions granted, false otherwise
    func requestAllPermissions() async -> Bool

    /// Show settings alert for denied permissions
    func showSettingsAlert()

    /// Open system settings for permissions
    func openSettings()
}

// MARK: - Permission Manager Implementation

@MainActor
final class PermissionManager: PermissionServiceProtocol {

#if os(iOS)
    var microphonePermissionStatus: AVAudioApplication.recordPermission = .undetermined {
        didSet { updateAllPermissionsStatus() }
    }
#else
    var microphonePermissionStatus: MicrophonePermissionStatus = .undetermined {
        didSet { updateAllPermissionsStatus() }
    }
#endif

    var speechPermissionStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined {
        didSet { updateAllPermissionsStatus() }
    }
    var allPermissionsGranted = false
    var showPermissionAlert = false
    var permissionAlertMessage = ""
    private var activePermissionRequest: Task<Bool, Never>?

    init() {
        initializeAudioSessionIfNeeded()
        checkAllPermissions()
    }

    private func initializeAudioSessionIfNeeded() {
        #if os(iOS)
        // Initialize AVAudioSession early to prevent factory registration issues
        let audioSession = AVAudioSession.sharedInstance()
        // Just access the shared instance to ensure it's initialized
        _ = audioSession
        #endif
    }

    func checkAllPermissions() {
        checkMicrophonePermission()
        checkSpeechPermission()
        updateAllPermissionsStatus()
    }

    func requestAllPermissions() async -> Bool {
        if let activePermissionRequest {
            return await activePermissionRequest.value
        }

        let request = Task { @MainActor [weak self] in
            guard let self else { return false }
            return await self.performPermissionRequest()
        }
        activePermissionRequest = request
        let granted = await request.value
        activePermissionRequest = nil
        return granted
    }

    private func performPermissionRequest() async -> Bool {
        checkAllPermissions()
        guard await requestMicrophonePermission() else {
            showSettingsAlert()
            return false
        }

        guard await requestSpeechPermission() else {
            showSettingsAlert()
            return false
        }

        checkAllPermissions()
        updateAllPermissionsStatus()
        if allPermissionsGranted {
            permissionAlertMessage = ""
            showPermissionAlert = false
        } else {
            showSettingsAlert()
        }
        return allPermissionsGranted
    }

    // MARK: - Microphone Permission

#if os(iOS)
    private func checkMicrophonePermission() {
        let status = AVAudioApplication.shared.recordPermission
        microphonePermissionStatus = status
    }

    private func requestMicrophonePermission() async -> Bool {
        checkMicrophonePermission()
        switch microphoneAuthorization.requestAction {
        case .returnAuthorized:
            return true
        case .returnDenied:
            return false
        case .requestAccess:
            let granted = await AVAudioApplication.requestRecordPermission()
            microphonePermissionStatus = granted ? .granted : .denied
            return granted
        }
    }
#else
    private func checkMicrophonePermission() {
        // This startup check must stay side-effect free. Starting an audio input path here
        // asks for access when the status is undetermined and can repeatedly prompt as views reload.
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined:
            microphonePermissionStatus = .undetermined
        case .restricted, .denied:
            microphonePermissionStatus = .denied
        case .authorized:
            microphonePermissionStatus = .granted
        @unknown default:
            microphonePermissionStatus = .denied
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        checkMicrophonePermission()
        switch microphoneAuthorization.requestAction {
        case .returnAuthorized:
            return true
        case .returnDenied:
            return false
        case .requestAccess:
            let granted = await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            }
            microphonePermissionStatus = granted ? .granted : .denied
            return granted
        }
    }
    #endif

    // MARK: - Speech Recognition Permission

    private func checkSpeechPermission() {
        speechPermissionStatus = SFSpeechRecognizer.authorizationStatus()
    }

    private func requestSpeechPermission() async -> Bool {
        checkSpeechPermission()
        switch speechAuthorization.requestAction {
        case .returnAuthorized:
            return true
        case .returnDenied:
            return false
        case .requestAccess:
            let status = await SpeechAuthorizationRequester.request()
            speechPermissionStatus = status
            return status == .authorized
        }
    }

    // MARK: - Helpers

    private func updateAllPermissionsStatus() {
        let micGranted = microphonePermissionStatus == .granted
        let speechGranted = speechPermissionStatus == .authorized

        allPermissionsGranted = micGranted && speechGranted
    }

    private var microphoneAuthorization: VoicePermissionAuthorization {
        switch microphonePermissionStatus {
        case .undetermined:
            .notDetermined
        case .denied:
            .denied
        case .granted:
            .authorized
        @unknown default:
            .denied
        }
    }

    private var speechAuthorization: VoicePermissionAuthorization {
        switch speechPermissionStatus {
        case .notDetermined:
            .notDetermined
        case .denied, .restricted:
            .denied
        case .authorized:
            .authorized
        @unknown default:
            .denied
        }
    }

    func showSettingsAlert() {
        var deniedPermissions: [String] = []

        if microphonePermissionStatus == .denied {
            deniedPermissions.append("Microphone")
        }

        if speechPermissionStatus == .denied || speechPermissionStatus == .restricted {
            deniedPermissions.append("Speech Recognition")
        }

        if deniedPermissions.isEmpty {
            permissionAlertMessage = "Microphone and Speech Recognition access are required to use Voice."
        } else {
            let permissionsList = deniedPermissions.joined(separator: ", ")
            permissionAlertMessage = "Please enable \(permissionsList) in Settings to use Voice features."
        }
        showPermissionAlert = true
    }

    func openSettings() {
        #if os(iOS)
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
        #elseif os(macOS)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
            NSWorkspace.shared.open(url)
        }
        #endif
    }
}
