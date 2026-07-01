import Foundation
import FoundationModelsKit

public struct SearchContactsUseCase: FoundationModelCapabilityUseCase {
    public static let descriptor = FoundationModelCapabilityDescriptor(
        id: "foundation-models.search-contacts",
        displayName: "Search Contacts",
        summary: "Searches the user's contacts using a shared Foundation Models capability."
    )

    private let searcher: any ContactsSearching

    public init(searcher: any ContactsSearching = FoundationModelsContactsSearcher()) {
        self.searcher = searcher
    }

    public func execute(_ request: SearchContactsRequest) async throws -> FoundationModelTextGenerationResult {
        let query = request.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing query")
        }

        return try await searcher.searchContacts(for: request)
    }
}
