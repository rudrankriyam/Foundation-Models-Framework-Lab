//
//  SessionStateBudgetInstructions.swift
//  FoundationLab
//

import FoundationModels

#if canImport(FoundationModels, _version: 2.2)
@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct SessionStateBudgetInstructions: DynamicInstructions {
    @SessionBinding private var remainingReplies: Int

    init(remainingReplies: SessionBinding<Int>) {
        _remainingReplies = remainingReplies
    }

    var body: some DynamicInstructions {
        Instructions(
            """
            You help someone plan a weekend. This session has a reply budget. Replies remaining, including this one: \
            \(remainingReplies). Keep each reply under 120 words. \
            \(remainingReplies == 1 ? "This is the last reply, so give the final plan and say the budget is spent." : "")
            """
        )
    }
}
#endif
