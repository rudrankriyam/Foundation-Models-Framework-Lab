import Foundation
import FoundationModels
import FoundationModelsKit

#if canImport(FoundationModels, _version: 2.2)
@Generable
public struct ProductReview: RuntimeCompatibleGenerable, Sendable, Hashable, Codable {
    @Guide(key: "product_name", description: "Product name")
    public let productName: String

    @Guide(key: "star_rating", description: "Rating from 1 to 5", .range(1...5))
    public let rating: Int

    @Guide(description: "Review text between 50-200 words")
    public let reviewText: String

    @Guide(key: "verdict", description: "Would recommend this product", /Recommended|Not recommended/)
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
#else
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
#endif

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
