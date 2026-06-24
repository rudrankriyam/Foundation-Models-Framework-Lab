import FoundationModels

/// A `Generable` conformance that remains compatible across Foundation Models runtime revisions.
///
/// Xcode 27 adds more-specific prompt and instruction witnesses to `Generable`. Defining those
/// witnesses in the client prevents binaries built with the newer SDK from requiring them at launch
/// when running on an earlier OS runtime.
@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol RuntimeCompatibleGenerable: Generable {}

public extension RuntimeCompatibleGenerable {
  var promptRepresentation: Prompt {
    Prompt(generatedContent)
  }

  var instructionsRepresentation: Instructions {
    Instructions(generatedContent)
  }
}
