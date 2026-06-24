import Foundation
import FoundationModels
import FoundationModelsKit

@Generable
public struct ProductReview: RuntimeCompatibleGenerable, Sendable, Hashable, Codable {
    @Guide(description: "Product name")
    public let productName: String

    @Guide(description: "Rating from 1 to 5")
    public let rating: Int

    @Guide(description: "Review text between 50-200 words")
    public let reviewText: String

    @Guide(description: "Would recommend this product")
    public let recommendation: String

    @Guide(description: "Key pros of the product")
    public let pros: [String]

    @Guide(description: "Key cons of the product")
    public let cons: [String]

    public init(
        productName: String,
        rating: Int,
        reviewText: String,
        recommendation: String,
        pros: [String],
        cons: [String]
    ) {
        self.productName = productName
        self.rating = rating
        self.reviewText = reviewText
        self.recommendation = recommendation
        self.pros = pros
        self.cons = cons
    }
}

public extension ProductReview {
    var plainTextSummary: String {
        """
        Product: \(productName)
        Rating: \(rating)/5

        Pros:
        \(pros.map { "• \($0)" }.joined(separator: "\n"))

        Cons:
        \(cons.map { "• \($0)" }.joined(separator: "\n"))

        Review:
        \(reviewText)

        Recommendation:
        \(recommendation)
        """
    }
}
