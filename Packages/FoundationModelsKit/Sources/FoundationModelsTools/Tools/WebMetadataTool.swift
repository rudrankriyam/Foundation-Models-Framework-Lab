//
//  WebMetadataTool.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import Foundation
import FoundationModels
import FoundationModelsKit
import LinkPresentation

/// A tool for extracting metadata from web pages using LinkPresentation.
///
/// Use `WebMetadataTool` to fetch and extract metadata from URLs including
/// page title and image availability. No API key is required.
///
/// Returns `url`, `title`, `description` (currently empty due to API limitations),
/// and `imageURL` (indicates if an image is available).
///
/// ```swift
/// let session = LanguageModelSession(tools: [WebMetadataTool()])
/// let response = try await session.respond(to: "Summarize this page: https://apple.com")
/// ```
///
/// - Note: Description extraction is not available through public API.
///   Image data is detected but not returned directly.
public struct WebMetadataTool: Tool {

  /// The name of the tool, used for identification.
  public let name = "getWebMetadata"
  /// A brief description of the tool's functionality.
  public let description =
    "Extract metadata from web pages including title, description, and images"

  /// Arguments for web metadata extraction.
  @Generable
  public struct Arguments: RuntimeCompatibleGenerable {
    /// The URL to extract metadata from
    @Guide(description: "The URL to extract metadata from")
    public var url: String

    public init(url: String = "") {
      self.url = url
    }
  }

  /// Extracted metadata from a web page
  public struct WebMetadata {
    public let url: String
    public let title: String
    public let description: String
    public let imageURL: String?
  }

  public init() {}

  public func call(arguments: Arguments) async throws -> some PromptRepresentable {
    let urlString = arguments.url.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !urlString.isEmpty else {
      return createErrorOutput(for: urlString, error: WebMetadataError.emptyURL)
    }

    guard let url = URL(string: urlString) else {
      return createErrorOutput(for: urlString, error: WebMetadataError.invalidURL)
    }

    do {
      let metadata = try await fetchMetadata(from: url)
      let webMetadata = extractBasicMetadata(from: metadata, url: url)
      return createSuccessOutput(from: webMetadata)
    } catch {
      return createErrorOutput(for: urlString, error: error)
    }
  }

  private func fetchMetadata(from url: URL) async throws -> LPLinkMetadata {
    let provider = LPMetadataProvider()

    do {
      let metadata = try await provider.startFetchingMetadata(for: url)
      return metadata
    } catch {
      throw WebMetadataError.fetchFailed(error)
    }
  }

  private func extractBasicMetadata(from metadata: LPLinkMetadata, url: URL) -> WebMetadata {
    let title = metadata.title ?? "Untitled"
    // Note: LPLinkMetadata does not expose a public API for page description/summary.
    // The description field will be empty. Consider using alternative approaches like
    // fetching and parsing the HTML meta description tag directly if needed.
    let description = ""
    let imageURL = metadata.imageProvider != nil ? "Image available" : nil

    return WebMetadata(
      url: url.absoluteString,
      title: title,
      description: description,
      imageURL: imageURL
    )
  }

  private func createSuccessOutput(from metadata: WebMetadata) -> GeneratedContent {
    return GeneratedContent(properties: [
      "status": "success",
      "url": metadata.url,
      "title": metadata.title,
      "description": metadata.description,
      "imageURL": metadata.imageURL ?? "",
      "message": "Successfully extracted web metadata"
    ])
  }

  private func createErrorOutput(for url: String, error: Error) -> GeneratedContent {
    return GeneratedContent(properties: [
      "status": "error",
      "url": url,
      "error": error.localizedDescription,
      "message": "Failed to fetch web metadata"
    ])
  }
}

enum WebMetadataError: Error, LocalizedError {
  case emptyURL
  case invalidURL
  case fetchFailed(Error)

  var errorDescription: String? {
    switch self {
    case .emptyURL:
      return "URL cannot be empty"
    case .invalidURL:
      return "Invalid URL format"
    case .fetchFailed(let error):
      return "Failed to fetch metadata: \(error.localizedDescription)"
    }
  }
}
