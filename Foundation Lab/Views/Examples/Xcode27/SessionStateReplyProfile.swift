//
//  SessionStateReplyProfile.swift
//  FoundationLab
//

import FoundationModels

#if canImport(FoundationModels, _version: 2.2)
@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct SessionStateReplyProfile: LanguageModelSession.DynamicProfile {
    @SessionBinding private var remainingReplies: Int
    let ledger: SessionStateLedger

    init(remainingReplies: SessionBinding<Int>, ledger: SessionStateLedger) {
        _remainingReplies = remainingReplies
        self.ledger = ledger
    }

    var body: some LanguageModelSession.DynamicProfile {
        LanguageModelSession.Profile {
            SessionStateBudgetInstructions(remainingReplies: $remainingReplies)
        }
        .temperature(0.3)
        .maximumResponseTokens(240)
        .onPrompt {
            await ledger.record(.prompt, remainingReplies: remainingReplies)
        }
        .onResponse {
            remainingReplies -= 1
            await ledger.record(.response, remainingReplies: remainingReplies)
        }
    }
}
#endif
