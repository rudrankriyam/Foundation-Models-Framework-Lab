import Foundation
import FoundationModelsKit

public protocol ContactsSearching: Sendable {
    func searchContacts(for request: SearchContactsRequest) async throws -> FoundationModelTextGenerationResult
}
