//
//  02_SearchTool.swift
//  Exploring Foundation Models
//
//  Created by Rudrank Riyam on 9/24/25.
//

import Foundation
import FoundationModels
import Playgrounds

struct SearchTool: Tool {
    let name = "searchWeb"
    let description = "Search the web using Search1API's free keyless endpoint"

    @Generable
    struct Arguments {
        @Guide(description: "The search query to look up")
        var query: String
    }

    nonisolated struct SearchResult: Decodable, Sendable {
        let title: String
        let link: String
        let snippet: String?
        let content: String?
    }

    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        let searchQuery = arguments.query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !searchQuery.isEmpty else {
            return createErrorOutput(for: searchQuery, error: SearchError.emptyQuery)
        }

        do {
            let results = try await search(query: searchQuery)
            return createSuccessOutput(query: searchQuery, results: results)
        } catch {
            return createErrorOutput(for: searchQuery, error: error)
        }
    }

    private func search(query: String) async throws -> [SearchResult] {
        guard let url = URL(string: "https://api.search1api.com/search") else {
            throw SearchError.invalidURL
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
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SearchError.apiError
        }
        return try JSONDecoder().decode(SearchResponse.self, from: data).results
    }

    private func createSuccessOutput(query: String, results: [SearchResult]) -> GeneratedContent {
        let summary = results.map {
            "\($0.title)\n\($0.snippet ?? $0.content ?? "No summary available.")\nSource: \($0.link)"
        }.joined(separator: "\n\n")

        return GeneratedContent(properties: [
            "query": query,
            "resultCount": results.count,
            "summary": summary,
            "status": "success"
        ])
    }

    private func createErrorOutput(for query: String, error: Error) -> GeneratedContent {
        GeneratedContent(properties: [
            "query": query,
            "error": "Unable to perform search: \(error.localizedDescription)",
            "resultCount": 0,
            "summary": "Search failed for query: '\(query)'",
            "status": "error"
        ])
    }
}

enum SearchError: Error, LocalizedError {
    case emptyQuery
    case invalidURL
    case apiError

    var errorDescription: String? {
        switch self {
        case .emptyQuery:
            return "Search query cannot be empty"
        case .invalidURL:
            return "Invalid search URL"
        case .apiError:
            return "Search API request failed"
        }
    }
}

nonisolated private struct SearchRequest: Encodable, Sendable {
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

nonisolated private struct SearchResponse: Decodable, Sendable {
    let results: [SearchTool.SearchResult]
}
