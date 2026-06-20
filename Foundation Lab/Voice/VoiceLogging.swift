//
//  VoiceLogging.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 11/14/25.
//

import Foundation
import OSLog

enum VoiceLogging {
    nonisolated private static let subsystem = Bundle.main.bundleIdentifier ?? "FoundationLab"

    nonisolated static let state = Logger(subsystem: subsystem, category: "voice.state")
    nonisolated static let recognition = Logger(subsystem: subsystem, category: "voice.recognition")
    nonisolated static let synthesis = Logger(subsystem: subsystem, category: "voice.synthesis")
    nonisolated static let permissions = Logger(subsystem: subsystem, category: "voice.permissions")
    nonisolated static let health = Logger(subsystem: subsystem, category: "health")

#if DEBUG
    nonisolated private static let verboseFlag = ProcessInfo.processInfo.environment["VOICE_VERBOSE_LOGS"] == "1"
#endif

    nonisolated static var isVerboseEnabled: Bool {
#if DEBUG
        verboseFlag
#else
        false
#endif
    }
}
