import Foundation
import FoundationModels

public struct Search1WebSearchTool: Tool {
    public let name = "searchWeb"
    public let description = "Search the web using Search1API's free keyless endpoint"

    public init() {}

    @Generable
    public struct Arguments {
        @Guide(description: "The search query to look up on the web.")
        public var query: String

        public init(query: String) {
            self.query = query
        }
    }

    public func call(arguments: Arguments) async throws -> some PromptRepresentable {
        let query = arguments.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return createErrorOutput(for: query, message: "Search query cannot be empty.")
        }

        do {
            let response = try await search(query: query)
            return createSuccessOutput(for: query, results: response.results)
        } catch {
            return createErrorOutput(for: query, message: "Web search failed: \(error.localizedDescription)")
        }
    }
}

extension Search1WebSearchTool {
    private static let apiURL = URL(string: "https://api.search1api.com/search")

    private func search(query: String) async throws -> SearchResponse {
        guard let url = Self.apiURL else {
            throw Search1WebSearchError.invalidURL
        }

        let payload = SearchRequest(
            query: query,
            searchService: "google",
            maxResults: 5,
            crawlResults: 0,
            image: false,
            includeSites: [],
            excludeSites: [],
            language: "en",
            timeRange: "year"
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw Search1WebSearchError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw Search1WebSearchError.httpStatus(code: httpResponse.statusCode, body: body)
        }

        return try JSONDecoder().decode(SearchResponse.self, from: data)
    }

    private func createSuccessOutput(for query: String, results: [SearchResult]) -> GeneratedContent {
        if results.isEmpty {
            return GeneratedContent(properties: [
                "status": "empty",
                "query": query,
                "resultCount": 0,
                "summary": "No results found for \"\(query)\"."
            ])
        }

        let summary = results.prefix(5).enumerated().map { index, result in
            let snippet = result.snippet ?? result.content ?? "No summary available."
            return """
            \(index + 1). \(result.title)
            \(snippet)
            \(result.link)
            """
        }.joined(separator: "\n\n")

        return GeneratedContent(properties: [
            "status": "success",
            "query": query,
            "resultCount": results.count,
            "summary": summary
        ])
    }

    private func createErrorOutput(for query: String, message: String) -> GeneratedContent {
        GeneratedContent(properties: [
            "status": "error",
            "query": query,
            "resultCount": 0,
            "summary": message
        ])
    }
}

private struct SearchRequest: Encodable {
    let query: String
    let searchService: String
    let maxResults: Int
    let crawlResults: Int
    let image: Bool
    let includeSites: [String]
    let excludeSites: [String]
    let language: String
    let timeRange: String

    enum CodingKeys: String, CodingKey {
        case query
        case searchService = "search_service"
        case maxResults = "max_results"
        case crawlResults = "crawl_results"
        case image
        case includeSites = "include_sites"
        case excludeSites = "exclude_sites"
        case language
        case timeRange = "time_range"
    }
}

private struct SearchResponse: Decodable {
    let results: [SearchResult]
}

private struct SearchResult: Decodable {
    let title: String
    let link: String
    let snippet: String?
    let content: String?
}

private enum Search1WebSearchError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(code: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "Invalid Search1API URL.")
        case .invalidResponse:
            return String(localized: "Invalid response from Search1API.")
        case let .httpStatus(code, _):
            switch code {
            case 401, 403:
                return String(localized: "Search1API keyless access is unavailable right now. Please try again later.")
            case 429:
                return String(localized: "Search1API keyless access is rate-limited. Please wait and try again.")
            default:
                return String(localized: "Search1API returned HTTP \(code).")
            }
        }
    }
}
