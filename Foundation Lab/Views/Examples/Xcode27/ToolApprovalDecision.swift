//
//  ToolApprovalDecision.swift
//  FoundationLab
//

import SwiftUI

enum ToolApprovalDecision {
    case notPrepared
    case awaitingUser
    case approvedForDemo
    case denied

    var title: String {
        switch self {
        case .notPrepared: String(localized: "No proposed action")
        case .awaitingUser: String(localized: "Waiting for the user")
        case .approvedForDemo: String(localized: "Approved in this demo")
        case .denied: String(localized: "Denied by the user")
        }
    }

    var detail: String {
        switch self {
        case .notPrepared: String(localized: "Run prepares a local review record from the prompt.")
        case .awaitingUser: String(localized: "Nothing has been sent. The app must wait at this boundary.")
        case .approvedForDemo:
            String(localized: "The demo recorded approval but intentionally has no message transport, so nothing was sent.")
        case .denied: String(localized: "The app stopped the proposed action before any side effect.")
        }
    }

    var icon: String {
        switch self {
        case .notPrepared: "tray"
        case .awaitingUser: "hand.raised"
        case .approvedForDemo: "checkmark.circle.fill"
        case .denied: "xmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .notPrepared: .secondary
        case .awaitingUser: .orange
        case .approvedForDemo: .green
        case .denied: .red
        }
    }

    var awaitsDecision: Bool { self == .awaitingUser }
}
