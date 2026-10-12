import Foundation
import FoundationModels

/// An explicit gap until this adapter can read an attested option chain.
public struct GlintOptionChainTool: Tool, Sendable {
    public let name = "glintOptionChain"
    public let description = "Reports that option-chain data is not connected. Does not provide PCR, open interest, strikes, or trading signals."

    @Generable
    public struct Arguments: Sendable {
        @Guide(description: "Underlying index symbol, such as NIFTY or BANKNIFTY")
        public var underlying: String

        public init(underlying: String = "NIFTY") {
            self.underlying = underlying
        }
    }

    public init() {}

    public func call(arguments: Arguments) async throws -> String {
        """
        Glint option chain
        status=unavailable
        gap=option_chain_not_connected
        No option-chain observation is available. PCR and open interest are unavailable.
        orders=locked
        """
    }
}
