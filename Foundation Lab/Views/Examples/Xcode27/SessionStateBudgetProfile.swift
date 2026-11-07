//
//  SessionStateBudgetProfile.swift
//  FoundationLab
//

import FoundationModels

#if canImport(FoundationModels, _version: 2.2)
@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct SessionStateBudgetProfile: LanguageModelSession.DynamicProfile {
    static let replyBudget = 3

    let ledger: SessionStateLedger

    @SessionState private var remainingReplies = Self.replyBudget

    var body: some LanguageModelSession.DynamicProfile {
        if remainingReplies > 0 {
            SessionStateReplyProfile(remainingReplies: $remainingReplies, ledger: ledger)
        } else {
            LanguageModelSession.Profile {
                Instructions(
                    """
                    The reply budget for this session is spent. Reply in one sentence that the budget is used up and that a new \
                    session starts with a fresh budget. Do not answer the request.
                    """
                )
            }
            .maximumResponseTokens(60)
            .onPrompt {
                await ledger.record(.budgetSpent, remainingReplies: remainingReplies)
            }
        }
    }
}
#endif
