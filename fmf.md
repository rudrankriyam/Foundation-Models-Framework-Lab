## Xcode 27 Foundation Models API Delta

Source: Xcode 27.3 beta (build `27C5020n`) FoundationModels Swift interface
(`10145` lines), synthesized from the iOS SDK public module surface
with an iOS 26.0 deployment target.

This section records the new public API shape found in Xcode 27. The raw Swift
interface reference below is refreshed from the Xcode 27.3 beta SDK.

### Xcode 27.3 beta changes

Compared with Xcode 27.2 beta (build `27B5019j`), the last interface recorded
here:

- Foundation Models comes to tvOS. Declarations previously marked
  `@available(tvOS, unavailable)` now carry `tvOS 27.0`, matching their watchOS
  floor. `SystemLanguageModel`, its availability, use cases, guardrails, and
  executor, plus `LanguageModelSession.init(model:dynamicInstructions:history:)`
  and `GenerationError.Refusal.explanationStream`, are available from
  `tvOS 27.3`. `PrivateCloudComputeLanguageModel`, `SystemLanguageModel.Adapter`,
  image attachments, and the deprecated `source`-based and `sampling:` initializers
  stay unavailable on tvOS.
- `LanguageModelSession.SessionState` and `LanguageModelSession.SessionBinding`
  are new property wrappers. `@SessionState` owns mutable state for a session's
  lifetime; its projected value is a `SessionBinding` that child dynamic
  instructions or profiles receive through an initializer. Both are marked
  available from 27.0 and are exposed as `SessionState` and `SessionBinding`
  typealiases on `DynamicInstructions` and `DynamicProfile`. `SessionState` is
  `Sendable` when `Value` is.
- `DynamicInstructionsGroup` (also `DynamicInstructions.Group`) groups dynamic
  instructions so one `onActivate` or `onDeactivate` applies to the whole group.
  `DynamicInstructions` gains `onActivate(perform:)` and
  `onDeactivate(perform:)`, matching the existing `DynamicProfile` modifiers.
  These are marked 27.2, but they weren't in the 27.2 beta interface.
- `@Guide` gains `key:` overloads, `Guide(key:description:)`,
  `Guide(key:description:_:)` with `GenerationGuide` values, and a `Regex`
  form. These name the generated property's key independently of the Swift
  property name, and they're available from iOS and macOS 26.0.
- `DynamicProfile.onDataEntry(perform:)` runs an action when the profile
  produces a `Transcript.DataEntry`, with a parameterless overload. It needs
  27.3, and data entries only appear for models whose
  `supportsDataEntryType(_:)` accepts the content type.
- The normalized synthesized interface shrinks from 10,315 to 10,145 lines,
  mostly from dropping the per-declaration `tvOS, unavailable` attributes. The
  framework's text-based stub moves from version `2.1.7` to `2.2.6`.

Verified on November 7, 2026, against the installed Xcode 27.3 beta iOS SDK.
The [Xcode 27.3 beta release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27_3-release-notes)
have no Foundation Models entry.

### Xcode 27.2 beta changes

Compared with Xcode 27.0 Release Candidate (build `27A266a`):

- Foundation Models adds portable, `UTType`-identified binary content.
  `DataAttachmentRepresentable` converts custom prompt attachment values to and
  from `Transcript.DataAttachment`; `DataEntryRepresentable` does the same for
  custom top-level model output through `Transcript.DataEntry`. Both transcript
  payloads carry `Data` plus optional `GeneratedContent` metadata. These APIs
  are available on iOS, macOS, visionOS, and watchOS 27.2; tvOS is unavailable.
- `Attachment` can wrap a `DataAttachmentRepresentable` value. Transcript
  attachments and entries add `.data` cases, allowing custom binary formats to
  survive transcript encoding even when the declaring package isn't installed.
- Custom `LanguageModel` implementations declare accepted content types with
  the asynchronous `supportsDataAttachmentType(_:)` and
  `supportsDataEntryType(_:)` requirements. Custom executors can emit or update
  a top-level data entry with the generation channel's new `.data` event.
- `GenerationSchema.SchemaError`, `LanguageModelError`, `Transcript.Entry`,
  `Transcript.Segment`, `Transcript.Attachment`, and
  `Transcript.ResponseFormat.Kind` are now explicitly `@nonexhaustive`.
- The normalized synthesized interface grows from 9,705 to 10,315 lines. Most
  remaining churn is expanded API documentation rather than signature changes;
  the framework's text-based stub moves from version `2.0.68` to `2.1.7` and
  exports the new data-content symbols.

Verified on September 17, 2026, against the installed Xcode 27.2 beta iOS SDK
and Apple's live DocC JSON for
[`DataAttachmentRepresentable`](https://developer.apple.com/documentation/foundationmodels/dataattachmentrepresentable),
[`DataEntryRepresentable`](https://developer.apple.com/documentation/foundationmodels/dataentryrepresentable),
[`Transcript.DataAttachment`](https://developer.apple.com/documentation/foundationmodels/transcript/dataattachment),
and
[`Transcript.DataEntry`](https://developer.apple.com/documentation/foundationmodels/transcript/dataentry).
The [Xcode 27.2 beta release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27_2-release-notes)
don't include a Foundation Models section, so the installed SDK remains the
source of truth for the complete public-surface diff.

### Release Candidate changes

Compared with Xcode 27 beta 6 (build `27A5252f`):

- The public Foundation Models interface is unchanged. Both SDKs produce
  9,705-line exports with `swift-synthesize-interface`, targeting
  `arm64-apple-ios26.0`. Their normalized content matches the raw reference
  below, so there are no declarations or signatures to update.
- The iOS SDK's `.swiftinterface` module flags and `.tbd` target lists add
  `arm64e.x1` alongside `arm64e`. The exported symbols are unchanged; this
  architecture metadata does not require a Foundation Models source migration.

Verified on September 10, 2026, using the installed Developer Documentation
release `2023` and Apple's live DocC JSON. The
[Core AI model guide](https://developer.apple.com/documentation/foundationmodels/running-a-core-ai-model-in-a-foundation-models-session)
still uses `CoreAILanguageModel` from the separate `coreai-models` package.

The [Xcode 27 RC release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes)
describe the Foundation Models Instrument for inspecting instructions, prompts,
responses, token usage, and inference performance. This is a tooling note,
separate from the SDK interface comparison.

An unchanged interface does not establish identical model output. Apple's
[prompt-versioning guide](https://developer.apple.com/documentation/foundationmodels/updating-prompts-for-new-model-versions)
recommends comparing responses when the underlying model changes and updating
prompts where needed.

### Beta 6 changes

Compared with the Xcode 27 beta 5 SDK interface:

- The public Foundation Models interface is unchanged. Both SDKs synthesize to
  9,705 lines, and their normalized interface content is identical.
- The Foundation Models documentation adds “Running a Core AI model in a
  Foundation Models session.” It uses `CoreAILanguageModel` from Apple's
  external `coreai-models` package with `LanguageModelSession`; it does not add
  a declaration to the Foundation Models SDK.

Apple's Xcode 27 beta 6 release notes contain no Foundation Models API entry.
The installed Xcode 27 documentation archive (`10M13878`) contains the Core AI
guide, while the installed SDK remains the source of truth for the public
interface result.

### Beta 5 changes

Compared with the Xcode 27 beta 4 SDK interface:

- `SystemLanguageModel` exposes its `variant`, with the new
  `SystemLanguageModel.Variant` values `.core3` and `.coreAdvanced3` plus a
  display name. The beta 5 documentation describes three model generations
  aligned with OS 26.0–26.3, 26.4, and 27.0.
- `PrivateCloudComputeLanguageModel.supportedLanguages` and
  `supportsLocale(_:)` are now asynchronous and throwing.
- Session, executor, usage, and transcript metadata inputs now accept
  `ConvertibleToGeneratedContent`; stored metadata is normalized to
  `[String: GeneratedContent]`.
- `Transcript.history` and `SessionPropertyValues.history` now use the mutable,
  random-access `Transcript.HistoryView` instead of `ArraySlice`.
- The public custom-transcript-segment path is removed, including
  `Transcript.CustomSegment`, `Transcript.Segment.custom`, and the executor's
  `updateCustomSegment` action.
- Deprecated compatibility APIs are gone, including
  `LanguageModelCapabilities.init(capabilities:)` and
  `ImageReference.resolve(in:)`. The dynamic-instructions session initializer
  is now available on watchOS 27.

The installed Xcode 27 documentation archive (`10M13753`) describes the three
model generations, while Apple's live DocC JSON confirms
`SystemLanguageModel.Variant`, `Transcript.HistoryView`, and the asynchronous
PCC locale APIs. The installed SDK remains the source of truth for the complete
public-surface diff, including the removals and metadata signature changes.

### Beta 4 changes

Compared with the Xcode 27 beta 3 SDK interface:

- `LanguageModelExecutorGenerationChannel.Usage` adds metadata, and the
  response, reasoning, and tool-call `updateUsage` factories accept it.
- Executor retraction actions now remove attachments and tool calls by ID
  instead of requiring a complete transcript value.
- `LanguageModelSession.Response` is `Sendable` when its generated content is
  `Sendable`. Session usage metadata is now exposed as `[String: any Sendable]`.
- `ImageReference.resolved(in:)` accepts any sequence of transcript entries and
  returns the latest matching attachment. `resolve(in:)` is deprecated.

Refreshing the raw reference also reconciles beta 3 SDK shapes that the stored
snapshot missed, including the concrete generation-channel event and action
types, unconstrained attachment wrappers, `Transcript.ResponseFormat.Kind`,
and the removal of deprecated dynamic-profile aliases.

### Beta 3 changes

Compared with the Xcode 27 beta 2 interface:

- `GenerationOptions.SamplingMode.Kind` renames the stored random cases from
  `top(k:seed:)` and `nucleus(threshold:seed:)` to `randomTopK(_:seed:)` and
  `randomProbabilityThreshold(_:seed:)`. The public factory methods remain
  `random(top:seed:)` and `random(probabilityThreshold:seed:)`.
- `LanguageModelSession.DynamicProfile` adds `onReasoning` lifecycle hooks for
  observing model reasoning as it works toward a response. Reasoning is only
  produced by models that declare the `.reasoning` capability.

### Beta 2 changes

Compared with the previous Xcode 27 beta interface:

- `DynamicInstructionsForEach` and `DynamicInstructions.ForEach` add collection
  support to the dynamic instructions result builder, including limited
  availability handling.
- `LanguageModelSession.AnyDynamicProfile` adds type erasure for dynamic
  profiles. The profile builder also gains limited availability handling and an
  overload that accepts `any LanguageModel`.
- `LanguageModelError.Refusal` now exposes an async `explanation`, an
  `explanationStream`, and an initializer that accepts the explanation text.
- `GenerationSchema.name` and `LanguageModelCapabilities.init(_:)` are new.
- The public interface no longer exposes the beta 1 `AnyTool` type eraser,
  `GeneratedContent.null`, the `Result` prompt conformance,
  `SessionPropertyValues.rootDynamicInstructions`, or
  `Transcript.CustomSegment.isEqual(to:)`.

### Private Cloud Compute model

```swift
@available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
final public class PrivateCloudComputeLanguageModel: Sendable, Observable, LanguageModel {
    public convenience init()

    public var availability: PrivateCloudComputeLanguageModel.Availability { get }
    public var quotaUsage: PrivateCloudComputeLanguageModel.QuotaUsage { get }
    public var isAvailable: Bool { get }
    public var capabilities: LanguageModelCapabilities { get }
    public var contextSize: Int { get async throws }
    public var supportedLanguages: Set<Locale.Language> { get async throws }

    public func supportsLocale(_ locale: Locale = .current) async throws -> Bool
}
```

`PrivateCloudComputeLanguageModel.Availability.UnavailableReason` has `deviceNotEligible` and `systemNotReady`. `PrivateCloudComputeLanguageModel.Error` adds `networkFailure`, `quotaLimitReached`, and `serviceUnavailable`. Quota usage reports whether the limit is reached, when it resets, and may expose a `LimitIncreaseSuggestion.show()` action.

### Shared language model execution

```swift
@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension SystemLanguageModel: LanguageModel {
    public var capabilities: LanguageModelCapabilities { get }
}

@available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
public protocol LanguageModel: Sendable {
    associatedtype Executor: LanguageModelExecutor where Self == Self.Executor.Model

    var capabilities: LanguageModelCapabilities { get }
    var executorConfiguration: Executor.Configuration { get }
}
```

`LanguageModelCapabilities` includes `.vision`, `.guidedGeneration`, `.reasoning`, and `.toolCalling`.

### Dynamic instructions and profiles

Xcode 27 adds a richer session configuration DSL:

```swift
public protocol DynamicInstructions { associatedtype Body: DynamicInstructions }
public struct AnyDynamicInstructions: DynamicInstructions
public struct DynamicInstructionsBuilder

extension LanguageModelSession {
    public struct Profile
    public protocol DynamicProfile

    public convenience init(profile: LanguageModelSession.Profile, history: Transcript = Transcript())
    public convenience init(
        model: some LanguageModel,
        dynamicInstructions: some DynamicInstructions,
        history: Transcript = Transcript()
    )
}
```

Dynamic profile modifiers include model selection, temperature, `samplingMode`, `maximumResponseTokens`, `reasoningLevel`, `toolCallingMode`, history transforms, and lifecycle hooks such as prompt, response, tool-call, and tool-output handlers.

The interface also adds type-erased dynamic instructions and conditional branches:

```swift
public struct AnyDynamicInstructions: DynamicInstructions
public struct ConditionalDynamicInstructions<TrueContent, FalseContent>: DynamicInstructions
public struct EmptyDynamicInstructions: DynamicInstructions, Sendable
```

`Instructions` conforms to `DynamicInstructions`, so existing static instruction builders can participate in the new profile DSL.

### Image attachments and generated image references

```swift
@available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
public struct Attachment<Content> where Content: AttachmentContent {
    public func label(_ label: String) -> Attachment<Content>
}

public struct ImageAttachmentContent: AttachmentContent, Sendable, Equatable {}

extension Attachment where Content == ImageAttachmentContent {
    public init(_ cgImage: CGImage, orientation: CGImagePropertyOrientation? = nil)
    public init(_ ciImage: CIImage, orientation: CGImagePropertyOrientation? = nil)
    public init(_ pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil)
    public init(imageURL: URL, orientation: CGImagePropertyOrientation? = nil)
}

public struct ImageReference: Sendable, Equatable, Generable {
    public let attachmentLabel: String
    public func resolve(in transcript: Transcript) -> Transcript.ImageAttachment?
}
```

The `_FoundationModels_UIKit` overlay also adds:

```swift
extension Attachment where Content == ImageAttachmentContent {
    public init(_ uiImage: UIImage, orientation: UIImage.Orientation? = nil)
}
```

### Generation options

```swift
public struct GenerationOptions: Sendable, Equatable {
    @available(*, deprecated, renamed: "samplingMode")
    public var sampling: GenerationOptions.SamplingMode?

    public var samplingMode: GenerationOptions.SamplingMode?
    public var temperature: Double?
    public var maximumResponseTokens: Int?

    @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
    public var toolCallingMode: GenerationOptions.ToolCallingMode?
}

extension GenerationOptions.ToolCallingMode {
    public static let allowed: GenerationOptions.ToolCallingMode
    public static let required: GenerationOptions.ToolCallingMode
    public static let disallowed: GenerationOptions.ToolCallingMode
}
```

The Xcode 26 `GenerationOptions(sampling:temperature:maximumResponseTokens:)` initializer is deprecated in favor of `GenerationOptions(samplingMode:temperature:maximumResponseTokens:)`.

### Context options and reasoning

```swift
@available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
public struct ContextOptions: Sendable, Equatable {
    public enum ReasoningLevel: Sendable, Equatable {
        case light
        case moderate
        case deep
        case custom(String)
    }

    public var includeSchemaInPrompt: Bool?
    public var reasoningLevel: ContextOptions.ReasoningLevel?
}
```

Newer response and streaming overloads can carry context options and metadata, so schema inclusion and reasoning level are no longer only ad hoc overload arguments.

### Transcript and response changes

```swift
extension Transcript.Entry {
    case reasoning(Transcript.Reasoning)
}

extension Transcript.Segment {
    case attachment(Transcript.AttachmentSegment)
}

extension LanguageModelSession.Response {
    public let usage: LanguageModelSession.Usage
}
```

`Transcript.StructuredSegment.source` is deprecated in favor of `schemaName`, with `init(id:schemaName:content:)` replacing `init(id:source:content:)` for Xcode 27 code. `Transcript` also gains mutable/range-replaceable collection behavior.

`LanguageModelSession.GenerationError.concurrentRequests` is deprecated in favor of `LanguageModelSession.Error.concurrentRequests`.

### Custom language model providers

The pasted interface exposes the custom provider path through `LanguageModel`, `LanguageModelExecutor`, and generation channels:

```swift
public protocol LanguageModel: Sendable {
    associatedtype Executor: LanguageModelExecutor where Self == Self.Executor.Model

    var capabilities: LanguageModelCapabilities { get }
    var executorConfiguration: Executor.Configuration { get }
}

public protocol LanguageModelExecutor: Sendable {
    associatedtype Configuration: Hashable, Sendable
    associatedtype Model: LanguageModel

    func prewarm(model: Model, transcript: Transcript)
    init(configuration: Configuration) throws
    func respond(
        to request: LanguageModelExecutorGenerationRequest,
        model: Model,
        streamingInto channel: LanguageModelExecutorGenerationChannel
    ) async throws
}

public struct LanguageModelExecutorGenerationRequest: Sendable
public struct LanguageModelExecutorGenerationChannel: AsyncSequence, Sendable
```

`LanguageModelExecutorGenerationChannel` can emit response deltas, reasoning deltas, and tool-call events. This is the lower-level replacement direction for Xcode 26 adapter-style examples.

The public transcript supports image attachments but no longer provides a
general custom-segment transport. Custom providers should carry provider-only
inputs, such as video bytes, in their executor configuration and translate
them into the provider request at the execution boundary.

### Session properties

Xcode 27 adds custom session properties for values shared across profiles, dynamic instructions, and tools:

```swift
extension LanguageModelSession {
    public struct SessionProperty<Value>
    public struct Profile
    public protocol DynamicProfile
}

public protocol SessionPropertyKey
public class SessionPropertyValues
public macro SessionPropertyEntry()
```

Use these when a dynamic profile needs typed state without baking everything into prompt strings.

### Feedback attachments

`LanguageModelFeedback` is available on watchOS 27 and continues to provide `Sentiment` and `Issue` metadata. `LanguageModelSession` exposes `logFeedbackAttachment(...)` overloads for serializing desired output as a transcript entry, response text, or generated content.

### Adapter migration

`SystemLanguageModel.init(adapter:guardrails:)` is obsoleted for iOS, macOS, and visionOS 27. Keep adapter examples guarded for 26.x and prefer the new `LanguageModel` / `LanguageModelExecutor` direction for Xcode 27-era custom model behavior.

### Related framework overlays

Xcode 27 ships additional Foundation Models bridge frameworks:

- `_FoundationModels_UIKit` adds `Attachment(UIImage, orientation:)`.
- `_FoundationModels_AppKit` provides macOS image attachment bridging.
- `_FoundationModels_SwiftUI` re-exports FoundationModels for SwiftUI integration.
- `_Vision_FoundationModels` exposes vision-oriented tools such as OCR and barcode reading.
- `_CoreSpotlight_FoundationModels` exposes Spotlight/file search tooling.

### Platform availability

Many Foundation Models prompting, schema, transcript, tool, feedback, and dynamic generation types include `watchOS 27.0` availability. As of Xcode 27.3, they also include `tvOS 27.0`, and `SystemLanguageModel` is available from `tvOS 27.3`. Private Cloud Compute, adapters, and image attachments remain unavailable on tvOS.

## Raw Swift Interface Reference

import CoreGraphics
import CoreImage
import CoreVideo
import Foundation
import ImageIO
import Observation
import UniformTypeIdentifiers

/// A dynamic instructions type that's type-erased.
@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
public struct AnyDynamicInstructions : DynamicInstructions {

    /// Creates an instance from the dynamic instructions you specify.
    ///
    /// - Parameters:
    ///   - dynamicInstructions: The dynamic instructions.
    public init(_ dynamicInstructions: any DynamicInstructions)

    /// The type of dynamic instructions that represent these instructions.
    @available(macOS 27.0, iOS 27.0, tvOS 27.0, watchOS 27.0, *)
    public typealias Body = Never
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension AnyDynamicInstructions {

    /// Creates an instance from the dynamic instructions you specify.
    ///
    /// - Parameters:
    ///   - dynamicInstructions: The dynamic instructions.
    @export(implementation) public init(erasing dynamicInstructions: some DynamicInstructions)

    /// The content of the dynamic instructions.
    public var body: Never { get }
}

/// An asset provided to the model.
///
/// Use `Attachment` to include media such as images alongside text in your
/// prompts and instructions.
///
/// ```swift
/// let response = try await session.respond {
///     "Describe this image:"
///     Attachment(image)
/// }
/// ```
///
/// Use the ``label(_:)`` method to assign a label to an attachment. Labels
/// help the model identify specific attachments when making tool calls.
///
/// ```swift
/// Prompt {
///     "Compare these two images:"
///     Attachment(firstImage)
///         .label("image-0")
///     Attachment(secondImage)
///         .label("image-1")
/// }
/// ```
@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
public struct Attachment<Content> {
}

@available(iOS 27.2, macOS 27.2, watchOS 27.2, tvOS 27.2, *)
extension Attachment where Content : DataAttachmentRepresentable {

    /// Creates an attachment from data content.
    ///
    /// - Parameter content: The content to attach.
    public init(_ content: Content)
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension Attachment {

    /// Assigns a label to an attachment.
    ///
    /// Labels help the model identify specific attachments when making tool calls.
    ///
    /// ```swift
    /// Attachment(image)
    ///     .label("profile-photo")
    /// ```
    ///
    /// - Parameter label: A string that identifies this attachment.
    public func label(_ label: String) -> Attachment<Content>
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension Attachment : PromptRepresentable, InstructionsRepresentable {

    /// An instance that represents a prompt.
    public var promptRepresentation: Prompt { get }

    /// An instance that represents the instructions.
    public var instructionsRepresentation: Instructions { get }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension Attachment where Content == ImageAttachmentContent {

    /// Creates an attachment from a Core Graphics image.
    ///
    /// - Parameters:
    ///   - cgImage: The image to attach.
    ///   - orientation: The orientation to apply to the image. Pass `nil` to use
    ///     the image's natural orientation.
    public init(_ cgImage: CGImage, orientation: CGImagePropertyOrientation? = nil)

    /// Creates an attachment from a Core Image image.
    ///
    /// - Parameters:
    ///   - ciImage: The image to attach.
    ///   - orientation: The orientation to apply to the image. Pass `nil` to use
    ///     the image's natural orientation.
    public init(_ ciImage: CIImage, orientation: CGImagePropertyOrientation? = nil)

    /// Creates an attachment from a pixel buffer.
    ///
    /// - Parameters:
    ///   - pixelBuffer: The pixel buffer to attach.
    ///   - orientation: The orientation to apply to the image. Pass `nil` to use
    ///     the image's natural orientation.
    public init(_ pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil)

    /// Creates an attachment from a file URL pointing to an image.
    ///
    /// - Parameters:
    ///   - imageURL: A URL to the image file to attach.
    ///   - orientation: The orientation to apply to the image. Pass `nil` to use
    ///     the image's natural orientation.
    public init(imageURL: URL, orientation: CGImagePropertyOrientation? = nil)
}

/// A dynamic instructions type that conditionally selects between two conditions.
@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
public struct ConditionalDynamicInstructions<TrueContent, FalseContent> : DynamicInstructions where TrueContent : DynamicInstructions, FalseContent : DynamicInstructions {

    /// Creates a dynamic instructions instance that selects between two conditions.
    ///
    /// - Parameters:
    ///   - branch: The condition to evaluate.
    public init(_ branch: ConditionalDynamicInstructions<TrueContent, FalseContent>.Branch)

    /// The type of dynamic instructions that represent these instructions.
    @available(macOS 27.0, iOS 27.0, tvOS 27.0, watchOS 27.0, *)
    public typealias Body = Never
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension ConditionalDynamicInstructions {

    /// An enumeration that represents a condition to evaluate.
    public enum Branch {

        /// A branch that represents true.
        case trueContent(TrueContent)

        /// A branch that represents false.
        case falseContent(FalseContent)
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension ConditionalDynamicInstructions {

    /// The content of the dynamic instructions.
    public var body: Never { get }
}

/// Options that configure details that should appear in the prompt.
///
/// Create a ``ContextOptions`` structure when you need to bias the model's behavior by
/// adjusting how the model receives your prompt.
///
/// When a property is `nil`, the framework defers to the underlying
/// ``LanguageModel`` to select an appropriate value. Each model, and each version
/// of a given model, may pick a different default, and the framework doesn't
/// guarantee a specific value or that the value remains stable across OS or model
/// updates.
@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
public struct ContextOptions : Sendable, Equatable {

    /// A Boolean value that indicates whether to inject the schema into the prompt to bias the model.
    ///
    /// Has no effect if there's no schema provided
    public var includeSchemaInPrompt: Bool?

    /// A value that controls the amount of reasoning the model is allowed to output
    /// before producing a response.
    public var reasoningLevel: ContextOptions.ReasoningLevel?

    /// Creates options that control how the model is prompted.
    ///
    /// - Parameters:
    ///   - includeSchemaInPrompt: If `true`, injects the schema into the prompt to bias the model.
    ///   - reasoningLevel: Controls the amount of reasoning that the model is allowed to output before producing a response
    public init(includeSchemaInPrompt: Bool? = nil, reasoningLevel: ContextOptions.ReasoningLevel? = nil)

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (a: ContextOptions, b: ContextOptions) -> Bool
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension ContextOptions {

    /// A level of reasoning the model is allowed to output before producing a response.
    public enum ReasoningLevel : Sendable, Equatable {

        /// A level that indicates light reasoning that's good for quick responses.
        case light

        /// A level that indicates a moderate amount of reasoning.
        case moderate

        /// A level that indicates deep reasoning that's good for more analysis over a request.
        case deep

        /// A custom level not represented by the other cases.
        case custom(String)

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: ContextOptions.ReasoningLevel, b: ContextOptions.ReasoningLevel) -> Bool
    }
}

/// A type that can be initialized from generated content.
@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
public protocol ConvertibleFromGeneratedContent : SendableMetatype {

    /// Creates an instance from content generated by a model.
    ///
    /// Conformance to this protocol is provided by the `@Generable` macro.
    /// You can provide a manual implementation to map values onto properties using
    /// different names. To manually initialize your type from generated content,
    /// decode the values as shown below:
    ///
    /// ```swift
    /// struct Person: ConvertibleFromGeneratedContent {
    ///     var name: String
    ///     var age: Int
    ///
    ///     init(_ content: GeneratedContent) {
    ///         self.name = try content.value(forProperty: "firstName")
    ///         self.age = try content.value(forProperty: "ageInYears")
    ///     }
    /// }
    /// ```
    ///
    /// - Important: If your type also conforms to ``ConvertibleToGeneratedContent``,
    /// it is critical that this implementation be symmetrical with ``ConvertibleToGeneratedContent/generatedContent``.
    ///
    /// - SeeAlso: `@Generable` macro ``Generable(description:)``
    init(_ content: GeneratedContent) throws
}

/// A type that can be converted to generated content.
@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
public protocol ConvertibleToGeneratedContent : InstructionsRepresentable, PromptRepresentable {

    /// This instance represented as generated content.
    ///
    /// Conformance to this protocol is provided by the `@Generable` macro.
    /// You can provide a manual implementation to map values onto properties using
    /// different names. Use the generated content property as shown below, to
    /// manually return a new ``GeneratedContent`` with the properties you specify.
    ///
    /// ```swift
    /// struct Person: ConvertibleToGeneratedContent {
    ///    var name: String
    ///    var age: Int
    ///
    ///    var generatedContent: GeneratedContent {
    ///        GeneratedContent(properties: [
    ///            "firstName": name,
    ///            "ageInYears": age
    ///        ])
    ///    }
    /// }
    /// ```
    ///
    /// - Important: If your type also conforms to ``ConvertibleFromGeneratedContent``,
    /// it is critical that this implementation be symmetrical with ``ConvertibleFromGeneratedContent/init(_:)``.
    var generatedContent: GeneratedContent { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension ConvertibleToGeneratedContent {

    /// An instance that represents the instructions.
    public var instructionsRepresentation: Instructions { get }

    /// An instance that represents a prompt.
    public var promptRepresentation: Prompt { get }
}

/// A type that you use as the content of a data attachment.
///
/// Conform to this protocol to describe how a value serializes into — and
/// deserializes back from — a ``Transcript/DataAttachment``. The serialized
/// form is a portable ``Data`` blob identified by a content type identifier, which is what
/// gets persisted when a ``Transcript`` is encoded, so a transcript remains
/// readable even in environments where the declaring package isn't installed.
///
/// A ``LanguageModel`` advertises which content types it accepts through
/// ``LanguageModel/supportsDataAttachmentType(_:)``; the framework validates
/// each data attachment's ``Transcript/DataAttachment/contentType`` against
/// that predicate before dispatching to the executor.
@available(iOS 27.2, macOS 27.2, watchOS 27.2, tvOS 27.2, *)
public protocol DataAttachmentRepresentable : Sendable {

    /// Rehydrates this content from its transcript representation.
    ///
    /// - Parameter attachment: The transcript representation to decode.
    init(_ attachment: Transcript.DataAttachment) throws

    /// The transcript representation of this content.
    ///
    /// The framework calls this to render the attachment into a session
    /// transcript.
    var transcriptRepresentation: Transcript.DataAttachment { get }
}

/// A type that a model can produce and represent as a top-level transcript entry.
///
/// Conform to this protocol to describe how a value serializes into — and
/// deserializes back from — a ``Transcript/DataEntry``.
///
/// ``transcriptRepresentation`` is non-throwing: any fallible encoding
/// should be surfaced from the conformer's own initializer, where the
/// developer is already deciding what input to accept. ``init(_:)`` is
/// throwing because the wire representation may come from a persisted
/// transcript, from over the network, or from any source the conformer
/// doesn't control, and could be malformed. The asymmetry mirrors
/// Foundation's `String.init(data:encoding:)` (failable) and `String.utf8`
/// (total).
@available(iOS 27.2, macOS 27.2, watchOS 27.2, tvOS 27.2, *)
public protocol DataEntryRepresentable : Sendable {

    /// Rehydrate this type from its transcript representation.
    init(_ entry: Transcript.DataEntry) throws

    /// How this type appears when recorded in a session transcript.
    var transcriptRepresentation: Transcript.DataEntry { get }
}

/// The dynamic counterpart to the generation schema type that you use to construct schemas at runtime.
///
/// An individual schema may reference other schemas by
/// name, and references are resolved when converting a set of
/// dynamic schemas into a ``GenerationSchema``.
@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
public struct DynamicGenerationSchema : Sendable {
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension DynamicGenerationSchema {

    /// A schema that represents a null value.
    ///
    /// You can use null schemas as a way to express types that
    /// cannot be absent, but may have an empty value.
    ///
    ///     let person = DynamicGenerationSchema(
    ///         name: "Person",
    ///         properties: [
    ///             DynamicGenerationSchema.Property(
    ///               name: "fullName",
    ///               schema: DynamicGenerationSchema(type: String.self)
    ///             )
    ///         ]
    ///     )
    ///
    ///     let nullablePerson = DynamicGenerationSchema(
    ///       name: "NullablePerson",
    ///       anyOf: [person, .null]
    ///     )
    ///
    ///     let schema = try GenerationSchema(root: nullablePerson, dependencies: [])
    ///
    @available(iOS 26.4, macOS 26.4, watchOS 27.0, tvOS 27.0, *)
    public static var null: DynamicGenerationSchema { get }

    /// Creates an object schema.
    ///
    /// - Parameters:
    ///   - name: A name this dynamic schema can be referenced by.
    ///   - description: A natural language description of this schema.
    ///   - properties: The properties associated with this schema.
    public init(name: String, description: String? = nil, properties: [DynamicGenerationSchema.Property])

    /// Creates an object schema.
    ///
    /// - Parameters:
    ///   - name: A name this dynamic schema can be referenced by.
    ///   - description: A natural language description of this schema.
    ///   - representNilExplicitlyInGeneratedContent: If `true`, the model represents `nil` explicitly.
    ///   - properties: The properties associated with this schema.
    @available(iOS 26.4, macOS 26.4, watchOS 27.0, tvOS 27.0, *)
    public init(name: String, description: String? = nil, representNilExplicitlyInGeneratedContent explicitNil: Bool, properties: [DynamicGenerationSchema.Property])

    /// Creates an any-of schema.
    ///
    /// - Parameters:
    ///   - name: A name this schema can be referenced by.
    ///   - description: A natural language description of this ``DynamicGenerationSchema``.
    ///   - choices: An array of schemas this one will be a union of.
    public init(name: String, description: String? = nil, anyOf choices: [DynamicGenerationSchema])

    /// Creates an enum schema.
    ///
    /// - Parameters:
    ///   - name: A name this schema can be referenced by.
    ///   - description: A natural language description of this ``DynamicGenerationSchema``.
    ///   - choices: An array of strings this one will be a union of.
    public init(name: String, description: String? = nil, anyOf choices: [String])

    /// Creates an array schema.
    ///
    /// - Parameters:
    ///   - itemSchema: A schema to use as the elements of the array.
    ///   - minimumElements: A minimum number of elements the array should contain.
    ///   - maximumElements: The maximum number of element the array should contain.
    public init(arrayOf itemSchema: DynamicGenerationSchema, minimumElements: Int? = nil, maximumElements: Int? = nil)

    /// Creates a schema from a generable type and guides.
    ///
    /// - Parameters:
    ///   - type: A `Generable` type
    ///   - guides: Generation guides to apply to this `DynamicGenerationSchema`.
    public init<Value>(type: Value.Type, guides: [GenerationGuide<Value>] = []) where Value : Generable

    /// Creates a reference schema.
    ///
    /// - Parameters:
    ///   - name: The name of the ``DynamicGenerationSchema`` this is a reference to.
    public init(referenceTo name: String)
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension DynamicGenerationSchema {

    /// A property that belongs to a dynamic generation schema.
    ///
    /// Fields are named members of object types. Fields are strongly
    /// typed and have optional descriptions.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    public struct Property : Sendable {
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension DynamicGenerationSchema.Property {

    /// Creates a property referencing a dynamic schema.
    ///
    /// - Parameters:
    ///   - name: A name for this property.
    ///   - description: An optional natural language description of this
    ///     property's contents.
    ///   - schema: A schema representing the type this property contains.
    ///   - isOptional: Determines if this property is required or not.
    public init(name: String, description: String? = nil, schema: DynamicGenerationSchema, isOptional: Bool = false)
}

/// A type that represents dynamic instructions.
///
/// Dynamic instructions provide a declarative approach to assembling instructions
/// and tools that a ``LanguageModelSession`` uses. The framework evaluates them
/// before every request to the model, so the body can contain conditional logic
/// that's based on current app state.
///
/// ```swift
/// struct PresentationInstructions: DynamicInstructions {
///     // The data source for conditional instructions.
///     var isEditingImage = true
///
///     var body: some DynamicInstructions {
///         // The instructions and tools that remain the same across any use of this type.
///         Instructions {
///             "Help people improve their presentation."
///         }
///         ListPhotosTool()
///         AddPhotoTool()
///
///         // Depending on the state of the app, include additional instructions
///         // that provide the model with more task-specific instructions and tools.
///         if isEditingImage {
///             ImageEditingInstructions()
///         }
///     }
/// }
/// ```
@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
public protocol DynamicInstructions {

    /// The type of dynamic instructions that represent these instructions.
    associatedtype Body : DynamicInstructions

    /// The content of the dynamic instructions.
    @DynamicInstructionsBuilder var body: Self.Body { get }
}

@available(iOS 27.2, macOS 27.2, watchOS 27.2, tvOS 27.2, *)
extension DynamicInstructions {

    public typealias Group = DynamicInstructionsGroup
}

@available(iOS 27.2, macOS 27.2, watchOS 27.2, tvOS 27.2, *)
extension DynamicInstructions {

    /// Runs an action when these dynamic instructions become active.
    ///
    /// Dynamic instructions become active when they are first included in the session's resolved
    /// configuration, or when they are re-included after being absent. Use this to set up state
    /// tied to the instructions' lifecycle:
    ///
    /// ```swift
    /// struct MyInstructions: DynamicInstructions {
    ///   var body: some DynamicInstructions {
    ///     Instructions("You are a helpful assistant.")
    ///       .onActivate {
    ///         activeInstructions = "assistant"
    ///       }
    ///   }
    /// }
    /// ```
    public func onActivate(perform action: sending @escaping @isolated(any) () async -> Void) -> some DynamicInstructions


    /// Runs an action when these dynamic instructions become inactive.
    ///
    /// Dynamic instructions become inactive when they are no longer included in the session's
    /// resolved configuration after previously being active. Use this to tear down state tied to
    /// the instructions' lifecycle:
    ///
    /// ```swift
    /// struct MyInstructions: DynamicInstructions {
    ///   var body: some DynamicInstructions {
    ///     Instructions("You are a helpful assistant.")
    ///       .onDeactivate {
    ///         activeInstructions = nil
    ///       }
    ///   }
    /// }
    /// ```
    public func onDeactivate(perform action: sending @escaping @isolated(any) () async -> Void) -> some DynamicInstructions

}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension DynamicInstructions {

    /// A shorthand for producing content for each element of a collection.
    public typealias ForEach = DynamicInstructionsForEach
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension DynamicInstructions {

    /// A property wrapper that provides access to a session property within dynamic instructions.
    public typealias SessionProperty = LanguageModelSession.SessionProperty
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension DynamicInstructions {

    public typealias SessionState = LanguageModelSession.SessionState
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension DynamicInstructions {

    public typealias SessionBinding = LanguageModelSession.SessionBinding
}

/// A result builder that combines tools and other content into dynamic instructions.
@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
@resultBuilder public struct DynamicInstructionsBuilder {
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension DynamicInstructionsBuilder {

    /// Creates a builder with a tool expression.
    public static func buildExpression<T>(_ expression: T) -> some DynamicInstructions where T : Tool


    /// Creates a builder with a dynamic instructions expression.
    @export(implementation) public static func buildExpression<T>(_ expression: T) -> T where T : DynamicInstructions

    /// Creates a builder with a list of tools expression.
    @export(implementation) public static func buildExpression(_ tools: [any Tool]) -> some DynamicInstructions


    @export(implementation) public static func buildBlock<each Content>(_ contents: repeat each Content) -> TupleDynamicInstructions<repeat each Content> where repeat each Content : DynamicInstructions

    /// Creates a builder with a block.
    @export(implementation) public static func buildBlock<T>(_ content: T) -> T where T : DynamicInstructions

    /// Creates a builder with an empty block.
    @export(implementation) public static func buildBlock() -> EmptyDynamicInstructions

    /// Creates a builder with the first component.
    @export(implementation) public static func buildEither<TrueContent, FalseContent>(first content: TrueContent) -> ConditionalDynamicInstructions<TrueContent, FalseContent> where TrueContent : DynamicInstructions, FalseContent : DynamicInstructions

    /// Creates a builder with the second component.
    @export(implementation) public static func buildEither<TrueContent, FalseContent>(second content: FalseContent) -> ConditionalDynamicInstructions<TrueContent, FalseContent> where TrueContent : DynamicInstructions, FalseContent : DynamicInstructions

    /// Creates a builder with an optional component.
    @export(implementation) public static func buildOptional<Content>(_ content: Content?) -> Content? where Content : DynamicInstructions

    /// Creates a builder with limited availability dynamic instructions.
    @export(implementation) public static func buildLimitedAvailability(_ content: some DynamicInstructions) -> AnyDynamicInstructions
}

/// Dynamic instructions that produce content for each element of a collection.
///
/// Don't use this type directly. Instead, use ``DynamicInstructions/ForEach`` within the
/// `body` of your ``DynamicInstructions``.
@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
public struct DynamicInstructionsForEach<Data, ID, Content> : DynamicInstructions where Data : RandomAccessCollection, ID : Hashable, Content : DynamicInstructions {

    /// The type of dynamic instructions that represent these instructions.
    @available(macOS 27.0, iOS 27.0, tvOS 27.0, watchOS 27.0, *)
    public typealias Body = Never
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension DynamicInstructionsForEach {

    /// The content of the dynamic instructions.
    public var body: Never { get }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension DynamicInstructionsForEach {

    /// Creates dynamic instructions that produce content for each element of a collection.
    ///
    /// Don't create this type directly. Instead, use ``DynamicInstructions/ForEach`` within the
    /// `body` of your ``DynamicInstructions``.
    ///
    /// - Parameters:
    ///   - data: The collection whose elements each produce content.
    ///   - id: A key path to a property that uniquely identifies each element.
    ///   - content: A builder closure that produces the dynamic instructions for an element.
    public init(_ data: Data, id: KeyPath<Data.Element, ID>, @DynamicInstructionsBuilder content: @escaping (Data.Element) -> Content)
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension DynamicInstructionsForEach where ID == Data.Element.ID, Data.Element : Identifiable {

    /// Creates dynamic instructions that produce content for each element of an identifiable
    /// collection.
    ///
    /// Don't create this type directly. Instead, use ``DynamicInstructions/ForEach`` within the
    /// `body` of your ``DynamicInstructions``.
    ///
    /// - Parameters:
    ///   - data: The collection whose elements each produce content.
    ///   - content: A builder closure that produces the dynamic instructions for an element.
    public init(_ data: Data, @DynamicInstructionsBuilder content: @escaping (Data.Element) -> Content)
}

/// A dynamic instructions type that groups its content so a single modifier can apply to the
/// whole group.
///
/// Use `Group` to gather several instructions and tools under one lifecycle, for example to run a
/// single `onActivate` / `onDeactivate` for the entire group:
///
/// ```swift
/// struct MyInstructions: DynamicInstructions {
///   var body: some DynamicInstructions {
///     Group {
///       Instructions("You are a helpful assistant.")
///       SomeTool()
///     }
///     .onActivate {
///       activeInstructions = "assistant"
///     }
///   }
/// }
/// ```
@available(iOS 27.2, macOS 27.2, watchOS 27.2, tvOS 27.2, *)
public struct DynamicInstructionsGroup<Content> : DynamicInstructions where Content : DynamicInstructions {

    /// Creates a group from the content you specify.
    ///
    /// - Parameters:
    ///   - content: The dynamic instructions to group.
    public init(@DynamicInstructionsBuilder content: () -> Content)

    /// The type of dynamic instructions that represent these instructions.
    @available(macOS 27.2, iOS 27.2, tvOS 27.2, watchOS 27.2, *)
    public typealias Body = Never
}

/// An empty dynamic instructions type.
@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
public struct EmptyDynamicInstructions : DynamicInstructions, Sendable {

    /// Creates an empty instance.
    public init()

    /// The type of dynamic instructions that represent these instructions.
    @available(macOS 27.0, iOS 27.0, tvOS 27.0, watchOS 27.0, *)
    public typealias Body = Never
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension EmptyDynamicInstructions {

    /// The content of the dynamic instructions.
    public var body: Never { get }
}

/// A type that the model uses when responding to prompts.
///
/// Annotate your Swift structure or enumeration with the `@Generable` macro to
/// allow the model to respond to prompts by generating an instance of your type.
/// Use the `@Guide` macro to provide natural language descriptions of your
/// properties, and programmatically control the values that the model can generate.
///
/// ```swift
/// @Generable
/// struct SearchSuggestions {
///     @Guide(description: "A list of suggested search terms.", .count(4))
///     var searchTerms: [SearchTerm]
///     @Generable
///     struct SearchTerm {
///         // Use a generation identifier for data structures the framework generates.
///         var id: GenerationID
///         @Guide(description: "A two- or three- word search term, like 'Beautiful sunsets'.")
///         var searchTerm: String
///     }
/// }
/// ```
///
/// For every ``Generable`` type in a request, the framework converts its type and
/// format information to a JSON schema and provides it to the model. This contributes
/// to the available context window size. If the ``LanguageModelSession`` exceeds
/// the available context size, it throws ``LanguageModelError/contextSizeExceeded(_:)``.
/// To reduce the size of your generable type:
///
/// - Reduce the complexity of your ``Generable`` type by evaluating whether properties
/// are necessary to complete the task.
/// - Give your properties short and clear names.
/// - Use ``Guide(description:)`` on properties only when it improves response quality.
/// - Add a ``Guide(description:_:)`` with ``GenerationGuide/maximumCount(_:)`` to
/// reduce token usage.
///
/// If the ``Generable`` type includes properties with clear names the model may have
/// all it needs to generate your type, eliminating the need of ``Guide(description:)``.
/// For more information on managing the context window size, see
/// <doc:managing-the-context-window>.
@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
public protocol Generable : ConvertibleFromGeneratedContent, ConvertibleToGeneratedContent {

    /// A representation of partially generated content
    associatedtype PartiallyGenerated : ConvertibleFromGeneratedContent = Self

    /// An instance of the generation schema.
    static var generationSchema: GenerationSchema { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Generable {

    /// Returns the partially generated representation of the current instance.
    public func asPartiallyGenerated() -> Self.PartiallyGenerated
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Generable {

    /// A representation of partially generated content, which defaults to the conforming type itself.
    public typealias PartiallyGenerated = Self

    /// An instance that represents a prompt.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public var promptRepresentation: Prompt { get }

    /// An instance that represents the instructions.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public var instructionsRepresentation: Instructions { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
@attached(extension, conformances: Generable, names: named(init(_:)), named(generatedContent)) @attached(member, names: arbitrary) public macro Generable(description: String? = nil) = #externalMacro(module: "FoundationModelsMacros", type: "GenerableMacro")

@available(iOS 26.4, macOS 26.4, watchOS 27.0, tvOS 27.0, *)
@attached(extension, conformances: Generable, names: named(init(_:)), named(generatedContent)) @attached(member, names: arbitrary) public macro Generable(description: String? = nil, representNilExplicitlyInGeneratedContent: Bool) = #externalMacro(module: "FoundationModelsMacros", type: "GenerableMacro")

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
@attached(extension, conformances: Generable, names: named(init(_:)), named(generatedContent)) @attached(member, names: arbitrary) public macro Generable(name: String, description: String? = nil, representNilExplicitlyInGeneratedContent: Bool = false) = #externalMacro(module: "FoundationModelsMacros", type: "GenerableMacro")

/// A type that represents structured, generated content.
///
/// Generated content may contain a single value, an array, or key-value pairs with unique keys.
@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
public struct GeneratedContent : Sendable, Equatable, Generable {

    /// A unique id that is stable for the duration of a generated response.
    ///
    /// A ``LanguageModelSession`` produces instances of ``GeneratedContent`` that have a
    /// non-nil `id`. When you stream a response, the `id` is the same for all partial generations in the
    /// response stream.
    ///
    /// Instances of ``GeneratedContent`` that you produce manually with initializers have a nil `id`
    /// because the framework didn't create them as part of a generation.
    public var id: GenerationID?

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (a: GeneratedContent, b: GeneratedContent) -> Bool
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GeneratedContent {

    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema { get }

    /// Creates generated content from another value.
    ///
    /// This is used to satisfy `Generable.init(_:)`.
    public init(_ content: GeneratedContent) throws

    /// A representation of this instance.
    public var generatedContent: GeneratedContent { get }

    /// Creates generated content representing a structure with the properties you specify.
    ///
    /// The order of properties is important. For ``Generable`` types, the order
    /// must match the order properties in the types `schema`.
    public init(properties: KeyValuePairs<String, any ConvertibleToGeneratedContent>, id: GenerationID? = nil)

    /// Creates generated content from key-value pairs, resolving duplicate keys with a combining closure.
    ///
    /// The order of properties is important. For ``Generable`` types, the order
    /// must match the order properties in the types `schema`.
    ///
    /// You use this initializer to create generated content when you have a sequence
    /// of key-value tuples that might have duplicate keys. As the content is
    /// built, the initializer calls the `combine` closure with the current and
    /// new values for any duplicate keys. Pass a closure as `combine` that
    /// returns the value to use in the resulting content: The closure can
    /// choose between the two values, combine them to produce a new value, or
    /// even throw an error.
    ///
    /// The following example shows how to choose the first and last values for
    /// any duplicate keys:
    ///
    /// ```swift
    ///     let content = GeneratedContent(
    ///       properties: [("name", "John"), ("name", "Jane"), ("married", true)],
    ///       uniquingKeysWith: { (first, _) in first }
    ///     )
    ///     // GeneratedContent(["name": "John", "married": true])
    /// ```
    ///
    /// - Parameters:
    ///   - properties: A sequence of key-value pairs to use for the new content.
    ///   - id: A unique id associated with ``GeneratedContent``.
    ///   - combine: A closure that is called with the values to resolve any duplicates
    ///     keys that are encountered. The closure returns the desired value for the final content.
    public init<S>(properties: S, id: GenerationID? = nil, uniquingKeysWith combine: (GeneratedContent, GeneratedContent) throws -> some ConvertibleToGeneratedContent) rethrows where S : Sequence, S.Element == (String, any ConvertibleToGeneratedContent)

    /// Creates content representing an array of elements you specify.
    public init<S>(elements: S, id: GenerationID? = nil) where S : Sequence, S.Element == any ConvertibleToGeneratedContent

    /// Creates content that contains a single value.
    ///
    /// - Parameters:
    ///   - value: The underlying value.
    public init(_ value: some ConvertibleToGeneratedContent)

    /// Creates content that contains a single value with a custom generation identifier.
    ///
    /// - Parameters:
    ///   - value: The underlying value.
    ///   - id: The ``GenerationID`` for this content.
    public init(_ value: some ConvertibleToGeneratedContent, id: GenerationID)

    /// Creates equivalent content from a JSON string.
    ///
    /// The JSON string you provide may be incomplete. This is useful for correctly handling partially generated responses.
    ///
    /// ```swift
    /// @Generable struct NovelIdea {
    ///   let title: String
    /// }
    ///
    /// let partial = #"{"title": "A story of"#
    /// let content = try GeneratedContent(json: partial)
    /// let idea = try NovelIdea(content)
    /// print(idea.title) // A story of
    /// ```
    public init(json: String) throws

    /// A JSON string representation of the generated content.
    ///
    /// Use this property to retrieve a JSON representation, like:
    ///
    /// ```swift
    /// // Create an object with properties.
    /// let content = GeneratedContent(properties: [
    ///     "name": "Johnny Appleseed",
    ///     "age": 30,
    /// ])
    /// // Print the output: {"name": "Johnny Appleseed", "age": 30}
    /// print(content.jsonString)
    /// ```
    public var jsonString: String { get }

    /// Reads a top level, concrete partially generable type from a named property.
    public func value<Value>(_ type: Value.Type = Value.self) throws -> Value where Value : ConvertibleFromGeneratedContent

    /// Reads a concrete generable type from a named property.
    public func value<Value>(_ type: Value.Type = Value.self, forProperty property: String) throws -> Value where Value : ConvertibleFromGeneratedContent

    /// Reads an optional, concrete generable type from a named property.
    public func value<Value>(_ type: Value?.Type = Value?.self, forProperty property: String) throws -> Value? where Value : ConvertibleFromGeneratedContent

    /// A Boolean value that indicates whether the generated content is complete.
    public var isComplete: Bool { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GeneratedContent : CustomDebugStringConvertible {

    /// A string representation for the debug description.
    public var debugDescription: String { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GeneratedContent {

    /// A representation of the different types of content that can be stored in generated content.
    ///
    /// `Kind` represents the various types of JSON-compatible data that can be held within
    /// a ``GeneratedContent`` instance, including primitive types, arrays, and structured objects.
    public enum Kind : Equatable, Sendable {

        /// A null value.
        case null

        /// A boolean value.
        /// - Parameter value: The boolean value.
        case bool(Bool)

        /// A numeric value.
        /// - Parameter value: The numeric value as a `Double`.
        case number(Double)

        /// A string value.
        /// - Parameter value: The string value.
        case string(String)

        /// An array of generated content elements.
        /// - Parameter elements: An array of ``GeneratedContent`` instances.
        case array([GeneratedContent])

        /// A structured object with key-value pairs.
        /// - Parameters:
        ///   - properties: A dictionary mapping string keys to ``GeneratedContent`` values.
        ///   - orderedKeys: An array of keys that specifies the order of properties.
        case structure(properties: [String : GeneratedContent], orderedKeys: [String])

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: GeneratedContent.Kind, b: GeneratedContent.Kind) -> Bool
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GeneratedContent {

    /// Creates content with the specified kind and generation identifier.
    ///
    /// This initializer provides a convenient way to create content from its kind representation.
    ///
    /// - Parameters:
    ///   - kind: The kind of content to create.
    ///   - id: An optional ``GenerationID`` to associate with this content.
    public init(kind: GeneratedContent.Kind, id: GenerationID? = nil)

    /// The representation of the generated content.
    ///
    /// This property provides access to the content in a strongly-typed enumeration representation,
    /// preserving the hierarchical structure of the data and the data's ``GenerationID`` values.
    public var kind: GeneratedContent.Kind { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GeneratedContent {

    /// A failure that occurs when a string cannot be parsed into generated content.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public struct ParsingError : LocalizedError, Sendable {

        /// The raw content that could not be parsed.
        public var rawContent: String

        /// The underlying error that caused the parsing failure, if any.
        public var underlyingError: (any Error)?

        /// A debug description of what failed to parse.
        public var debugDescription: String

        /// Creates a parsing failure value.
        /// - Parameters:
        ///   - rawContent: The raw content that could not be parsed.
        ///   - underlyingError: The underlying error that caused the parsing failure, if any.
        ///   - debugDescription: A debug description of what failed to parse.
        public init(rawContent: String, underlyingError: (any Error)? = nil, debugDescription: String)
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension GeneratedContent.ParsingError : CustomDebugStringConvertible {
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension GeneratedContent.ParsingError {

    /// A localized message describing what error occurred.
    public var errorDescription: String? { get }
}

/// Guides that control how values are generated.
@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
public struct GenerationGuide<Value> {
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationGuide where Value == String {

    /// Enforces that the string be precisely the given value.
    public static func constant(_ value: String) -> GenerationGuide<String>

    /// Enforces that the string be one of the provided values.
    public static func anyOf(_ values: [String]) -> GenerationGuide<String>

    /// Enforces that the string follows the pattern.
    public static func pattern<Output>(_ regex: Regex<Output>) -> GenerationGuide<String>
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationGuide where Value == Int {

    /// Enforces a minimum value.
    ///
    /// Use a `minimum` generation guide --- whose bounds are inclusive --- to ensure the model produces
    /// a value greater than or equal to some minimum value. For example, you can specify that all characters
    /// in your game start at level 1:
    ///
    /// ```swift
    /// @Generable
    /// struct GameCharacter {
    ///     @Guide(description: "A creative name appropriate for a fantasy RPG character")
    ///     var name: String
    ///
    ///     @Guide(description: "A level for the character", .minimum(1))
    ///     var level: Int
    /// }
    /// ```
    public static func minimum(_ value: Int) -> GenerationGuide<Int>

    /// Enforces a maximum value.
    ///
    /// Use a `maximum` generation guide --- whose bounds are inclusive --- to ensure the model produces
    /// a value less than or equal to some maximum value. For example, you can specify that the highest level
    /// a character in your game can achieve is 100:
    ///
    /// ```swift
    /// @Generable
    /// struct GameCharacter {
    ///     @Guide(description: "A creative name appropriate for a fantasy RPG character")
    ///     var name: String
    ///
    ///     @Guide(description: "A level for the character", .maximum(100))
    ///     var level: Int
    /// }
    /// ```
    public static func maximum(_ value: Int) -> GenerationGuide<Int>

    /// Enforces values that fall within a range.
    ///
    /// Use a `range` generation guide --- whose bounds are inclusive --- to ensure the model produces a
    /// value that falls within a range. For example, you can specify that the level of characters in your game
    /// are between 1 and 100:
    ///
    /// ```swift
    /// @Generable
    /// struct GameCharacter {
    ///     @Guide(description: "A creative name appropriate for a fantasy RPG character")
    ///     var name: String
    ///
    ///     @Guide(description: "A level for the character", .range(1...100))
    ///     var level: Int
    /// }
    /// ```
    public static func range(_ range: ClosedRange<Int>) -> GenerationGuide<Int>
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationGuide where Value == Float {

    /// Enforces a minimum value.
    ///
    /// Use a `minimum` generation guide --- whose bounds are inclusive --- to ensure the model produces
    /// a value greater than or equal to some minimum value. For example, you can specify that all characters
    /// in your game start at level 1.0:
    ///
    /// ```swift
    /// @Generable
    /// struct GameCharacter {
    ///     @Guide(description: "A creative name appropriate for a fantasy RPG character")
    ///     var name: String
    ///
    ///     @Guide(description: "A level for the character", .minimum(1.0))
    ///     var level: Float
    /// }
    /// ```
    public static func minimum(_ value: Float) -> GenerationGuide<Float>

    /// Enforces a maximum value.
    ///
    /// Use a `maximum` generation guide --- whose bounds are inclusive --- to ensure the model produces
    /// a value less than or equal to some maximum value. For example, you can specify that the highest level
    /// a character in your game can achieve is 100.0:
    ///
    /// ```swift
    /// @Generable
    /// struct GameCharacter {
    ///     @Guide(description: "A creative name appropriate for a fantasy RPG character")
    ///     var name: String
    ///
    ///     @Guide(description: "A level for the character", .maximum(100.0))
    ///     var level: Float
    /// }
    /// ```
    public static func maximum(_ value: Float) -> GenerationGuide<Float>

    /// Enforces values that fall within a range.
    ///
    /// Bounds are inclusive.
    ///
    /// A `range` generation guide may be used when you want to ensure the model
    /// produces a value that falls in some range, such as the cost for an item
    /// in a game.
    ///
    /// ```swift
    /// @Generable
    /// struct ShopItem {
    ///     @Guide(description: "A creative name for an item sold in a fantasy RPG")
    ///     var name: String
    ///
    ///     @Guide(description: "A cost for the item", .range(1...1000))
    ///     var cost: Float
    /// }
    /// ```
    public static func range(_ range: ClosedRange<Float>) -> GenerationGuide<Float>
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationGuide where Value == Decimal {

    /// Enforces a minimum value.
    ///
    /// Use a `minimum` generation guide --- whose bounds are inclusive --- to ensure the model produces
    /// a value greater than or equal to some minimum value. For example, you can specify that all characters
    /// in your game start at level 0.75:
    ///
    /// ```swift
    /// @Generable
    /// struct GameCharacter {
    ///     @Guide(description: "A creative name appropriate for a fantasy RPG character")
    ///     var name: String
    ///
    ///     @Guide(description: "A level for the character", .minimum(0.75))
    ///     var level: Decimal
    /// }
    /// ```
    public static func minimum(_ value: Decimal) -> GenerationGuide<Decimal>

    /// Enforces a maximum value.
    ///
    /// Use a `maximum` generation guide --- whose bounds are inclusive --- to ensure the model produces
    /// a value less than or equal to some maximum value. For example, you can specify that the highest level
    /// a character in your game can achieve is 99.9:
    ///
    /// ```swift
    /// @Generable
    /// struct GameCharacter {
    ///     @Guide(description: "A creative name appropriate for a fantasy RPG character")
    ///     var name: String
    ///
    ///     @Guide(description: "A level for the character", .maximum(99.9))
    ///     var level: Decimal
    /// }
    /// ```
    public static func maximum(_ value: Decimal) -> GenerationGuide<Decimal>

    /// Enforces values that fall within a range.
    ///
    /// Bounds are inclusive.
    ///
    /// A `range` generation guide may be used when you want to ensure the model
    /// produces a value that falls in some range, such as the cost for an item
    /// in a game.
    ///
    /// ```swift
    /// @Generable
    /// struct ShopItem {
    ///     @Guide(description: "A creative name for an item sold in a fantasy RPG")
    ///     var name: String
    ///
    ///     @Guide(description: "A cost for the item", .range(0.25...1000))
    ///     var cost: Decimal
    /// }
    /// ```
    public static func range(_ range: ClosedRange<Decimal>) -> GenerationGuide<Decimal>
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationGuide where Value == Double {

    /// Enforces a minimum value.
    ///
    /// Use a `minimum` generation guide --- whose bounds are inclusive --- to ensure the model produces
    /// a value greater than or equal to some minimum value. For example, you can specify that all characters
    /// in your game start at level 1.0:
    ///
    /// ```swift
    /// @Generable
    /// struct GameCharacter {
    ///     @Guide(description: "A creative name appropriate for a fantasy RPG character")
    ///     var name: String
    ///
    ///     @Guide(description: "A level for the character", .minimum(1.0))
    ///     var level: Double
    /// }
    /// ```
    public static func minimum(_ value: Double) -> GenerationGuide<Double>

    /// Enforces a maximum value.
    ///
    /// Use a `maximum` generation guide --- whose bounds are inclusive --- to ensure the model produces
    /// a value less than or equal to some maximum value. For example, you can specify that the highest level
    /// a character in your game can achieve is 5000.0:
    ///
    /// ```swift
    /// @Generable
    /// struct GameCharacter {
    ///     @Guide(description: "A creative name appropriate for a fantasy RPG character")
    ///     var name: String
    ///
    ///     @Guide(description: "A level for the character", .maximum(5000.0))
    ///     var level: Double
    /// }
    /// ```
    public static func maximum(_ value: Double) -> GenerationGuide<Double>

    /// Enforces values that fall within a range.
    ///
    /// Bounds are inclusive.
    ///
    /// A `range` generation guide may be used when you want to ensure the model
    /// produces a value that falls in some range, such as the cost for an item
    /// in a game.
    ///
    /// ```swift
    /// @Generable
    /// struct ShopItem {
    ///     @Guide(description: "A creative name for an item sold in a fantasy RPG")
    ///     var name: String
    ///
    ///     @Guide(description: "A cost for the item", .range(1...1000))
    ///     var cost: Double
    /// }
    /// ```
    public static func range(_ range: ClosedRange<Double>) -> GenerationGuide<Double>
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationGuide {

    /// Enforces a minimum number of elements in the array.
    ///
    /// The bounds are inclusive.
    ///
    /// A `minimumCount` generation guide may be used when you want to ensure the
    /// model produces a number of array elements greater than or equal to some
    /// minimum value, such as the number of items in a game's shop.
    ///
    /// ```swift
    /// @Generable
    /// struct Shop {
    ///     @Guide(description: "A creative name for a shop in a fantasy RPG")
    ///     var name: String
    ///
    ///     @Guide(description: "A list of items for sale", .minimumCount(3))
    ///     var inventory: [ShopItem]
    /// }
    /// ```
    public static func minimumCount<Element>(_ count: Int) -> GenerationGuide<[Element]> where Value == [Element]

    /// Enforces a maximum number of elements in the array.
    ///
    /// The bounds are inclusive.
    ///
    /// A `maximumCount` generation guide may be used when you want to ensure the
    /// model produces a number of array elements less than or equal to some
    /// maximum value, such as the number of items in a game's shop.
    ///
    /// ```swift
    /// @Generable
    /// struct Shop {
    ///     @Guide(description: "A creative name for a shop in a fantasy RPG")
    ///     var name: String
    ///
    ///     @Guide(description: "A list of items for sale", .maximumCount(10))
    ///     var inventory: [ShopItem]
    /// }
    /// ```
    public static func maximumCount<Element>(_ count: Int) -> GenerationGuide<[Element]> where Value == [Element]

    /// Enforces that the number of elements in the array falls within a closed range.
    ///
    /// Bounds are inclusive.
    ///
    /// A `count` generation guide may be used when you want to ensure the
    /// model produces a number of array elements that falls within a given range,
    /// such as the number of items in a game's shop.
    ///
    /// ```swift
    /// @Generable
    /// struct Shop {
    ///     @Guide(description: "A creative name for a shop in a fantasy RPG")
    ///     var name: String
    ///
    ///     @Guide(description: "A list of items for sale", .count(2...10))
    ///     var inventory: [ShopItem]
    /// }
    /// ```
    public static func count<Element>(_ range: ClosedRange<Int>) -> GenerationGuide<[Element]> where Value == [Element]

    /// Enforces that the array has exactly a certain number of elements.
    ///
    /// A `count` generation guide may be used when you want to ensure the
    /// model produces exactly a certain number array elements, such as the
    /// number of items in a game's shop.
    ///
    /// ```swift
    /// @Generable
    /// struct Shop {
    ///     @Guide(description: "A creative name for a shop in a fantasy RPG")
    ///     var name: String
    ///
    ///     @Guide(description: "A list of items for sale", .count(3))
    ///     var inventory: [ShopItem]
    /// }
    /// ```
    public static func count<Element>(_ count: Int) -> GenerationGuide<[Element]> where Value == [Element]

    /// Enforces a guide on the elements within the array.
    ///
    /// An `element` generation guide may be used when you want to apply guides to
    /// the values a model produces within an array. For example, you may want to
    /// generate an array of integers, where all the integers are in the range 0-9.
    ///
    /// ```swift
    /// @Generable
    /// struct FortuneCookie {
    ///     @Guide(description: "A fortune from a fortune cookie")
    ///     var name: String
    ///
    ///     @Guide(description: "A list lucky numbers", .element(.range(0...9)), .count(4))
    ///     var luckyNumbers: [Int]
    /// }
    /// ```
    public static func element<Element>(_ guide: GenerationGuide<Element>) -> GenerationGuide<[Element]> where Value == [Element]
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationGuide where Value == [Never] {

    /// Enforces a minimum number of elements in the array.
    ///
    /// Bounds are inclusive.
    ///
    /// - Warning: This overload is only used for macro expansion. Don't call `GenerationGuide<[Never]>.minimumCount(_:)` on your own.
    @export(implementation) public static func minimumCount(_ count: Int) -> GenerationGuide<Value>

    /// Enforces a maximum number of elements in the array.
    ///
    /// Bounds are inclusive.
    ///
    /// - Warning: This overload is only used for macro expansion. Don't call `GenerationGuide<[Never]>.maximumCount(_:)` on your own.
    @export(implementation) public static func maximumCount(_ count: Int) -> GenerationGuide<Value>

    /// Enforces that the number of elements in the array falls within a closed range.
    ///
    /// - Warning: This overload is only used for macro expansion. Don't call `GenerationGuide<[Never]>.count(_:)` on your own.
    @export(implementation) public static func count(_ range: ClosedRange<Int>) -> GenerationGuide<Value>

    /// Enforces that the array has exactly a certain number of elements.
    ///
    /// - Warning: This overload is only used for macro expansion. Don't call `GenerationGuide<[Never]>.count(_:)` on your own.
    @export(implementation) public static func count(_ count: Int) -> GenerationGuide<Value>
}

/// A unique identifier that is stable for the duration of a response, but not across responses.
///
/// The framework guarantees a `GenerationID` to be both present and stable when you
/// receive it from a ``LanguageModelSession``. When you create an instance of
/// `GenerationID` there is no guarantee an identifier is present or stable.
///
/// ```swift
/// @Generable struct Person: Equatable {
///     var id: GenerationID
///     var name: String
/// }
///
/// struct PeopleView: View {
///     @State private var session = LanguageModelSession()
///     @State private var people = [Person.PartiallyGenerated]()
///
///     var body: some View {
///         // A person's name changes as the response is generated,
///         // and two people can have the same name, so it is not suitable
///         // for use as an id.
///         //
///         // `GenerationID` receives special treatment and is guaranteed
///         // to be both present and stable.
///         List {
///             ForEach(people) { person in
///                 Text("Name: \(person.name ?? "")")
///             }
///         }
///         .task {
///             do {
///                 let stream = session.streamResponse(
///                     to: "Who were the first 3 presidents of the US?",
///                     generating: [Person].self
///                 )
///                 for try await snapshot in stream {
///                     withAnimation {
///                         self.people = snapshot.content
///                     }
///                 }
///             } catch {
///                 // Handle the thrown error.
///             }
///         }
///     }
/// }
/// ```
@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
public struct GenerationID : Sendable, Hashable {

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (a: GenerationID, b: GenerationID) -> Bool

    /// Hashes the essential components of this value by feeding them into the
    /// given hasher.
    ///
    /// Implement this method to conform to the `Hashable` protocol. The
    /// components used for hashing must be the same as the components compared
    /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
    /// with each of these components.
    ///
    /// - Important: In your implementation of `hash(into:)`,
    ///   don't call `finalize()` on the `hasher` instance provided,
    ///   or replace it with a different instance.
    ///   Doing so may become a compile-time error in the future.
    ///
    /// - Parameter hasher: The hasher to use when combining the components
    ///   of this instance.
    public func hash(into hasher: inout Hasher)

    /// The hash value.
    ///
    /// Hash values are not guaranteed to be equal across different executions of
    /// your program. Do not save hash values to use during a future execution.
    ///
    /// - Important: `hashValue` is deprecated as a `Hashable` requirement. To
    ///   conform to `Hashable`, implement the `hash(into:)` requirement instead.
    ///   The compiler provides an implementation for `hashValue` for you.
    public var hashValue: Int { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationID {

    /// Creates a unique identifier.
    public init()
}

/// Options that control how the model generates its response to a prompt.
///
/// Generation options determine the decoding strategy the framework uses to adjust
/// the way the model chooses output tokens. When you interact with the model, it
/// converts your input to a token sequence, and uses it to generate the response.
///
/// Only use ``maximumResponseTokens`` when you need to protect against unexpectedly
/// verbose responses. Enforcing a strict token response limit can lead to the model
/// producing malformed results or grammatically incorrect responses.
///
/// All input to the model contributes tokens to the context window of the
/// ``LanguageModelSession`` --- including the ``Instructions``, ``Prompt``, ``Tool``,
/// and ``Generable`` types, and the model's responses. If your session exceeds the
/// available context size, it throws
/// ``LanguageModelError/contextSizeExceeded(_:)``. For more
/// information on managing the context window size, see
/// <doc:managing-the-context-window>.
///
/// When a property is `nil`, the framework defers to the underlying
/// ``LanguageModel`` to select an appropriate value. Each model, and each version
/// of a given model, may pick a different default, and the framework doesn't
/// guarantee a specific value or that the value remains stable across OS or model
/// updates.
@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
public struct GenerationOptions : Sendable, Equatable {

    /// A sampling strategy for how the model picks tokens when generating a
    /// response.
    ///
    /// When you execute a prompt on a model, the model produces a probability
    /// for every token in its vocabulary. The sampling strategy controls how
    /// the model narrows down the list of tokens to consider during that process.
    /// A strategy that picks the single most likely token yields a predictable
    /// response every time, but other strategies offer results that often
    /// sound more natural to a person.
    ///
    /// - Note: Leaving the `sampling` to `nil` lets the system choose a
    ///   reasonable default on your behalf.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    @available(*, deprecated, renamed: "samplingMode")
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public var sampling: GenerationOptions.SamplingMode?

    /// A value that influences the confidence of the model's response.
    ///
    /// The value of this property must be a number between `0` and `1` inclusive.
    ///
    /// Temperature is an adjustment applied to the probability distribution
    /// prior to sampling. A value of `1` results in no adjustment. Values less
    /// than `1` make the probability distribution sharper, with already
    /// likely tokens becoming even more likely.
    ///
    /// The net effect is that low temperatures manifest as more stable and
    /// predictable responses, while high temperatures give the model more
    /// creative license.
    ///
    /// - Note: Leaving `temperature` nil lets the system choose a reasonable
    ///   default on your behalf.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    public var temperature: Double?

    /// The maximum number of tokens the model is allowed to produce in its response.
    ///
    /// If the model produces `maximumResponseTokens` before it naturally completes its response,
    /// the framework terminates the response early, without throwing an error. Use this property
    /// to protect against unexpectedly verbose responses and runaway generations.
    ///
    /// If no value is specified, then the model is allowed to produce the longest answer
    /// its context size supports. If the response exceeds that limit without terminating,
    /// the framework throws an error.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    public var maximumResponseTokens: Int?

    /// The tool calling requirements.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public var toolCallingMode: GenerationOptions.ToolCallingMode?

    /// Creates generation options that control token sampling behavior.
    ///
    /// - Parameters:
    ///   - samplingMode: A strategy to use for sampling from a distribution.
    ///   - temperature: A value between `0` and `1`, inclusive, that controls how sharply the model
    ///     favors its most likely responses. A higher value increases variety.
    ///   - maximumResponseTokens: The maximum number of tokens the model produces
    ///     before being halted. Must be positive.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    @backDeployed(before: iOS 27.0, macOS 27.0, visionOS 27.0)
    public init(samplingMode: GenerationOptions.SamplingMode? = nil, temperature: Double? = nil, maximumResponseTokens: Int? = nil)

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (a: GenerationOptions, b: GenerationOptions) -> Bool
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationOptions {

    /// A sampling strategy for how the model picks tokens when generating a
    /// response.
    ///
    /// When you execute a prompt on a model, the model produces a probability
    /// for every token in its vocabulary. The sampling strategy controls how
    /// the model narrows down the list of tokens to consider during that process.
    /// A strategy that picks the single most likely token yields a predictable
    /// response every time, but other strategies offer results that often
    /// sound more natural to a person.
    ///
    /// - Note: Leaving the `sampling` to `nil` lets the system choose a
    ///   reasonable default on your behalf.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    @backDeployed(before: iOS 27.0, macOS 27.0, visionOS 27.0)
    public var samplingMode: GenerationOptions.SamplingMode?
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationOptions {

    /// Creates generation options that control token sampling behavior.
    ///
    /// - Parameters:
    ///   - samplingMode: A strategy to use for sampling from a distribution.
    ///   - temperature: A value between `0` and `1`, inclusive, that controls how sharply the model
    ///     favors its most likely responses. A higher value increases variety.
    ///   - maximumResponseTokens: The maximum number of tokens the model is allowed
    ///     to produce before being artificially halted. Must be positive.
    ///   - toolCallingMode: The requirements defining how the model should call tools.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public init(samplingMode: GenerationOptions.SamplingMode? = nil, temperature: Double? = nil, maximumResponseTokens: Int? = nil, toolCallingMode: GenerationOptions.ToolCallingMode?)
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationOptions {

    /// A type that defines how values are sampled from a probability distribution.
    ///
    /// A model builds its response to a prompt in a loop. At each iteration in the
    /// loop the model produces a probability distribution for all the tokens in its
    /// vocabulary. The sampling mode controls how a token is selected from that
    /// distribution.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    public struct SamplingMode : Sendable, Equatable {

        /// The strategy this sampling mode uses to choose the next token.
        @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
        public let kind: GenerationOptions.SamplingMode.Kind

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: GenerationOptions.SamplingMode, b: GenerationOptions.SamplingMode) -> Bool
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationOptions {

    /// A value that describes how the model uses tools.
    ///
    /// Use this to control how the model interacts with tools for a given request. Tool
    /// calling mode supports three modes:
    ///
    /// - term ``GenerationOptions/ToolCallingMode/allowed``: The model may call tools.
    /// This is the default behavior.
    /// - term ``GenerationOptions/ToolCallingMode/required``: The model must call one or
    /// more tools before it can respond.
    /// - term ``GenerationOptions/ToolCallingMode/disallowed``: The model can't call any
    /// tools and responds using only its own knowledge.
    ///
    /// The following changes the mode from ``GenerationOptions/ToolCallingMode/required``
    /// to ``GenerationOptions/ToolCallingMode/allowed`` after the first tool call, which
    /// lets the model produce a final response:
    ///
    /// ```swift
    /// extension SessionPropertyValues {
    ///     @SessionPropertyEntry
    ///     var toolCallCount: Int = 0
    /// }
    ///
    /// struct RecipeDynamicProfile: LanguageModelSession.DynamicProfile {
    ///     @SessionProperty(\.toolCallCount)
    ///     var toolCallCount
    ///     var body: some LanguageModelSession.DynamicProfile {
    ///         Profile {
    ///             BreadDatabaseTool()
    ///         }
    ///         .toolCallingMode(toolCallCount < 1 ? .required : .allowed)
    ///         .onToolCall {
    ///             toolCallCount += 1
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// > Important: When you set the mode to ``GenerationOptions/ToolCallingMode/required``,
    /// you must define an exit condition by either throwing an error from a tool's
    /// ``Tool/call(arguments:)`` method or by changing the mode dynamically using a
    /// ``LanguageModelSession/DynamicProfile``; otherwise, the model continues to call
    /// the tool.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public struct ToolCallingMode : Sendable, Equatable {

        /// The tool-calling behavior this mode represents.
        public var kind: GenerationOptions.ToolCallingMode.Kind

        /// The model may or may not call tools.
        ///
        /// This is the default.
        public static let allowed: GenerationOptions.ToolCallingMode

        /// The model must call one or multiple tools.
        ///
        /// ``LanguageModelSession`` keeps calling tools until a tool throws an error from its
        /// ``Tool/call(arguments:)`` method or you change the mode dynamically using a
        /// ``LanguageModelSession/DynamicProfile``.
        public static let required: GenerationOptions.ToolCallingMode

        /// The model may not call any tool.
        public static let disallowed: GenerationOptions.ToolCallingMode

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: GenerationOptions.ToolCallingMode, b: GenerationOptions.ToolCallingMode) -> Bool
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationOptions {

    /// Creates generation options that control token sampling behavior.
    ///
    /// - Parameters:
    ///   - sampling: A strategy to use for sampling from a distribution.
    ///   - temperature: Increasing temperature makes it possible for the model to produce less likely
    ///     responses. Must be between `0` and `1`, inclusive.
    ///   - maximumResponseTokens: The maximum number of tokens the model is allowed
    ///     to produce before being artificially halted. Must be positive.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    @available(*, deprecated, renamed: "init(samplingMode:temperature:maximumResponseTokens:)")
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public init(sampling: GenerationOptions.SamplingMode?, temperature: Double? = nil, maximumResponseTokens: Int? = nil)
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationOptions.SamplingMode {

    /// A sampling mode that always chooses the most likely token.
    ///
    /// This mode always produces the same output
    /// for a given input. Responses produced with greedy sampling
    /// are statistically likely, but may lack the human-like quality
    /// and variety of other sampling strategies.
    /// - SeeAlso: Sampling modes ``random(top:seed:)`` and ``random(probabilityThreshold:seed:)``
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    public static var greedy: GenerationOptions.SamplingMode { get }

    /// A sampling mode that considers a fixed number of high-probability tokens.
    ///
    /// Also known as top-k.
    ///
    /// During the token-selection process, the vocabulary is sorted by probability a
    /// token is selected from among the top K candidates. Smaller values of K
    /// ensure only the most probable tokens are candidates for selection, resulting
    /// in more deterministic and confident answers. Larger values of K allow less
    /// probably tokens to be selected, raising non-determinism and creativity.
    ///
    /// - Note: Setting a random seed is not guaranteed to result in fully deterministic
    ///   output. It is best effort.
    ///
    /// - Parameters:
    ///   - k: The number of tokens to consider.
    ///   - seed: An optional random seed used to make output more deterministic.
    /// - SeeAlso: Sampling modes ``greedy`` and ``random(probabilityThreshold:seed:)``
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    public static func random(top k: Int, seed: UInt64? = nil) -> GenerationOptions.SamplingMode

    /// A mode that considers a variable number of high-probability tokens
    /// based on the specified threshold.
    ///
    /// Also known as top-p or nucleus sampling.
    ///
    /// With nucleus sampling, tokens are sorted by probability and added to a
    /// pool of candidates until the cumulative probability of the pool exceeds
    /// the specified threshold, and then a token is sampled from the pool.
    ///
    /// Because the number of tokens isn't predetermined, the selection pool size
    /// is larger when the distribution is flat and smaller when it is spikey.
    /// This variability can lead to a wider variety of options to choose from, and
    /// potentially more creative responses.
    ///
    /// - Note: Setting a random seed is not guaranteed to result in fully deterministic
    ///   output. It is best effort.
    ///
    /// - Parameters:
    ///     - probabilityThreshold: A number between `0.0` and `1.0` that
    ///       increases sampling pool size.
    ///     - seed: An optional random seed used to make output more deterministic.
    /// - SeeAlso: Sampling modes ``greedy`` and ``random(top:seed:)``
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    public static func random(probabilityThreshold: Double, seed: UInt64? = nil) -> GenerationOptions.SamplingMode
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationOptions.SamplingMode {

    /// A representation of the different strategies for choosing the next token.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public enum Kind : Sendable, Equatable {

        /// A strategy that always chooses the most likely token.
        case greedy

        /// A strategy that samples from a fixed number of the highest-probability tokens.
        case randomTopK(Int, seed: UInt64?)

        /// A strategy that samples from the highest-probability tokens whose cumulative
        /// probability reaches a threshold.
        case randomProbabilityThreshold(Double, seed: UInt64?)

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: GenerationOptions.SamplingMode.Kind, b: GenerationOptions.SamplingMode.Kind) -> Bool
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationOptions.ToolCallingMode {

    /// A representation of the different ways a model can use tools.
    public enum Kind : Sendable, Equatable {

        /// The model may call tools.
        case allowed

        /// The model must call one or more tools.
        case required

        /// The model can't call any tools.
        case disallowed

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: GenerationOptions.ToolCallingMode.Kind, b: GenerationOptions.ToolCallingMode.Kind) -> Bool

        /// Hashes the essential components of this value by feeding them into the
        /// given hasher.
        ///
        /// Implement this method to conform to the `Hashable` protocol. The
        /// components used for hashing must be the same as the components compared
        /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
        /// with each of these components.
        ///
        /// - Important: In your implementation of `hash(into:)`,
        ///   don't call `finalize()` on the `hasher` instance provided,
        ///   or replace it with a different instance.
        ///   Doing so may become a compile-time error in the future.
        ///
        /// - Parameter hasher: The hasher to use when combining the components
        ///   of this instance.
        public func hash(into hasher: inout Hasher)

        /// The hash value.
        ///
        /// Hash values are not guaranteed to be equal across different executions of
        /// your program. Do not save hash values to use during a future execution.
        ///
        /// - Important: `hashValue` is deprecated as a `Hashable` requirement. To
        ///   conform to `Hashable`, implement the `hash(into:)` requirement instead.
        ///   The compiler provides an implementation for `hashValue` for you.
        public var hashValue: Int { get }
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationOptions.ToolCallingMode.Kind : Hashable {
}

/// A type that describes the properties of an object and any guides
/// on their values.
///
/// Generation schemas guide the output of a language model to deterministically
/// ensure the output is in the desired format.
@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
public struct GenerationSchema : Sendable {
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationSchema {

    /// The name of this generation schema.
    ///
    /// Typically this will the name of a Swift type, but it can be an arbitrary
    /// string for schemas created dynamically.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public var name: String { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationSchema {

    /// A named, strongly typed member of an object type with an optional description and guides.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    public struct Property : Sendable {
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationSchema {

    /// Creates a schema by providing an array of properties.
    ///
    /// - Parameters:
    ///   - type: The type this schema represents.
    ///   - description: A natural language description of this schema.
    ///   - properties: An array of properties.
    public init(type: any Generable.Type, description: String? = nil, properties: [GenerationSchema.Property])
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationSchema : Codable {

    /// Creates a new instance by decoding from the given decoder.
    ///
    /// This initializer throws an error if reading from the decoder fails, or
    /// if the data read is corrupted or otherwise invalid.
    ///
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: any Decoder) throws

    /// Encodes this value into the given encoder.
    ///
    /// If the value fails to encode anything, `encoder` will encode an empty
    /// keyed container in its place.
    ///
    /// This function throws an error if any values are invalid for the given
    /// encoder's format.
    ///
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: any Encoder) throws
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationSchema : CustomDebugStringConvertible {

    /// A textual representation of this instance, suitable for debugging.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(reflecting:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `debugDescription` property for types that conform to
    /// `CustomDebugStringConvertible`:
    ///
    ///     struct Point: CustomDebugStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var debugDescription: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(reflecting: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `debugDescription` property.
    public var debugDescription: String { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationSchema {

    /// Creates a schema by providing an array of properties.
    ///
    /// - Parameters:
    ///   - type: The type this schema represents.
    ///   - description: A natural language description of this schema.
    ///   - representNilExplicitlyInGeneratedContent: If `true`, the model represents `nil` explicitly.
    ///   - properties: An array of properties.
    @available(iOS 26.4, macOS 26.4, watchOS 27.0, tvOS 27.0, *)
    public init(type: any Generable.Type, description: String? = nil, representNilExplicitlyInGeneratedContent explicitNil: Bool, properties: [GenerationSchema.Property])

    /// Creates a schema for a string enumeration.
    ///
    /// - Parameters:
    ///   - type: The type this schema represents.
    ///   - description: A natural language description of this schema.
    ///   - choices: The allowed choices.
    public init(type: any Generable.Type, description: String? = nil, anyOf choices: [String])

    /// Creates a schema as the union of several other types.
    ///
    /// - Parameters:
    ///   - type: The type this schema represents.
    ///   - description: A natural language description of this schema.
    ///   - types: The types this schema should be a union of.
    public init(type: any Generable.Type, description: String? = nil, anyOf types: [any Generable.Type])

    /// Creates a schema by providing an array of dynamic schemas.
    ///
    /// - Parameters:
    ///   - root: The root schema.
    ///   - dependencies: An array of dynamic schemas.
    /// - Throws: If there are schemas with naming conflicts or
    ///   references to undefined types.
    public init(root: DynamicGenerationSchema, dependencies: [DynamicGenerationSchema]) throws
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationSchema {

    /// An error that occurs when there is a problem creating a generation schema.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    @nonexhaustive public enum SchemaError : Error, LocalizedError {

        /// An error that represents an attempt to construct a schema from dynamic schemas
        /// in which two or more of the subschemas have the same type name.
        case duplicateType(schema: String?, type: String, context: GenerationSchema.SchemaError.Context)

        /// An error that represents an attempt to construct a dynamic schema
        /// with properties that have conflicting names.
        case duplicateProperty(schema: String, property: String, context: GenerationSchema.SchemaError.Context)

        /// An error that represents an attempt to construct an anyOf schema with an
        /// empty array of type choices.
        case emptyTypeChoices(schema: String, context: GenerationSchema.SchemaError.Context)

        /// An error that represents an attempt to construct a schema from dynamic schemas
        /// in which one of those schemas references an undefined schema.
        case undefinedReferences(schema: String?, references: [String], context: GenerationSchema.SchemaError.Context)
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationSchema.Property {

    /// Creates a property that contains a generable type.
    ///
    /// - Parameters:
    ///   - name: The property's name.
    ///   - description: A natural language description of what content
    ///     should be generated for this property.
    ///   - type: The type this property represents.
    ///   - guides: A list of guides to apply to this property.
    public init<Value>(name: String, description: String? = nil, type: Value.Type, guides: [GenerationGuide<Value>] = []) where Value : Generable

    /// Creates an optional property that contains a generable type.
    ///
    /// - Parameters:
    ///   - name: The property's name.
    ///   - description: A natural language description of what content
    ///     should be generated for this property.
    ///   - type: The type this property represents.
    ///   - guides: A list of guides to apply to this property.
    public init<Value>(name: String, description: String? = nil, type: Value?.Type, guides: [GenerationGuide<Value>] = []) where Value : Generable

    /// Creates a property that contains a string type.
    ///
    /// - Parameters:
    ///   - name: The property's name.
    ///   - description: A natural language description of what content
    ///     should be generated for this property.
    ///   - type: The type this property represents.
    ///   - guides: An array of regexes to apply to this string. If the array contains multiple
    ///     regexes, only the last one applies.
    public init<RegexOutput>(name: String, description: String? = nil, type: String.Type, guides: [Regex<RegexOutput>] = [])

    /// Creates an optional property that contains a generable type.
    ///
    /// - Parameters:
    ///   - name: The property's name.
    ///   - description: A natural language description of what content
    ///     should be generated for this property.
    ///   - type: The type this property represents.
    ///   - guides: An array of regexes to apply to this string. If the array contains multiple
    ///     regexes, only the last one applies.
    public init<RegexOutput>(name: String, description: String? = nil, type: String?.Type, guides: [Regex<RegexOutput>] = [])
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationSchema.SchemaError {

    /// The context in which the error occurred.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    public struct Context : Sendable {

        /// A string representation of the debug description.
        ///
        /// This string is not localized and is not appropriate for display to end users.
        public let debugDescription: String
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationSchema.SchemaError {

    /// A string representation of the error description.
    public var errorDescription: String? { get }

    /// A suggestion that indicates how to handle the error.
    public var recoverySuggestion: String? { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension GenerationSchema.SchemaError.Context {

    /// Creates a context with the debug description you provide.
    ///
    /// - Parameter debugDescription: A description of the circumstances of the error.
    public init(debugDescription: String)
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
@attached(peer) public macro Guide<T>(description: String? = nil, _ guides: GenerationGuide<T>...) = #externalMacro(module: "FoundationModelsMacros", type: "GuideMacro") where T : Generable

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
@attached(peer) public macro Guide<RegexOutput>(description: String? = nil, _ guides: Regex<RegexOutput>) = #externalMacro(module: "FoundationModelsMacros", type: "GuideMacro")

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
@attached(peer) public macro Guide(description: String) = #externalMacro(module: "FoundationModelsMacros", type: "GuideMacro")

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
@attached(peer) public macro Guide<T>(key: String, description: String? = nil, _ guides: GenerationGuide<T>...) = #externalMacro(module: "FoundationModelsMacros", type: "GuideMacro") where T : Generable

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
@attached(peer) public macro Guide<RegexOutput>(key: String, description: String? = nil, _ guides: Regex<RegexOutput>) = #externalMacro(module: "FoundationModelsMacros", type: "GuideMacro")

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
@attached(peer) public macro Guide(key: String, description: String? = nil) = #externalMacro(module: "FoundationModelsMacros", type: "GuideMacro")

/// A type that holds image data.
///
/// You don't create `ImageAttachmentContent` directly. Instead, use one of the
/// ``Attachment`` initializers to attach a
/// <doc://com.apple.documentation/documentation/coregraphics/cgimage>,
/// <doc://com.apple.documentation/documentation/coreimage/ciimage>,
/// <doc://com.apple.documentation/documentation/corevideo/cvpixelbuffer-q2e>,
/// or image file URL.
@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
public struct ImageAttachmentContent : Sendable, Equatable {

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (a: ImageAttachmentContent, b: ImageAttachmentContent) -> Bool
}

/// A reference to an image in a session's transcript.
///
/// Use `ImageReference` to allow the model to reference images from the transcript of the current `LanguageModelSession`.
///
/// You can define an `ImageReference` as an argument to a `Tool`. Retrieve the referenced image from the transcript during the tool call.
///
/// ```swift
/// struct MyTool: Tool {
///   @SessionProperty(\.history) var history
///
///   @Generable
///   struct Arguments {
///     var image: ImageReference
///   }
///
///   public func call(arguments: Arguments) async throws -> Output {
///     guard let imageAttachment = arguments.image.resolved(in: history) else {
///       throw ImageToolError.imageNotFound(arguments.image.attachmentLabel)
///     }
///     let image = imageAttachment.cgImage
///     ...
///   }
/// }
/// ```
@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
public struct ImageReference : Sendable, Equatable {

    /// The label of the referenced image.
    public let attachmentLabel: String

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (a: ImageReference, b: ImageReference) -> Bool
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension ImageReference {

    /// Returns the referenced image from the transcript.
    ///
    /// If more than one attachment shares an ``attachmentLabel``, the attachment from the latest entry is returned.
    ///
    /// - Parameters:
    ///   - transcript: The transcript to resolve the reference against.
    /// - Returns: The ``Transcript/ImageAttachment`` for this reference, or `nil` if no
    ///   attachment with label ``attachmentLabel`` is found in the transcript.
    public func resolved(in transcript: some Sequence<Transcript.Entry>) -> Transcript.ImageAttachment?
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension ImageReference {

    /// A representation of an image reference that the model has only partially generated.
    nonisolated public struct PartiallyGenerated : Identifiable, nonisolated ConvertibleFromGeneratedContent, Equatable {

        /// The stable identity of the entity associated with this instance.
        public var id: GenerationID

        /// The label of the referenced image as the model generates it.
        public var attachmentLabel: String.PartiallyGenerated?

        /// Creates an instance from content generated by a model.
        ///
        /// Conformance to this protocol is provided by the `@Generable` macro.
        /// You can provide a manual implementation to map values onto properties using
        /// different names. To manually initialize your type from generated content,
        /// decode the values as shown below:
        ///
        /// ```swift
        /// struct Person: ConvertibleFromGeneratedContent {
        ///     var name: String
        ///     var age: Int
        ///
        ///     init(_ content: GeneratedContent) {
        ///         self.name = try content.value(forProperty: "firstName")
        ///         self.age = try content.value(forProperty: "ageInYears")
        ///     }
        /// }
        /// ```
        ///
        /// - Important: If your type also conforms to ``ConvertibleToGeneratedContent``,
        /// it is critical that this implementation be symmetrical with ``ConvertibleToGeneratedContent/generatedContent``.
        ///
        /// - SeeAlso: `@Generable` macro ``Generable(description:)``
        nonisolated public init(_ content: GeneratedContent) throws

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: ImageReference.PartiallyGenerated, b: ImageReference.PartiallyGenerated) -> Bool

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(macOS 27.0, iOS 27.0, tvOS 27.0, watchOS 27.0, *)
        public typealias ID = GenerationID
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension ImageReference : nonisolated Generable {

    /// An instance of the generation schema.
    nonisolated public static var generationSchema: GenerationSchema { get }

    /// This instance represented as generated content.
    ///
    /// Conformance to this protocol is provided by the `@Generable` macro.
    /// You can provide a manual implementation to map values onto properties using
    /// different names. Use the generated content property as shown below, to
    /// manually return a new ``GeneratedContent`` with the properties you specify.
    ///
    /// ```swift
    /// struct Person: ConvertibleToGeneratedContent {
    ///    var name: String
    ///    var age: Int
    ///
    ///    var generatedContent: GeneratedContent {
    ///        GeneratedContent(properties: [
    ///            "firstName": name,
    ///            "ageInYears": age
    ///        ])
    ///    }
    /// }
    /// ```
    ///
    /// - Important: If your type also conforms to ``ConvertibleFromGeneratedContent``,
    /// it is critical that this implementation be symmetrical with ``ConvertibleFromGeneratedContent/init(_:)``.
    nonisolated public var generatedContent: GeneratedContent { get }

    /// Creates an instance from content generated by a model.
    ///
    /// Conformance to this protocol is provided by the `@Generable` macro.
    /// You can provide a manual implementation to map values onto properties using
    /// different names. To manually initialize your type from generated content,
    /// decode the values as shown below:
    ///
    /// ```swift
    /// struct Person: ConvertibleFromGeneratedContent {
    ///     var name: String
    ///     var age: Int
    ///
    ///     init(_ content: GeneratedContent) {
    ///         self.name = try content.value(forProperty: "firstName")
    ///         self.age = try content.value(forProperty: "ageInYears")
    ///     }
    /// }
    /// ```
    ///
    /// - Important: If your type also conforms to ``ConvertibleToGeneratedContent``,
    /// it is critical that this implementation be symmetrical with ``ConvertibleToGeneratedContent/generatedContent``.
    ///
    /// - SeeAlso: `@Generable` macro ``Generable(description:)``
    nonisolated public init(_ content: GeneratedContent) throws
}

/// Details you provide that define the model's intended behavior on prompts.
///
/// You typically provide instructions to define the role and behavior of
/// the model. In the code below, the instructions specify that the model replies
/// with topics rather than, for example, a recipe:
///
/// ```swift
/// let instructions = """
///     Suggest related topics. Keep them concise (three to seven words) and make sure they \
///     build naturally from the person's topic.
///     """
///
/// let session = LanguageModelSession(instructions: instructions)
///
/// let prompt = "Making homemade bread"
/// let response = try await session.respond(to: prompt)
/// ```
///
/// Don't include untrusted content in instructions: the model is typically trained to obey
/// instructions over any commands it receives in prompts. For more on how instructions
/// impact generation quality and safety, see <doc:improving-the-safety-of-generative-model-output>.
///
/// All input to the model contributes tokens to the context window of the
/// ``LanguageModelSession`` --- including the ``Instructions``, ``Prompt``, ``Tool``,
/// and ``Generable`` types, and the model's responses. If your session exceeds the
/// available context size, it throws  ``LanguageModelError/contextSizeExceeded(_:)``.
///
/// Instructions can consume a lot of tokens that contribute to the context window
/// size. To reduce your instruction size:
///
/// - Write shorter instructions to save tokens.
/// - Provide only the information necessary to perform the task.
/// - Use concise and imperative language instead of indirect or jargon that the model might misinterpret.
/// - Aim for one to three paragraphs instead of including a significant amount of background information,
/// policy, or extra content.
///
/// For more information on managing the context window size, see <doc:managing-the-context-window>.
@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
public struct Instructions : Sendable {
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension Instructions : DynamicInstructions {

    /// The content of the dynamic instructions.
    public var body: some DynamicInstructions { get }

    /// The type of dynamic instructions that represent these instructions.
    @available(macOS 27.0, iOS 27.0, tvOS 27.0, watchOS 27.0, *)
    public typealias Body = some DynamicInstructions
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Instructions {

    /// Creates an instance with the content you specify.
    public init(_ content: some InstructionsRepresentable)
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Instructions : InstructionsRepresentable {

    /// An instance that represents the instructions.
    public var instructionsRepresentation: Instructions { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Instructions {

    /// Creates instructions from the content of a builder closure.
    ///
    /// - Parameter content: A closure that produces the instructions to give the model.
    public init(@InstructionsBuilder _ content: () throws -> Instructions) rethrows
}

/// A type that represents an instructions builder.
@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
@resultBuilder public struct InstructionsBuilder {
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension InstructionsBuilder {

    /// Creates a builder with a block.
    @export(implementation) public static func buildBlock<each I>(_ components: repeat each I) -> Instructions where repeat each I : InstructionsRepresentable

    /// Creates a builder with an array of instructions.
    @export(implementation) public static func buildArray(_ instructions: [some InstructionsRepresentable]) -> Instructions

    /// Creates a builder with the first component.
    @export(implementation) public static func buildEither(first component: some InstructionsRepresentable) -> Instructions

    /// Creates a builder with the second component.
    @export(implementation) public static func buildEither(second component: some InstructionsRepresentable) -> Instructions

    /// Creates a builder with an optional component.
    @export(implementation) public static func buildOptional(_ instructions: Instructions?) -> Instructions

    /// Creates a builder with limited availability instructions.
    @export(implementation) public static func buildLimitedAvailability(_ instructions: some InstructionsRepresentable) -> Instructions

    /// Creates a builder with an expression.
    @export(implementation) public static func buildExpression<I>(_ expression: I) -> I where I : InstructionsRepresentable

    /// Creates a builder with an instructions expression.
    @export(implementation) public static func buildExpression(_ expression: Instructions) -> Instructions
}

/// A type that can be represented as instructions.
@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
public protocol InstructionsRepresentable {

    /// An instance that represents the instructions.
    @InstructionsBuilder var instructionsRepresentation: Instructions { get }
}

/// A protocol that you use to interface with a model.
///
/// Implement this protocol to create a bridge between a model and the framework.
/// The protocol describes the capabilities and the configuration for your model. An
/// ``Executor`` does the work of translating framework types into the types your
/// platform expects, and streams results back through ``LanguageModelExecutorGenerationChannel``.
/// Because most of the work is done in the executor, keep the type that adopts this
/// protocol intentionally light.
///
/// When your implementation is ready to adopt, distribute your solution with Swift
/// Package Manager so developers can easily integrate it into their project. After
/// they add your package, they simply initialize a ``LanguageModelSession`` with
/// your model:
///
/// ```swift
/// // Initialize a session with a custom server model.
/// let session = LanguageModelSession(model: MyCustomServerLanguageModel())
/// // Use the same API surface to prompt the model.
/// let response = try await session.respond(to: "Tell me a joke!")
/// ```
@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
public protocol LanguageModel : Sendable {

    associatedtype Executor : LanguageModelExecutor where Self == Self.Executor.Model

    /// The capabilities of this language model.
    ///
    /// If a developer attempts to use capabilities that your model does not support,
    /// the system automatically throws an error for you instead of calling a respond method, like
    /// ``LanguageModelSession/respond(to:options:)-(Prompt,_)`` or
    /// ``LanguageModelSession/streamResponse(to:options:)-(Prompt,_)``.
    var capabilities: LanguageModelCapabilities { get }

    /// A configuration for an executor capable of running this model.
    var executorConfiguration: Self.Executor.Configuration { get }

    @available(iOS 27.2, macOS 27.2, watchOS 27.2, tvOS 27.2, *)
    nonisolated(nonsending) func supportsDataAttachmentType(_ type: UTType) async throws -> Bool

    @available(iOS 27.2, macOS 27.2, watchOS 27.2, tvOS 27.2, *)
    nonisolated(nonsending) func supportsDataEntryType(_ type: UTType) async throws -> Bool
}

@available(iOS 27.2, macOS 27.2, watchOS 27.2, tvOS 27.2, *)
extension LanguageModel {

    nonisolated(nonsending) public func supportsDataAttachmentType(_ type: UTType) async throws -> Bool

    nonisolated(nonsending) public func supportsDataEntryType(_ type: UTType) async throws -> Bool
}

/// A set of capabilities that a language model provides.
///
/// Use this to declare what your model can do, like tool calling and guided
/// generation:
///
/// ```swift
/// struct MyLanguageModel: LanguageModel {
///     var capabilities: LanguageModelCapabilities {
///         LanguageModelCapabilities([
///             .toolCalling,
///             .guidedGeneration,
///             .reasoning
///         ])
///     }
/// }
/// ```
///
/// Inspect ``LanguageModel/capabilities`` ahead of time to detect what
/// the model supports before performing the request:
///
/// ```swift
/// // Before prompting the model with a generable type, check whether it
/// // supports guided generation.
/// if selectedModel.capabilities.contains(.guidedGeneration) {
///     let response = try await session.respond(to: "...", generating: MySchema.self)
/// }
/// ```
///
/// When a model doesn't support a capability, the framework can refuse to dispatch
/// incompatible requests to the executor and throw an
/// ``LanguageModelError/unsupportedCapability(_:)`` error instead.
@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
public struct LanguageModelCapabilities : Sendable {

    /// Creates a capabilities instance from a list of supported capabilities.
    public init(_ capabilities: [LanguageModelCapabilities.Capability])
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelCapabilities {

    /// Returns a Boolean value that indicates whether the specified capability is supported.
    public func contains(_ capability: LanguageModelCapabilities.Capability) -> Bool
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelCapabilities {

    /// A capability that a given language model may or may not have.
    public struct Capability : Sendable, Hashable {

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: LanguageModelCapabilities.Capability, b: LanguageModelCapabilities.Capability) -> Bool

        /// Hashes the essential components of this value by feeding them into the
        /// given hasher.
        ///
        /// Implement this method to conform to the `Hashable` protocol. The
        /// components used for hashing must be the same as the components compared
        /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
        /// with each of these components.
        ///
        /// - Important: In your implementation of `hash(into:)`,
        ///   don't call `finalize()` on the `hasher` instance provided,
        ///   or replace it with a different instance.
        ///   Doing so may become a compile-time error in the future.
        ///
        /// - Parameter hasher: The hasher to use when combining the components
        ///   of this instance.
        public func hash(into hasher: inout Hasher)

        /// The hash value.
        ///
        /// Hash values are not guaranteed to be equal across different executions of
        /// your program. Do not save hash values to use during a future execution.
        ///
        /// - Important: `hashValue` is deprecated as a `Hashable` requirement. To
        ///   conform to `Hashable`, implement the `hash(into:)` requirement instead.
        ///   The compiler provides an implementation for `hashValue` for you.
        public var hashValue: Int { get }
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelCapabilities.Capability {

    /// The capability to accept image inputs in prompts.
    public static var vision: LanguageModelCapabilities.Capability { get }

    /// The capability to ensure model output conforms to a given generation schema.
    public static var guidedGeneration: LanguageModelCapabilities.Capability { get }

    /// The capability to reason, structurally separately from producing a response.
    public static var reasoning: LanguageModelCapabilities.Capability { get }

    /// The capability to call tools to gather information or trigger side effects.
    public static var toolCalling: LanguageModelCapabilities.Capability { get }
}

/// A failure that may occur while generating a response when using any language model.
///
/// - Note: If your app deploys to iOS 26, macOS 26, or visionOS 26, where this error is
///   unavailable, use an availability check and fall back to
///   ``LanguageModelSession/GenerationError``:
///
///   ```swift
///   do {
///       let response = try await session.respond(to: prompt)
///   } catch {
///       if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *),
///           let error = error as? LanguageModelError
///       {
///           // Handle the error.
///       } else if let error = error as? LanguageModelSession.GenerationError {
///           // Handle the deprecated error.
///       }
///   }
///   ```
@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
@nonexhaustive public enum LanguageModelError : LocalizedError {

    /// The session's transcript exceeded the model's context size.
    ///
    /// You can recover from this error by removing entries from the transcript and trying again.
    ///
    /// For more information on managing the context window size, see <doc:managing-the-context-window>.
    case contextSizeExceeded(LanguageModelError.ContextSizeExceeded)

    /// The session has been rate limited.
    ///
    /// This failure can happen if you make too many requests in a short window.
    /// You can recover from this error by spacing your requests or reducing system load. The
    /// exact solution may be model dependent.
    case rateLimited(LanguageModelError.RateLimited)

    /// The model's safety guardrails were triggered by content in a
    /// prompt or the response generated by the model.
    case guardrailViolation(LanguageModelError.GuardrailViolation)

    /// The model refused to answer.
    ///
    /// This failure can happen for prompts that do not violate any guardrail policy, but
    /// the model isn't able to provide the kind of response you requested. You can
    /// choose to handle this by showing a predetermined message of your choice.
    case refusal(LanguageModelError.Refusal)

    /// The model being used doesn't support a particular feature.
    ///
    /// This failure can happen if you use capabilities like guided generation or tool calling
    /// with a model that does not support them.
    case unsupportedCapability(LanguageModelError.UnsupportedCapability)

    /// The prompt contains content that the model cannot process.
    ///
    /// This failure occurs when you include unsupported file types, corrupted data, or custom
    /// content formats that the model doesn't recognize.
    case unsupportedTranscriptContent(LanguageModelError.UnsupportedTranscriptContent)

    /// An unsupported generation guide was used.
    ///
    /// This failure occurs if you attempt to use generation guides that a model does not support.
    /// For example, many models don't support certain guides using certain regex patterns.
    case unsupportedGenerationGuide(LanguageModelError.UnsupportedGenerationGuide)

    /// The model was prompted to respond in a language that it does not support.
    case unsupportedLanguageOrLocale(LanguageModelError.UnsupportedLanguageOrLocale)

    /// The request timed out before the model could produce a response.
    case timeout(LanguageModelError.Timeout)
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelError {

    /// Information about exceeding the context window size.
    public struct ContextSizeExceeded : Sendable {

        /// The model's maximum context size, in tokens.
        public var contextSize: Int

        /// The number of tokens in the transcript that exceeded the model's context size.
        public var tokenCount: Int

        /// A debug description to help developers diagnose issues during development.
        public var debugDescription: String

        /// Additional information about the failure, keyed by name.
        public var metadata: [String : any Sendable]
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelError {

    /// Information about a rate limiting event.
    public struct RateLimited : Sendable {

        /// The date after which retrying is likely to succeed, if known.
        public var resetDate: Date?

        /// A debug description to help developers diagnose issues during development.
        public var debugDescription: String

        /// Additional information about the failure, keyed by name.
        public var metadata: [String : any Sendable]
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelError {

    /// Information about a guardrail violation.
    public struct GuardrailViolation : Sendable {

        /// A debug description to help developers diagnose issues during development.
        public var debugDescription: String

        /// Additional information about the failure, keyed by name.
        public var metadata: [String : any Sendable]
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelError {

    /// Information about a model refusal.
    ///
    /// Refusal failures indicate that the model chose not to respond to a prompt.
    public struct Refusal : Sendable {

        /// A debug description to help developers diagnose issues during development.
        public var debugDescription: String

        /// Additional information about the failure, keyed by name.
        public var metadata: [String : any Sendable]
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelError {

    /// Information about an unsupported capability.
    public struct UnsupportedCapability : Sendable {

        /// The capability that the model doesn't support.
        public var capability: LanguageModelCapabilities.Capability

        /// A debug description to help developers diagnose issues during development.
        public var debugDescription: String

        /// Additional information about the failure, keyed by name.
        public var metadata: [String : any Sendable]
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelError {

    /// Information about unsupported prompt content.
    public struct UnsupportedTranscriptContent : Sendable {

        /// The transcript entries that the model can't process.
        public var unsupportedContent: [Transcript.Entry]

        /// A debug description to help developers diagnose issues during development.
        public var debugDescription: String

        /// Additional information about the failure, keyed by name.
        public var metadata: [String : any Sendable]
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelError {

    /// Information about an unsupported generation guide.
    public struct UnsupportedGenerationGuide : Sendable {

        /// The name of the schema whose generation guide isn't supported, if any.
        public var schemaName: String?

        /// A debug description to help developers diagnose issues during development.
        public var debugDescription: String

        /// Additional information about the failure, keyed by name.
        public var metadata: [String : any Sendable]
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelError {

    /// Information about an unsupported language or locale.
    public struct UnsupportedLanguageOrLocale : Sendable {

        /// The language code that the model doesn't support.
        public var languageCode: Locale.LanguageCode

        /// A debug description to help developers diagnose issues during development.
        public var debugDescription: String

        /// Additional information about the failure, keyed by name.
        public var metadata: [String : any Sendable]
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelError {

    /// Information about a timeout.
    public struct Timeout : Sendable {

        /// A debug description to help developers diagnose issues during development.
        public var debugDescription: String

        /// Additional information about the failure, keyed by name.
        public var metadata: [String : any Sendable]
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelError : CustomDebugStringConvertible {

    /// A textual representation of this instance, suitable for debugging.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(reflecting:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `debugDescription` property for types that conform to
    /// `CustomDebugStringConvertible`:
    ///
    ///     struct Point: CustomDebugStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var debugDescription: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(reflecting: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `debugDescription` property.
    public var debugDescription: String { get }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelError {

    /// A localized message describing what error occurred.
    public var errorDescription: String? { get }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelError.ContextSizeExceeded {

    /// Creates information describing a transcript that exceeded the model's context size.
    ///
    /// - Parameters:
    ///   - contextSize: The model's maximum context size, in tokens.
    ///   - tokenCount: The number of tokens in the transcript that exceeded the context size.
    ///   - debugDescription: A developer-facing description of the failure.
    ///   - metadata: Additional information about the failure, keyed by name.
    public init(contextSize: Int, tokenCount: Int, debugDescription: String, metadata: [String : any Sendable] = [:])
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelError.RateLimited {

    /// Creates information describing a rate-limiting event.
    ///
    /// - Parameters:
    ///   - resetDate: The date after which retrying is likely to succeed, or `nil` if unknown.
    ///   - debugDescription: A debug description to help developers diagnose issues during development.
    ///   - metadata: Additional information about the failure, keyed by name.
    public init(resetDate: Date?, debugDescription: String, metadata: [String : any Sendable] = [:])
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelError.GuardrailViolation {

    /// Creates information describing a guardrail violation.
    ///
    /// - Parameters:
    ///   - debugDescription: A debug description to help developers diagnose issues during development.
    ///   - metadata: Additional information about the failure, keyed by name.
    public init(debugDescription: String, metadata: [String : any Sendable] = [:])
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelError.Refusal {

    /// Creates information describing a model refusal.
    ///
    /// - Parameters:
    ///   - explanation: The model's explanation for why it refused to respond.
    ///   - debugDescription: A debug description to help developers diagnose issues during development.
    ///   - metadata: Additional information about the failure, keyed by name.
    public init(explanation: String, debugDescription: String, metadata: [String : any Sendable] = [:])
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelError.Refusal {

    /// The model's explanation for why it refused to generate a response.
    nonisolated(nonsending) public var explanation: LanguageModelSession.Response<String> { get async throws }

    /// The model's explanation for why it refused to generate a response, delivered as it streams.
    public var explanationStream: LanguageModelSession.ResponseStream<String> { get }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelError.UnsupportedCapability {

    /// Creates information describing a capability the model doesn't support.
    ///
    /// - Parameters:
    ///   - capability: The capability that the model doesn't support.
    ///   - debugDescription: A debug description to help developers diagnose issues during development.
    ///   - metadata: Additional information about the failure, keyed by name.
    public init(capability: LanguageModelCapabilities.Capability, debugDescription: String, metadata: [String : any Sendable] = [:])
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelError.UnsupportedTranscriptContent {

    /// Creates information describing transcript content the model can't process.
    ///
    /// - Parameters:
    ///   - unsupportedContent: The transcript entries that the model can't process.
    ///   - debugDescription: A debug description to help developers diagnose issues during development.
    ///   - metadata: Additional information about the failure, keyed by name.
    public init(unsupportedContent: [Transcript.Entry], debugDescription: String, metadata: [String : any Sendable] = [:])
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelError.UnsupportedGenerationGuide {

    /// Creates information describing a generation guide the model doesn't support.
    ///
    /// - Parameters:
    ///   - schemaName: The name of the schema whose generation guide isn't supported, if any.
    ///   - debugDescription: A debug description to help developers diagnose issues during development.
    ///   - metadata: Additional information about the failure, keyed by name.
    public init(schemaName: String?, debugDescription: String, metadata: [String : any Sendable] = [:])
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelError.UnsupportedLanguageOrLocale {

    /// Creates information describing a language or locale the model doesn't support.
    ///
    /// - Parameters:
    ///   - languageCode: The language code that the model doesn't support.
    ///   - debugDescription: A debug description to help developers diagnose issues during development.
    ///   - metadata: Additional information about the failure, keyed by name.
    public init(languageCode: Locale.LanguageCode, debugDescription: String, metadata: [String : any Sendable] = [:])
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelError.Timeout {

    /// Creates information describing a request timeout.
    ///
    /// - Parameters:
    ///   - debugDescription: A debug description to help developers diagnose issues during development.
    ///   - metadata: Additional information about the failure, keyed by name.
    public init(debugDescription: String, metadata: [String : any Sendable] = [:])
}

/// A protocol that defines the interface for responding to session requests.
///
/// An executor is the bridge between the framework types and the system that actually
/// generates the tokens, like a server API or a local inference engine. A ``LanguageModel``
/// pairs with exactly one executor type and the framework instantiates the executor
/// from the ``Configuration`` the model provides.
///
/// Every request can include preferences that control generation:
///
/// - term ``GenerationOptions``: Configures the sampling strategy, temperature,
/// and maximum response length.
/// - term ``ContextOptions``: Configures the prompting behavior and thinking effort.
///
/// When the framework calls ``respond(to:model:streamingInto:)``, handle converting
/// the transcript into the format your model expects and applying generation options.
/// In some cases, you may need to fall back when your model can't do exactly what
/// was asked, like using temperature to approximate sampling options:
///
/// ```swift
/// // Parse generation and context options
/// func respond(
///     to request: LanguageModelExecutorGenerationRequest,
///     model: MyLanguageModel,
///     streamingInto channel: LanguageModelExecutorGenerationChannel
/// ) async throws {
///
///     // The request includes a sampling set to `greedy`, but your
///     // model only uses temperature.
///     if request.generationOptions.samplingMode == .greedy {
///         // Use the temperature of `0` to approximate the intention.
///     }
///
///     // ...
/// }
/// ```
///
/// Use ``LanguageModelExecutorGenerationChannel`` to stream incremental events back
/// as generation progresses. You don't return a value or close the channel explicitly.
/// The channel finishes when the method returns or when an error is thrown.
@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
public protocol LanguageModelExecutor : Sendable {

    associatedtype Configuration : Hashable, Sendable

    /// The model type this executor processes requests for.
    associatedtype Model : LanguageModel

    /// Loads assets into memory or pre-fills caches ahead of a request.
    ///
    /// - Note: The default implementation is a no-op.
    func prewarm(model: Self.Model, transcript: Transcript)

    /// Creates an executor from a configuration.
    init(configuration: Self.Configuration) throws

    /// Creates a response stream containing deltas.
    ///
    /// - Parameters:
    ///    - request: The generation request.
    ///    - model: The model instance for this request, providing live model state.
    ///    - channel: A channel used to send events.
    ///
    /// - Note: If the model declares that it does not have a given capability
    /// via ``LanguageModel/capabilities``, then the system will automatically
    /// throw an error instead
    /// of invoking this method. You do not need to manually validate the request
    /// for any functionality captured by ``LanguageModelCapabilities``.
    nonisolated(nonsending) func respond(to request: LanguageModelExecutorGenerationRequest, model: Self.Model, streamingInto channel: LanguageModelExecutorGenerationChannel) async throws
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelExecutor {

    /// Loads assets into memory or pre-fills caches ahead of a request.
    ///
    /// - Note: The default implementation is a no-op.
    public func prewarm(model: Self.Model, transcript: Transcript)
}

/// A type you use to send model output deltas and updates to the framework.
///
/// Use this to stream text as your model produces it. You can also use the channel
/// to report metadata and usage that helps developers track what's happening, like
/// when you want to report model details and token usage updates:
///
/// ```swift
/// func respond(
///     to request: LanguageModelExecutorGenerationRequest,
///     model: MyLanguageModel,
///     streamingInto channel: LanguageModelExecutorGenerationChannel
/// ) async throws {
///
///     let entryID = UUID().uuidString
///
///     // Calculate your total and cached tokens counts for the input.
///     let totalTokens = 0
///     let cachedTokens = 0
///
///     // Send model identification.
///     await channel.send(.response(entryID: entryID, action: .updateMetadata([
///         "modelID": "my-model-2026-06-08",
///         "requestID": request.id.uuidString
///     ])))
///
///     // Report prompt token usage upfront.
///     await channel.send(.response(
///         entryID: entryID,
///         action: .updateUsage(
///             input: .init(
///                 totalTokenCount: totalTokens,
///                 cachedTokenCount: cachedTokens
///             ),
///             output: .init(
///                 totalTokenCount: 0,
///                 reasoningTokenCount: 0
///             )
///         )
///     ))
/// }
/// ```
@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
public struct LanguageModelExecutorGenerationChannel : AsyncSequence, Sendable {

    /// Creates a generation channel instance.
    public init()

    /// The type of element produced by this asynchronous sequence.
    @available(macOS 27.0, iOS 27.0, tvOS 27.0, watchOS 27.0, *)
    public typealias Element = LanguageModelExecutorGenerationChannel.Event
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelExecutorGenerationChannel {

    /// An asynchronous iterator that produces the generation events sent on a channel.
    public struct AsyncIterator : AsyncIteratorProtocol {

        @available(macOS 27.0, iOS 27.0, tvOS 27.0, watchOS 27.0, *)
        public typealias Element = LanguageModelExecutorGenerationChannel.Event
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelExecutorGenerationChannel {

    /// Creates the asynchronous iterator that produces elements of this
    /// asynchronous sequence.
    ///
    /// - Returns: An instance of the `AsyncIterator` type used to produce
    /// elements of the asynchronous sequence.
    public func makeAsyncIterator() -> LanguageModelExecutorGenerationChannel.AsyncIterator

    /// Sends a generation event on the channel.
    ///
    /// - Parameters:
    ///   - event: The event to send.
    nonisolated(nonsending) public func send(_ event: LanguageModelExecutorGenerationChannel.Event) async
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelExecutorGenerationChannel {

    /// A generation event sent on a generation channel.
    ///
    /// Construct one with a leading-dot factory — ``response(entryID:action:)``,
    /// ``reasoning(entryID:action:)``, or ``toolCalls(entryID:action:)`` — and pass
    /// it to ``send(_:)``.
    public struct Event : Sendable {
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelExecutorGenerationChannel {

    /// Snapshot of an entry's metadata dictionary.
    ///
    /// Each event replaces the prior metadata wholesale; keys absent from `values` are
    /// considered removed.
    public struct Metadata : Sendable {

        /// The metadata key-value pairs for the entry.
        public var values: [String : GeneratedContent]
    }

    /// Snapshot of an entry's token totals.
    ///
    /// Producers report the current cumulative totals on every update, and consumers replace
    /// prior totals wholesale.
    public struct Usage : Sendable {

        /// The input token counts from the transcript.
        public var input: LanguageModelExecutorGenerationChannel.Usage.Input

        /// The output token counts from the response.
        public var output: LanguageModelExecutorGenerationChannel.Usage.Output

        /// The additional metadata with a token count.
        public var metadata: [String : GeneratedContent]

        /// Creates a usage update.
        ///
        /// - Parameters:
        ///   - input: Token counts for the transcript.
        ///   - output: Token counts for the response.
        ///   - metadata: Additional metadata to record alongside the token counts.
        public init(input: LanguageModelExecutorGenerationChannel.Usage.Input, output: LanguageModelExecutorGenerationChannel.Usage.Output, metadata: [String : any ConvertibleToGeneratedContent] = [:])
    }

    /// Text appended to a streaming entry's current text segment.
    ///
    /// Use this type when appending text with ``Response`` and ``Reasoning`` actions.
    public struct TextFragment : Sendable {

        /// The text to append to the entry's current text segment.
        public var content: String

        /// The identifier of the text segment to append to, or empty to append to the
        /// current segment.
        public var segmentID: String?

        /// The number of tokens the text carries.
        public var tokenCount: Int
    }

    /// A replacement for a streaming entry's current text segment.
    ///
    /// The `tokenCount` is the producer's count of tokens carried by `content` and
    /// is used by safety or usage accounting to credit the replacement against.
    public struct TextSegmentReplacement : Sendable {

        /// The replacement text for the entry's current text segment.
        public var content: String

        /// The identifier of the text segment to replace, or empty for the current segment.
        public var segmentID: String?

        /// The number of tokens the replacement text carries.
        public var tokenCount: Int
    }

    /// A model-generated response event: text, segment replacements, citations,
    /// advisories, custom segments, metadata, or usage.
    public struct Response : Sendable {

        /// The identifier for the entry.
        public var entryID: String?

        /// The action to perform.
        public var action: LanguageModelExecutorGenerationChannel.Response.Action
    }

    /// A reasoning event.
    ///
    /// A per-entry reasoning text, segment replacements, signature updates, metadata, or usage.
    /// Reasoning events are peers of ``Response`` and ``ToolCalls``.
    public struct Reasoning : Sendable {

        /// The identifier for the entry.
        public var entryID: String?

        /// The action to perform.
        public var action: LanguageModelExecutorGenerationChannel.Reasoning.Action
    }

    /// Payload for a reasoning entry's signature update.
    ///
    /// The signature is an opaque, producer-supplied token; each `updateSignature` event replaces
    /// the prior value wholesale. `tokenCount` is the producer's count of tokens carried by the
    /// signature, used for usage accounting.
    public struct ReasoningSignature : Sendable {

        /// The opaque token that authenticates the reasoning entry.
        public var signature: Data

        /// The number of the tokens the signature carries.
        public var tokenCount: Int
    }

    /// A tool-call lifecycle event, including per-call argument streaming, reasoning, metadata, usage,
    /// or retraction.
    ///
    /// Events for a specific tool call route through ``Action/toolCall(id:name:action:)``. Use
    /// ``Action/removeToolCall(id:)`` to drop a tool call the model retracted.
    public struct ToolCalls : Sendable {

        /// The identifier for the entry.
        public var entryID: String?

        /// The action to perform.
        public var action: LanguageModelExecutorGenerationChannel.ToolCalls.Action
    }

    /// A top-level data-entry event addressed to a transcript entry.
    ///
    /// A ``DataEntry`` event carries an entry-level action; the currently defined
    /// action is ``Action/update(contentType:content:metadata:)``, which upserts a
    /// data entry with the given fields — replacing the existing entry that
    /// matches `entryID`, or appending a new one.
    @available(iOS 27.2, macOS 27.2, watchOS 27.2, tvOS 27.2, *)
    public struct DataEntry : Sendable {

        /// The identifier for the entry.
        public var entryID: String?

        /// The action to perform.
        public var action: LanguageModelExecutorGenerationChannel.DataEntry.Action
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelExecutorGenerationChannel.AsyncIterator {

    /// Asynchronously advances to the next element and returns it, or ends the
    /// sequence if there is no next element.
    ///
    /// - Returns: The next element, if it exists, or `nil` to signal the end of
    ///   the sequence.
    public mutating func next(isolation actor: isolated (any Actor)?) async throws -> LanguageModelExecutorGenerationChannel.Event?
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelExecutorGenerationChannel.Event {

    /// A response event addressed to a transcript entry.
    ///
    /// - Parameters:
    ///   - entryID: The response entry this event targets. Pass `nil` to let the
    ///     framework coalesce consecutive response events into a single entry;
    ///     pass an explicit id to anchor the event to a specific entry.
    ///   - action: The operation to perform on the response entry.
    public static func response(entryID: String? = nil, action: LanguageModelExecutorGenerationChannel.Response.Action) -> LanguageModelExecutorGenerationChannel.Event

    /// A reasoning event addressed to a transcript entry.
    ///
    /// - Parameters:
    ///   - entryID: The reasoning entry this event targets. Pass `nil` to coalesce
    ///     consecutive reasoning deltas into the trailing reasoning entry; pass an
    ///     explicit id when you need a stable anchor.
    ///   - action: The operation to perform on the reasoning entry.
    public static func reasoning(entryID: String? = nil, action: LanguageModelExecutorGenerationChannel.Reasoning.Action) -> LanguageModelExecutorGenerationChannel.Event

    /// A tool-calls event addressed to a transcript entry.
    ///
    /// - Parameters:
    ///   - entryID: The tool-calls entry this event targets. Pass `nil` to let the
    ///     framework coalesce consecutive tool-calls events into a single entry;
    ///     pass an explicit id to anchor the event to a specific entry.
    ///   - action: The operation to perform on the tool-calls entry.
    public static func toolCalls(entryID: String? = nil, action: LanguageModelExecutorGenerationChannel.ToolCalls.Action) -> LanguageModelExecutorGenerationChannel.Event

    /// A data-entry event addressed to a transcript entry.
    ///
    /// The entry's `contentType` (from ``DataEntry/Action/update(contentType:content:metadata:)``)
    /// is checked against ``LanguageModel/supportsDataEntryType(_:)`` before the entry is
    /// appended, and rejected entries surface as
    /// ``LanguageModelError/unsupportedTranscriptContent(_:)``.
    ///
    /// - Parameters:
    ///   - entryID: The identifier for the data entry to upsert. Pass `nil` to
    ///     have the framework assign a fresh id.
    ///   - action: The operation to perform on the data entry.
    @available(iOS 27.2, macOS 27.2, watchOS 27.2, tvOS 27.2, *)
    public static func data(entryID: String? = nil, action: LanguageModelExecutorGenerationChannel.DataEntry.Action) -> LanguageModelExecutorGenerationChannel.Event
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelExecutorGenerationChannel.Usage {

    /// Token counts for the transcript submitted to the model.
    public struct Input : Sendable {

        /// The total number of input tokens from the transcript.
        public var totalTokenCount: Int

        /// The number of input tokens that were served from a cache.
        public var cachedTokenCount: Int

        /// Creates input token counts for the transcript submitted to the model.
        ///
        /// - Parameters:
        ///   - totalTokenCount: The total number of input tokens from the transcript.
        ///   - cachedTokenCount: The number of input tokens served from a cache.
        public init(totalTokenCount: Int, cachedTokenCount: Int)
    }

    /// Token counts for the output produced by the model.
    public struct Output : Sendable {

        /// The total number of output tokens.
        public var totalTokenCount: Int

        /// The number of output tokens that were part of the model's
        /// reasoning output.
        public var reasoningTokenCount: Int

        /// Creates output token counts for the response the model produces.
        ///
        /// - Parameters:
        ///   - totalTokenCount: The total number of output tokens.
        ///   - reasoningTokenCount: The number of output tokens that were part of the model's
        ///     reasoning output.
        public init(totalTokenCount: Int, reasoningTokenCount: Int)
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelExecutorGenerationChannel.Response {

    /// An operation that can be performed on a response entry.
    ///
    /// `Action` is an enum-like struct; construct one with a leading-dot factory
    /// such as ``appendText(_:segmentID:tokenCount:)``.
    public struct Action : Sendable {
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelExecutorGenerationChannel.Reasoning {

    /// An operation that can be performed on a reasoning entry.
    ///
    /// `Action` is an enum-like struct; construct one with a leading-dot factory
    /// such as ``appendText(_:segmentID:tokenCount:)``.
    public struct Action : Sendable {
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelExecutorGenerationChannel.ToolCalls {

    /// An operation that can be performed on a tool-calls entry.
    ///
    /// `Action` is an enum-like struct; construct one with a leading-dot factory
    /// such as ``toolCall(id:name:action:)``.
    public struct Action : Sendable {
    }

    /// A per-tool-call event payload.
    ///
    /// The `id` and `name` route the event to a specific tool call within the `ToolCalls` entry.
    /// The`action` names the mutation.
    public struct ToolCall : Sendable {

        /// The identifier for the tool call.
        public var id: String

        /// The name of the tool call.
        public var name: String

        /// The action to perform.
        public var action: LanguageModelExecutorGenerationChannel.ToolCalls.ToolCall.Action
    }
}

@available(iOS 27.2, macOS 27.2, watchOS 27.2, tvOS 27.2, *)
extension LanguageModelExecutorGenerationChannel.DataEntry {

    /// An operation that can be performed on a data entry.
    ///
    /// `Action` is an enum-like struct; construct one with a leading-dot factory
    /// such as ``update(contentType:content:metadata:)``.
    public struct Action : Sendable {
    }
}

@available(iOS 27.2, macOS 27.2, watchOS 27.2, tvOS 27.2, *)
extension LanguageModelExecutorGenerationChannel.DataEntry {

    /// The content carried by an ``Action/update(contentType:content:metadata:)`` action.
    public struct Update : Sendable {

        /// A `UTType` identifying how to interpret ``content``.
        public var contentType: UTType

        /// A raw binary representation of the entry.
        public var content: Data

        /// Metadata pertinent to the entry.
        public var metadata: GeneratedContent
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelExecutorGenerationChannel.Response.Action {

    /// Creates an action that appends text to the entry's current text segment.
    ///
    /// - Parameters:
    ///   - text: The text to append to the entry.
    ///   - segmentID: The identifier of the segment to append to, or `nil` to append to the
    ///     current segment.
    ///   - tokenCount: The number of the tokens the text carries.
    public static func appendText(_ text: String, segmentID: String? = nil, tokenCount: Int) -> LanguageModelExecutorGenerationChannel.Response.Action

    /// Creates an action that replaces the entry's current text segment.
    ///
    /// - Parameters:
    ///   - text: The replacement text for the segment.
    ///   - segmentID: The identifier of the segment to replace, or `nil` for the current
    ///     segment.
    ///   - tokenCount: The number of the tokens the replacement text carries.
    public static func replaceTextSegment(_ text: String, segmentID: String? = nil, tokenCount: Int) -> LanguageModelExecutorGenerationChannel.Response.Action

    /// Creates an action that adds an attachment segment to the entry.
    ///
    /// - Parameter segment: The attatchment segment to add.
    public static func addAttachmentSegment(_ segment: Transcript.AttachmentSegment) -> LanguageModelExecutorGenerationChannel.Response.Action

    /// Creates an action that removes an attachment segment from the entry.
    ///
    /// - Parameter id: The identifier of the attachment segment to remove.
    public static func removeAttachmentSegment(id: String) -> LanguageModelExecutorGenerationChannel.Response.Action

    /// Creates an action that replaces the entry's metadata.
    ///
    /// - Parameter values: The key-value pairs that replace the entry's current metadata.
    public static func updateMetadata(_ values: [String : any ConvertibleToGeneratedContent]) -> LanguageModelExecutorGenerationChannel.Response.Action

    /// Creates an action that replaces the entry's token-usage totals.
    ///
    /// - Parameters:
    ///   - input: The token counts for the transcript submitted to the model.
    ///   - output: The token counts for the response the model produces.
    ///   - metadata: Additional metadata to record alongside the token counts.
    public static func updateUsage(input: LanguageModelExecutorGenerationChannel.Usage.Input, output: LanguageModelExecutorGenerationChannel.Usage.Output, metadata: [String : any ConvertibleToGeneratedContent] = [:]) -> LanguageModelExecutorGenerationChannel.Response.Action
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelExecutorGenerationChannel.Reasoning.Action {

    /// Creates an action that appends text to the entry's current text segment.
    ///
    /// - Parameters:
    ///   - text: The text to append to the entry.
    ///   - segmentID: The identifier of the segment to append to, or `nil` to append to the
    ///     current segment.
    ///   - tokenCount: The number of the tokens the text carries.
    public static func appendText(_ text: String, segmentID: String? = nil, tokenCount: Int) -> LanguageModelExecutorGenerationChannel.Reasoning.Action

    /// Creates an action that replaces the entry's current text segment.
    ///
    /// - Parameters:
    ///   - text: The replacement text for the segment.
    ///   - segmentID: The identifier of the segment to replace, or `nil` for the current
    ///     segment.
    ///   - tokenCount: The number of the tokens the replacement text carries.
    public static func replaceTextSegment(_ text: String, segmentID: String? = nil, tokenCount: Int) -> LanguageModelExecutorGenerationChannel.Reasoning.Action

    /// Creates an action that replaces the reasoning entry's signature.
    ///
    /// - Parameters:
    ///   - signature: The opaque token that replaces the entry's current signature.
    ///   - tokenCount: The number of the tokens the signature carries.
    public static func updateSignature(_ signature: Data, tokenCount: Int) -> LanguageModelExecutorGenerationChannel.Reasoning.Action

    /// Creates an action that replaces the entry's metadata.
    ///
    /// - Parameter values: The key-value pairs that replace the entry's current metadata.
    public static func updateMetadata(_ values: [String : any ConvertibleToGeneratedContent]) -> LanguageModelExecutorGenerationChannel.Reasoning.Action

    /// Creates an action that replaces the entry's token-usage totals.
    ///
    /// - Parameters:
    ///   - input: The token counts for the transcript submitted to the model.
    ///   - output: The token counts for the response the model produces.
    ///   - metadata: Additional metadata to record alongside the token counts.
    public static func updateUsage(input: LanguageModelExecutorGenerationChannel.Usage.Input, output: LanguageModelExecutorGenerationChannel.Usage.Output, metadata: [String : any ConvertibleToGeneratedContent] = [:]) -> LanguageModelExecutorGenerationChannel.Reasoning.Action
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelExecutorGenerationChannel.ToolCalls.Action {

    /// Creates an action that routes an event to a specific tool call within the entry.
    ///
    /// - Parameters:
    ///   - id: The identifier of the tool call the event targets.
    ///   - name: The name of the tool being called.
    ///   - action: The operation to perform on the tool call.
    public static func toolCall(id: String, name: String, action: LanguageModelExecutorGenerationChannel.ToolCalls.ToolCall.Action) -> LanguageModelExecutorGenerationChannel.ToolCalls.Action

    /// Creates an action that removes a tool call.
    ///
    /// - Parameter id: The identifier of the tool call to remove.
    public static func removeToolCall(id: String) -> LanguageModelExecutorGenerationChannel.ToolCalls.Action

    /// Creates an action that replaces the tool call’s metadata.
    ///
    /// - Parameter values: The key-value pairs that replace the tool call’s current metadata.
    public static func updateMetadata(_ values: [String : any ConvertibleToGeneratedContent]) -> LanguageModelExecutorGenerationChannel.ToolCalls.Action

    /// Creates an action that replaces the entry's token-usage totals.
    ///
    /// - Parameters:
    ///   - input: The token counts for the transcript submitted to the model.
    ///   - output: The token counts for the response the model produces.
    ///   - metadata: Additional metadata to record alongside the token counts.
    public static func updateUsage(input: LanguageModelExecutorGenerationChannel.Usage.Input, output: LanguageModelExecutorGenerationChannel.Usage.Output, metadata: [String : any ConvertibleToGeneratedContent] = [:]) -> LanguageModelExecutorGenerationChannel.ToolCalls.Action
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelExecutorGenerationChannel.ToolCalls.ToolCall {

    /// An operation that can be performed on a tool call.
    ///
    /// `Action` is an enum-like struct; construct one with a leading-dot factory
    /// such as ``appendArguments(_:tokenCount:)``.
    public struct Action : Sendable {
    }

    /// Argument text appended to this tool call.
    ///
    /// The first event for a given id opens the tool call (using `name` from the enclosing
    /// ``ToolCall``); subsequent events append additional argument text.
    public struct ArgumentsFragment : Sendable {

        /// The argument text to append to the tool call.
        public var content: String

        /// The number of tokens the argument text carries.
        public var tokenCount: Int
    }
}

@available(iOS 27.2, macOS 27.2, watchOS 27.2, tvOS 27.2, *)
extension LanguageModelExecutorGenerationChannel.DataEntry.Action {

    public static func update(contentType: UTType, content: Data, metadata: GeneratedContent = GeneratedContent(properties: [:])) -> LanguageModelExecutorGenerationChannel.DataEntry.Action
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelExecutorGenerationChannel.ToolCalls.ToolCall.Action {

    /// Creates an action that appends argument text to the tool call.
    ///
    /// - Parameters:
    ///   - content: The argument text to append to the tool call.
    ///   - tokenCount: The number of the tokens the argument text carries.
    public static func appendArguments(_ content: String, tokenCount: Int) -> LanguageModelExecutorGenerationChannel.ToolCalls.ToolCall.Action

    /// Creates an action that replaces the metadata for a tool call.
    ///
    /// - Parameter values: The key-value pairs that replace the current metadata for a tool call.
    public static func updateMetadata(_ values: [String : any ConvertibleToGeneratedContent]) -> LanguageModelExecutorGenerationChannel.ToolCalls.ToolCall.Action
}

/// A type that contains the details for a generation request.
///
/// A generation request is the input payload that
/// ``LanguageModelExecutor/respond(to:model:streamingInto:)`` handles. It bundles
/// everything the executor needs to translate a framework call into a backend request,
/// like the conversation so far, what tools are available, and so on.
@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
public struct LanguageModelExecutorGenerationRequest : Sendable {

    /// A request id for logging and tracing purposes.
    public var id: UUID

    /// A transcript to generate the next entry for.
    public var transcript: Transcript

    /// The subset of tool definitions that the model is allowed to call.
    public var enabledToolDefinitions: [Transcript.ToolDefinition]

    /// An optional schema dictating the required output format.
    public var schema: GenerationSchema?

    /// Generation options that control sampling behavior.
    public var generationOptions: GenerationOptions

    /// Settings that configure how the model is prompted.
    public var contextOptions: ContextOptions

    /// Metadata to attach to the request.
    public var metadata: [String : GeneratedContent]
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelExecutorGenerationRequest {

    /// Creates a generation request.
    ///
    /// - Parameters:
    ///   - id: The request identifier.
    ///   - transcript: The transcript to generate the next entry for.
    ///   - enabledTools: The subset of tool definitions that the model can call.
    ///   - schema: The schema dictating the required output format.
    ///   - generationOptions: The generation options to use.
    ///   - contextOptions: The settings that configure how the model is prompted.
    ///   - metadata: The metadata to attach to the request.
    public init(id: UUID, transcript: Transcript, enabledTools: [Transcript.ToolDefinition], schema: GenerationSchema? = nil, generationOptions: GenerationOptions, contextOptions: ContextOptions, metadata: [String : any ConvertibleToGeneratedContent])
}

/// Feedback appropriate for logging or attaching to Feedback Assistant.
///
/// `LanguageModelFeedback` is a namespace with structures for describing feedback in a consistent way.
/// ``LanguageModelFeedback/Sentiment`` describes the sentiment of the feedback, while
/// ``LanguageModelFeedback/Issue`` offers a standard template for issues.
///
/// Given a model session, use
/// ``LanguageModelSession/logFeedbackAttachment(sentiment:issues:desiredOutput:)`` to produce
/// structured feedback.
///
/// ```swift
/// let session = LanguageModelSession()
/// let response = try await session.respond(to: "What is the capital of France?")
///
/// // Create feedback for a problematic response.
/// let feedbackData = session.logFeedbackAttachment(
///     sentiment: LanguageModelFeedback.Sentiment.negative,
///     issues: [
///         LanguageModelFeedback.Issue(
///             category: .incorrect,
///             explanation: "The model provided outdated information"
///         )
///     ],
///     desiredOutput: Transcript.Entry.response(...)
/// )
/// ```
@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
public struct LanguageModelFeedback {
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelFeedback {

    /// A sentiment regarding the model's response.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    public enum Sentiment : Sendable, CaseIterable {

        /// A positive sentiment.
        case positive

        /// A negative sentiment.
        case negative

        /// A neutral sentiment.
        case neutral

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: LanguageModelFeedback.Sentiment, b: LanguageModelFeedback.Sentiment) -> Bool

        /// A type that can represent a collection of all values of this type.
        @available(macOS 26.0, iOS 26.0, tvOS 27.0, watchOS 27.0, *)
        public typealias AllCases = [LanguageModelFeedback.Sentiment]

        /// A collection of all values of this type.
        nonisolated public static var allCases: [LanguageModelFeedback.Sentiment] { get }

        /// Hashes the essential components of this value by feeding them into the
        /// given hasher.
        ///
        /// Implement this method to conform to the `Hashable` protocol. The
        /// components used for hashing must be the same as the components compared
        /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
        /// with each of these components.
        ///
        /// - Important: In your implementation of `hash(into:)`,
        ///   don't call `finalize()` on the `hasher` instance provided,
        ///   or replace it with a different instance.
        ///   Doing so may become a compile-time error in the future.
        ///
        /// - Parameter hasher: The hasher to use when combining the components
        ///   of this instance.
        public func hash(into hasher: inout Hasher)

        /// The hash value.
        ///
        /// Hash values are not guaranteed to be equal across different executions of
        /// your program. Do not save hash values to use during a future execution.
        ///
        /// - Important: `hashValue` is deprecated as a `Hashable` requirement. To
        ///   conform to `Hashable`, implement the `hash(into:)` requirement instead.
        ///   The compiler provides an implementation for `hashValue` for you.
        public var hashValue: Int { get }
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelFeedback {

    /// An issue with the model's response.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    public struct Issue : Sendable {

        /// Creates an issue.
        ///
        /// - Parameters:
        ///   - category: A category for this issue.
        ///   - explanation: An optional explanation of this issue.
        public init(category: LanguageModelFeedback.Issue.Category, explanation: String? = nil)
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelFeedback.Sentiment : Equatable {
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelFeedback.Sentiment : Hashable {
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelFeedback.Issue {

    /// Categories for model response issues.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    public enum Category : Sendable, CaseIterable {

        /// An unhelpful response.
        ///
        /// An unhelpful issue might be where you asked for a recipe, and the model gave you a list of
        /// ingredients but not amounts.
        case unhelpful

        /// An overly verbose response.
        ///
        /// A verbose issue might be where you asked for a simple recipe, and the model wrote introductory
        /// and conclusion paragraphs.
        case tooVerbose

        /// A response that doesn't follow instructions correctly.
        ///
        /// An instruction issue might be where you asked for a recipe in numbered steps, and the model
        /// provided a recipe but didn't number the steps.
        case didNotFollowInstructions

        /// An incorrect response.
        ///
        /// An incorrect issue might be where you asked how to make a pizza, and the model suggested using glue.
        case incorrect

        /// A response that exhibits bias or perpetuates a stereotype.
        ///
        /// A stereotype or bias issue might be where you ask the model to summarize an article written by
        /// a male, and the model doesn't state the author's sex, but the model uses male pronouns.
        case stereotypeOrBias

        /// A response with suggestive or sexual material.
        ///
        /// A suggestive or sexual issue might be where you ask the model to draft a script for a school
        /// play, and it includes a sex scene.
        case suggestiveOrSexual

        /// A response with vulgar or offensive material.
        ///
        /// A vulgar or offensive issue might be where you ask the model to draft a complaint about poor
        /// customer service, and it uses profanity.
        case vulgarOrOffensive

        /// An unexpected guardrail violation.
        ///
        /// An unexpected guardrail issue might be where you ask for a cake recipe, and the framework
        /// throws a guardrail violation error.
        case triggeredGuardrailUnexpectedly

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: LanguageModelFeedback.Issue.Category, b: LanguageModelFeedback.Issue.Category) -> Bool

        /// A type that can represent a collection of all values of this type.
        @available(macOS 26.0, iOS 26.0, tvOS 27.0, watchOS 27.0, *)
        public typealias AllCases = [LanguageModelFeedback.Issue.Category]

        /// A collection of all values of this type.
        nonisolated public static var allCases: [LanguageModelFeedback.Issue.Category] { get }

        /// Hashes the essential components of this value by feeding them into the
        /// given hasher.
        ///
        /// Implement this method to conform to the `Hashable` protocol. The
        /// components used for hashing must be the same as the components compared
        /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
        /// with each of these components.
        ///
        /// - Important: In your implementation of `hash(into:)`,
        ///   don't call `finalize()` on the `hasher` instance provided,
        ///   or replace it with a different instance.
        ///   Doing so may become a compile-time error in the future.
        ///
        /// - Parameter hasher: The hasher to use when combining the components
        ///   of this instance.
        public func hash(into hasher: inout Hasher)

        /// The hash value.
        ///
        /// Hash values are not guaranteed to be equal across different executions of
        /// your program. Do not save hash values to use during a future execution.
        ///
        /// - Important: `hashValue` is deprecated as a `Hashable` requirement. To
        ///   conform to `Hashable`, implement the `hash(into:)` requirement instead.
        ///   The compiler provides an implementation for `hashValue` for you.
        public var hashValue: Int { get }
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelFeedback.Issue.Category : Equatable {
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelFeedback.Issue.Category : Hashable {
}

/// An object that represents a session that interacts with a language model.
///
/// A session is a single context that you use to generate content with, and maintains state between
/// requests. You can reuse the existing instance or create a new one each time you call the model. When
/// you create a session you can provide instructions that tell the model what its role is and
/// provide guidance on how to respond.
///
/// ```swift
/// let session = LanguageModelSession(instructions: """
///     You are a motivational workout coach that provides quotes to inspire \
///     and motivate athletes.
///     """
/// )
/// let prompt = "Generate a motivational quote for my next workout."
/// let response = try await session.respond(to: prompt)
/// ```
///
/// The framework records each call to the model in a ``Transcript`` that includes all prompts and
/// responses. If your session exceeds the available context size, it throws
/// ``LanguageModelError/contextSizeExceeded(_:)``. For more information on managing
/// the context window size, see <doc:managing-the-context-window>.
///
/// Use Instruments to analyze token consumption while your app is running and to look for
/// opportunities to improve performance, like with ``prewarm(promptPrefix:)``. For more
/// information on Instruments, see
/// <doc:analyzing-the-runtime-performance-of-your-foundation-models-app>.
@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
final public class LanguageModelSession {

    /// A full history of interactions, including user inputs and model responses.
    final public var transcript: Transcript

    @objc deinit
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension LanguageModelSession {

    /// An error that may occur while generating a response.
    ///
    /// @DeprecationSummary {
    ///   When your app is built against Xcode 27 or later, the framework throws ``LanguageModelError``,
    ///   ``SystemLanguageModel/Error``, or ``LanguageModelSession/Error`` instead. If
    ///   your app deploys to iOS 26, macOS 26 or visionOS 26, match the new types inside an availability
    ///   check and fall back to ``LanguageModelSession/GenerationError`` for earlier system versions.
    ///
    ///   Apps built against Xcode 26 continues to receive ``LanguageModelSession/GenerationError``.
    /// }
    @available(iOS, introduced: 26.0, deprecated: 27.0)
    @available(macOS, introduced: 26.0, deprecated: 27.0)
    @available(visionOS, introduced: 26.0, deprecated: 27.0)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public enum GenerationError : Error, LocalizedError {

        /// An error that signals the session reached its context window size limit.
        ///
        /// @DeprecationSummary {
        ///     Use ``LanguageModelError/contextSizeExceeded(_:)`` instead.
        /// }
        ///
        /// This error occurs when you use the available tokens for the context window of 4,096 tokens. The
        /// token count includes instructions, prompts, and outputs for a session instance. A single token
        /// corresponds to approximately three to four characters in languages like English, Spanish, or
        /// German, and one token per character in languages like Japanese, Chinese, and Korean.
        ///
        /// Start a new session when you exceed the content window size, and try again using a shorter
        /// prompt or shorter output length.
        ///
        /// For more information on managing the context window size,
        /// see <doc:managing-the-context-window>.
        @available(iOS, deprecated: 27.0, message: "Use ``LanguageModelError/contextSizeExceeded(_:)`` instead.")
        @available(macOS, deprecated: 27.0, message: "Use ``LanguageModelError/contextSizeExceeded(_:)`` instead.")
        @available(visionOS, deprecated: 27.0, message: "Use ``LanguageModelError/contextSizeExceeded(_:)`` instead.")
        case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)

        /// An error that indicates the assets required for the session are unavailable.
        ///
        /// @DeprecationSummary {
        ///     Use ``SystemLanguageModel/Error/assetsUnavailable(_:)`` instead.
        /// }
        ///
        /// This may happen if you forget to check model availability to begin with,
        /// or if the model assets are deleted. This can happen if the user disables
        /// AppleIntelligence while your app is running.
        ///
        /// You may be able to recover from this error by retrying later after the
        /// device has freed up enough space to redownload model assets.
        @available(iOS, deprecated: 27.0, message: "Use ``SystemLanguageModel/Error/assetsUnavailable(_:)`` instead.")
        @available(macOS, deprecated: 27.0, message: "Use ``SystemLanguageModel/Error/assetsUnavailable(_:)`` instead.")
        @available(visionOS, deprecated: 27.0, message: "Use ``SystemLanguageModel/Error/assetsUnavailable(_:)`` instead.")
        case assetsUnavailable(LanguageModelSession.GenerationError.Context)

        /// An error that indicates the system's safety guardrails are triggered by content in a
        /// prompt or the response generated by the model.
        ///
        /// @DeprecationSummary {
        ///     Use ``LanguageModelError/guardrailViolation(_:)`` instead.
        /// }
        @available(iOS, deprecated: 27.0, message: "Use ``LanguageModelError/guardrailViolation(_:)`` instead.")
        @available(macOS, deprecated: 27.0, message: "Use ``LanguageModelError/guardrailViolation(_:)`` instead.")
        @available(visionOS, deprecated: 27.0, message: "Use ``LanguageModelError/guardrailViolation(_:)`` instead.")
        case guardrailViolation(LanguageModelSession.GenerationError.Context)

        /// An error that indicates a generation guide with an unsupported pattern was used.
        ///
        /// @DeprecationSummary {
        ///     Use ``LanguageModelError/unsupportedGenerationGuide(_:)`` instead.
        /// }
        @available(iOS, deprecated: 27.0, message: "Use ``LanguageModelError/unsupportedGenerationGuide(_:)`` instead.")
        @available(macOS, deprecated: 27.0, message: "Use ``LanguageModelError/unsupportedGenerationGuide(_:)`` instead.")
        @available(visionOS, deprecated: 27.0, message: "Use ``LanguageModelError/unsupportedGenerationGuide(_:)`` instead.")
        case unsupportedGuide(LanguageModelSession.GenerationError.Context)

        /// An error that indicates an error that occurs if the model is prompted to respond in a language
        /// that it does not support.
        ///
        /// @DeprecationSummary {
        ///     Use ``LanguageModelError/unsupportedLanguageOrLocale(_:)`` instead.
        /// }
        @available(iOS, deprecated: 27.0, message: "Use ``LanguageModelError/unsupportedLanguageOrLocale(_:)`` instead.")
        @available(macOS, deprecated: 27.0, message: "Use ``LanguageModelError/unsupportedLanguageOrLocale(_:)`` instead.")
        @available(visionOS, deprecated: 27.0, message: "Use ``LanguageModelError/unsupportedLanguageOrLocale(_:)`` instead.")
        case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)

        /// An error that indicates the session failed to deserialize a valid generable type from model output.
        ///
        /// @DeprecationSummary {
        ///     Use ``GeneratedContent/ParsingError`` instead.
        /// }
        ///
        /// This can happen if generation was terminated early.
        @available(iOS, deprecated: 27.0, message: "Use ``GeneratedContent/ParsingError`` instead.")
        @available(macOS, deprecated: 27.0, message: "Use ``GeneratedContent/ParsingError`` instead.")
        @available(visionOS, deprecated: 27.0, message: "Use ``GeneratedContent/ParsingError`` instead.")
        case decodingFailure(LanguageModelSession.GenerationError.Context)

        /// An error that indicates your session has been rate limited.
        ///
        /// @DeprecationSummary {
        ///     Use ``LanguageModelError/rateLimited(_:)`` instead.
        /// }
        ///
        /// This error will only happen if your app is running in the background
        /// and exceeds the system defined rate limit.
        @available(iOS, deprecated: 27.0, message: "Use ``LanguageModelError/rateLimited(_:)`` instead.")
        @available(macOS, deprecated: 27.0, message: "Use ``LanguageModelError/rateLimited(_:)`` instead.")
        @available(visionOS, deprecated: 27.0, message: "Use ``LanguageModelError/rateLimited(_:)`` instead.")
        case rateLimited(LanguageModelSession.GenerationError.Context)

        /// An error that happens if you attempt to make a session respond to a
        /// second prompt while it's still responding to the first one.
        ///
        /// @DeprecationSummary {
        ///     Use ``LanguageModelSession/Error/concurrentRequests`` instead.
        /// }
        @available(iOS, deprecated: 27.0, message: "Use ``LanguageModelSession/Error/concurrentRequests`` instead.")
        @available(macOS, deprecated: 27.0, message: "Use ``LanguageModelSession/Error/concurrentRequests`` instead.")
        @available(visionOS, deprecated: 27.0, message: "Use ``LanguageModelSession/Error/concurrentRequests`` instead.")
        case concurrentRequests(LanguageModelSession.GenerationError.Context)

        /// An error indicating that the model refused to answer.
        ///
        /// @DeprecationSummary {
        ///     Use ``LanguageModelError/refusal(_:)`` instead.
        /// }
        ///
        /// This error can happen for prompts that do not violate any guardrail policy, but
        /// the model isn't able to provide the kind of response you requested. You can
        /// choose to handle this error by showing a predetermined message of your choice,
        /// or you can use the `Refusal` to generate an explanation from the model itself.
        @available(iOS, deprecated: 27.0, message: "Use ``LanguageModelError/refusal(_:)`` instead.")
        @available(macOS, deprecated: 27.0, message: "Use ``LanguageModelError/refusal(_:)`` instead.")
        @available(visionOS, deprecated: 27.0, message: "Use ``LanguageModelError/refusal(_:)`` instead.")
        case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)
    }
}

@available(iOS 26.0, macOS 26.0, tvOS 27.3, *)
@available(watchOS, unavailable)
extension LanguageModelSession {

    /// Creates a session in a blank slate state with string-based instructions.
    ///
    /// - Parameters
    ///   - model: The language model to use for this session.
    ///   - tools: Tools to make available to the model for this session.
    ///   - instructions: Instructions that control the model's behavior.
    @available(watchOS, unavailable)
    public convenience init(model: SystemLanguageModel = .default, tools: [any Tool] = [], instructions: String? = nil)

    /// Creates a session in a blank slate state with an instructions builder.
    ///
    /// - Parameters
    ///   - model: The language model to use for this session.
    ///   - tools: Tools to make available to the model for this session.
    ///   - instructions: Instructions that control the model's behavior.
    @available(watchOS, unavailable)
    public convenience init(model: SystemLanguageModel = .default, tools: [any Tool] = [], @InstructionsBuilder instructions: () throws -> Instructions) rethrows

    /// Creates a session in a blank slate state with instructions.
    ///
    /// - Parameters
    ///   - model: The language model to use for this session.
    ///   - tools: Tools to make available to the model for this session.
    ///   - instructions: Instructions that control the model's behavior.
    @available(watchOS, unavailable)
    public convenience init(model: SystemLanguageModel = .default, tools: [any Tool] = [], instructions: Instructions? = nil)

    /// Creates a session by rehydrating from a transcript.
    ///
    /// - Parameters
    ///   - model: The language model to use for this session.
    ///   - transcript: A transcript to resume from.
    ///   - tools: Tools to make available to the model for this session.
    @available(watchOS, unavailable)
    public convenience init(model: SystemLanguageModel = .default, tools: [any Tool] = [], transcript: Transcript)
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession {

    /// A type-erased dynamic profile.
    public struct AnyDynamicProfile : LanguageModelSession.DynamicProfile {

        /// Creates an instance from the dynamic profile you specify.
        ///
        /// - Parameters:
        ///   - dynamicProfile: The dynamic profile.
        public init(_ dynamicProfile: any LanguageModelSession.DynamicProfile)

        /// The type of dynamic profile that represent this profile.
        @available(macOS 27.0, iOS 27.0, tvOS 27.0, watchOS 27.0, *)
        public typealias Body = Never
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession {

    /// A dynamic profile that contains one or more profiles.
    ///
    /// A dynamic profile is the top-level coordination layer that manages profiles. It
    /// determines which ``Profile`` is in an active state and allows a ``LanguageModelSession``
    /// to switch between entirely different configurations as app state changes. A body
    /// must resolve to a single profile.
    ///
    /// ``DynamicInstructions`` declares what content and tools the model sees, and
    /// ``Profile`` binds that content to how a single configuration runs. That
    /// configuration includes details like the model to use, temperature, reasoning
    /// level, and so on.
    ///
    /// ```swift
    /// struct PresentationProfile: LanguageModelSession.DynamicProfile {
    ///     // The data source for the profile.
    ///     var isEditingImage = true
    ///     var isEditingAnimation = false
    ///
    ///     // Determine which profile to load based on the current state.
    ///     var body: some LanguageModelSession.DynamicProfile {
    ///         if isEditingImage {
    ///             // Use the editing image profile.
    ///         } else if isEditingAnimation {
    ///             // Use the editing animation profile.
    ///         } else {
    ///             // Use the default profile.
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// Use ``historyTransform(_:)`` to perform stateless transcript transforms. This
    /// allows you to modify the transcript that's sent to the model, but doesn't impact
    /// the global transcript state. For example, the request might only need the last
    /// twenty entries instead of the full transcript:
    ///
    /// ```swift
    /// Profile {
    ///     // The instructions and tools necessary for the task.
    /// }
    /// .historyTransform { history in
    ///     Array(history.suffix(20))
    /// }
    /// ```
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public protocol DynamicProfile {

        /// The type of dynamic profile that represent this profile.
        associatedtype Body : LanguageModelSession.DynamicProfile

        /// The content of the dynamic profile.
        @LanguageModelSession.DynamicProfileBuilder var body: Self.Body { get }
    }

    /// A profile that contains dynamic instructions.
    ///
    /// A profile binds ``DynamicInstructions`` to a set of session-level configuration
    /// values. The ``DynamicInstructions`` describes the content and tools and a
    /// ``DynamicProfile`` orchestrates transitions between session configurations.
    ///
    /// ```swift
    /// Profile {
    ///     // Custom instructions and tools for a creative task.
    /// }
    /// // Use a higher creative temperature value when a person likes poetry.
    /// .temperature(likesPoetry ? 0.8 : 0.1)
    /// // Perform deeper reasoning when a person likes astronomy.
    /// .reasoningLevel(likesAstronomy ? .deep : .light)
    /// ```
    ///
    /// A ``Profile`` conforms to ``DynamicProfile`` and includes all the same modifiers
    /// that you use to configure a unit of work to perform. Observe and react to key
    /// moments during a session by using life cycle modifiers. When a profile and a
    /// subprofile both register a callback, the framework calls both. The following
    /// shows observing ``DynamicProfile/onToolOutput(perform:)`` to handle logging after
    /// a tool provides output:
    ///
    /// ```swift
    /// Profile {
    ///     // Custom instructions and tools for the task.
    /// }
    /// .onToolOutput { toolCall, output in
    ///     // Runs after the tool to log any necessary activity.
    /// }
    /// ```
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public struct Profile : LanguageModelSession.DynamicProfile {

        /// The type of dynamic profile that represent this profile.
        @available(macOS 27.0, iOS 27.0, tvOS 27.0, watchOS 27.0, *)
        public typealias Body = Never
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession {

    /// A dynamic profile that resolves to one of two profiles, depending on a condition.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public struct ConditionalDynamicProfile<TrueContent, FalseContent> : LanguageModelSession.DynamicProfile where TrueContent : LanguageModelSession.DynamicProfile, FalseContent : LanguageModelSession.DynamicProfile {

        /// The type of dynamic profile that represent this profile.
        @available(macOS 27.0, iOS 27.0, tvOS 27.0, watchOS 27.0, *)
        public typealias Body = Never
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession {

    /// A type that represents a dynamic profile builder.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    @resultBuilder public struct DynamicProfileBuilder {
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession {

    /// Creates a session with a profile.
    ///
    /// - Parameters:
    ///   - profile: The profile to use for this session.
    ///   - history: Transcript entries without the initial instructions, since that's defined by the profile.
    public convenience init(profile: sending some LanguageModelSession.DynamicProfile, history: some Collection<Transcript.Entry> = [])
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession {

    /// A protocol for creating reusable wrappers around dynamic profile content.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public protocol DynamicProfileModifier {

        /// The type of dynamic profile modifier that represents this modifier.
        associatedtype Body : LanguageModelSession.DynamicProfile

        /// The content of the dynamic profile modifier.
        @LanguageModelSession.DynamicProfileBuilder func body(content: Self.Content) -> Self.Body

        /// The type of dynamic profile content that this modifier wraps.
        typealias Content = LanguageModelSession.DynamicProfileModifierContent<Self>
    }

    /// A type that represents the dynamic profile a modifier applies to.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public struct DynamicProfileModifierContent<Modifier> : LanguageModelSession.DynamicProfile where Modifier : LanguageModelSession.DynamicProfileModifier {

        /// The type of dynamic profile that represent this profile.
        @available(macOS 27.0, iOS 27.0, tvOS 27.0, watchOS 27.0, *)
        public typealias Body = Never
    }

    /// A dynamic profile with a modifier applied to it.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public struct ModifiedDynamicProfile<Content, Modifier> : LanguageModelSession.DynamicProfile where Content : LanguageModelSession.DynamicProfile, Modifier : LanguageModelSession.DynamicProfileModifier {

        /// The type of dynamic profile that represent this profile.
        @available(macOS 27.0, iOS 27.0, tvOS 27.0, watchOS 27.0, *)
        public typealias Body = Never
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession {

    /// A property wrapper that provides access to properties from within profiles, dynamic
    /// instructions, and tools.
    ///
    /// Use this to access properties across a language model session, like to access
    /// the session history:
    ///
    /// ```swift
    /// // Get a reference to the session history.
    /// @SessionProperty(\.history)
    /// var history
    /// ```
    ///
    /// To create a custom session property, use ``SessionPropertyEntry()`` to define
    /// a custom key that you access with ``LanguageModelSession/SessionProperty``.
    @propertyWrapper public struct SessionProperty<Value> {

        /// The wrapped value of this property wrapper.
        public var wrappedValue: Value { get nonmutating set }

        /// Creates a session property with the specified key path.
        ///
        /// - Parameters:
        ///   - keyPath: The key path to the property.
        public init(_ keyPath: ReferenceWritableKeyPath<SessionPropertyValues, Value>)
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession {

    /// A property wrapper type that stores session state.
    ///
    /// Use `@SessionState` to store mutable state that persists across
    /// a session's lifetime.
    ///
    /// You can use `@SessionState` as a property wrapper:
    /// ```swift
    /// @SessionState var counter: Int = 0
    /// ```
    @propertyWrapper public struct SessionState<Value> {

        /// The underlying value.
        public var wrappedValue: Value { get nonmutating set }

        /// A binding to this state for passing to child components.
        public var projectedValue: LanguageModelSession.SessionBinding<Value> { get }

        /// Creates a session state with a closure providing the initial value.
        @abi(LanguageModelSession.SessionState<Value>.init(initialValue value: @autoclosure @escaping () -> Value))
        public init(wrappedValue value: @autoclosure @escaping () -> Value)
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession {

    /// A property wrapper type that provides a binding to session state from a parent scope.
    ///
    /// Use `@SessionBinding` when a child component needs to access state
    /// that is owned by a parent. The binding must be provided via an initializer.
    ///
    /// Unlike `@SessionState` which owns and initializes its value, `@SessionBinding`
    /// receives its value from an external source (typically via `$parentState`).
    ///
    /// You can use `@SessionBinding` as a property wrapper:
    /// ```swift
    /// @SessionBinding var value: Int
    /// ```
    ///
    /// Or as a type directly:
    /// ```swift
    /// var value: SessionBinding<Int>
    /// ```
    ///
    /// ```swift
    /// // Parent component owns the state
    /// struct BudgetWorkflow: DynamicInstructions {
    ///     @SessionState var budget = 100
    ///
    ///     var body: some DynamicInstructions {
    ///       IncrementBudget(value: $budget)
    ///     }
    /// }
    ///
    /// // Child component receives binding
    /// struct IncrementBudget: Tool {
    ///     @SessionBinding var value: Int
    ///
    ///     init(value: SessionBinding<Int>) {
    ///         self._value = value
    ///     }
    ///
    ///     func call(arguments: Args) -> String {
    ///         value += arguments.amount
    ///         return "Budget is now \(value)"
    ///     }
    /// }
    /// ```
    @propertyWrapper public struct SessionBinding<Value> {

        public var wrappedValue: Value { get nonmutating set }

        public var projectedValue: LanguageModelSession.SessionBinding<Value> { get }
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession {

    /// Creates a session with dynamic instructions.
    ///
    /// - Parameters:
    ///   - dynamicInstructions: The instructions to use for this session.
    ///   - history: Transcript entries without the initial instructions, since that's defined by the profile.
    @available(iOS 27.0, macOS 27.0, tvOS 27.3, *)
    public convenience init(model: some LanguageModel = SystemLanguageModel.default, dynamicInstructions: sending some DynamicInstructions, history: some Collection<Transcript.Entry> = [])

    /// The values of the session's managed properties.
    final public var properties: SessionPropertyValues { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession {

    /// An error that occurs while a language model is calling a tool.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    public struct ToolCallError : Error, LocalizedError {

        /// The tool that produced the error.
        public var tool: any Tool

        /// The underlying error that was thrown during a tool call.
        public var underlyingError: any Error

        /// Creates a tool call error.
        ///
        /// - Parameters:
        ///   - tool: The tool that produced the error.
        ///   - underlyingError: The underlying error that was thrown during a tool call.
        public init(tool: any Tool, underlyingError: any Error)
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession : nonisolated Observable {
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession {

    /// The session's policy for managing the transcript when errors occur.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    final public var transcriptErrorHandlingPolicy: TranscriptErrorHandlingPolicy?

    /// A Boolean value that indicates whether a response is being generated.
    ///
    /// - Important: You should not call any of the respond methods while
    /// this property is `true`.
    ///
    /// Disable buttons and other interactions to prevent users from submitting
    /// a second prompt while the model is responding to their first prompt.
    ///
    /// ```swift
    /// struct ShopView: View {
    ///     @State var session = LanguageModelSession()
    ///     @State var joke = ""
    ///
    ///     var body: some View {
    ///         Text(joke)
    ///         Button("Generate joke") {
    ///             Task {
    ///                 assert(!session.isResponding, "It should not be possible to tap this button while the model is responding")
    ///                 joke = try await session.respond(to: "Tell me a joke").content
    ///             }
    ///         }
    ///         .disabled(session.isResponding) // Prevent concurrent calls to respond
    ///     }
    /// }
    /// ```
    final public var isResponding: Bool { get }

    /// The total accumulated usage across all responses generated by this session.
    ///
    /// This value increases monotonically over the lifetime of the session.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    final public var usage: LanguageModelSession.Usage { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession {

    /// Creates a session with the model, tools, and instructions you provide.
    ///
    /// - Parameters:
    ///   - model: The language model the session uses to generate responses.
    ///   - tools: The tools the model can call while responding.
    ///   - instructions: A builder closure that produces the instructions guiding the
    ///     model's behavior for the session.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public convenience init<Failure>(model: some LanguageModel, tools: [any Tool] = [], @InstructionsBuilder instructions: () throws(Failure) -> Instructions) throws(Failure) where Failure : Error

    /// Creates a session that resumes from an existing transcript.
    ///
    /// - Parameters:
    ///   - model: The language model the session uses to generate responses.
    ///   - tools: The tools the model can call while responding.
    ///   - transcript: The transcript of a conversation to continue.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public convenience init(model: some LanguageModel, tools: [any Tool] = [], transcript: Transcript)

    /// Creates a session with the model, tools, and instructions you provide.
    ///
    /// - Parameters:
    ///   - model: The language model the session uses to generate responses.
    ///   - tools: The tools the model can call while responding.
    ///   - instructions: The instructions that guide the model's behavior for the session.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public convenience init(model: some LanguageModel, tools: [any Tool] = [], instructions: Instructions? = nil)

    /// Creates a session with the model, tools, and instructions you provide.
    ///
    /// - Parameters:
    ///   - model: The language model the session uses to generate responses.
    ///   - tools: The tools the model can call while responding.
    ///   - instructions: The instructions that guide the model's behavior for the session.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public convenience init(model: some LanguageModel, tools: [any Tool] = [], instructions: String? = nil)
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession {

    /// Loads the resources required for this session into memory ahead of a request.
    ///
    /// This method can be useful in cases where you have a strong signal that the user will interact with
    /// session within a few seconds. For example, you might call `prewarm(promptPrefix:)` when
    /// a person begins typing into a text field.
    ///
    /// If you know a prefix for the future prompt, passing it to `prewarm(promptPrefix:)` allows
    /// the system to process the prompt eagerly and reduce latency for the future request.
    ///
    /// - Important: You should only use prewarm when you have a window of at least 1 second before
    /// the call to a respond method, like ``respond(to:options:)-(Prompt,_)`` or
    /// ``streamResponse(to:options:)-(Prompt,_)``.
    ///
    /// Calling this method doesn't guarantee that the system loads your assets immediately, particularly if
    /// your app is running in the background or the system is under load.
    final public func prewarm(promptPrefix: Prompt? = nil)
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession {

    /// A structure that stores the output of a response call.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    public struct Response<Content> where Content : Generable {

        /// The response content.
        public let content: Content

        /// The raw response content.
        ///
        /// When `Content` is `GeneratedContent`, this is the same as `content`.
        public let rawContent: GeneratedContent

        /// The list of transcript entries.
        public let transcriptEntries: ArraySlice<Transcript.Entry>

        /// Information about how many tokens were used by this response.
        @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
        public let usage: LanguageModelSession.Usage
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession {

    /// Information about how many tokens were used by a response.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public struct Usage : Sendable {

        /// The input token counts from the transcript.
        public var input: LanguageModelSession.Usage.Input

        /// The output token counts from the response.
        public var output: LanguageModelSession.Usage.Output

        /// Additional usage statistics that the language model encodes for the response.
        public var metadata: [String : GeneratedContent]

        /// Creates a usage value with the given token counts.
        ///
        /// - Parameters:
        ///   - input: Token counts for the transcript.
        ///   - output: Token counts for the response.
        ///   - metadata: Additional usage statistics from the language model.
        public init(input: LanguageModelSession.Usage.Input, output: LanguageModelSession.Usage.Output, metadata: [String : any ConvertibleToGeneratedContent] = [:])
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession : @unchecked Sendable {
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession {

    /// A failure caused by incorrect use of a language model session.
    ///
    /// - Note: If your app deploys to iOS 26, macOS 26, or visionOS 26, where this error is
    ///   unavailable, use an availability check and fall back to
    ///   ``LanguageModelSession/GenerationError``:
    ///
    ///   ```swift
    ///   do {
    ///       let response = try await session.respond(to: prompt)
    ///   } catch {
    ///       if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *),
    ///           let error = error as? LanguageModelSession.Error
    ///       {
    ///           // Handle the error.
    ///       } else if case .concurrentRequests = error as? LanguageModelSession.GenerationError {
    ///           // Handle the deprecated error.
    ///       }
    ///   }
    ///   ```
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public enum Error : LocalizedError {

        /// The session received multiple concurrent requests.
        ///
        /// A language model session only supports one request at a time.
        /// Wait for the current request to complete before starting another.
        case concurrentRequests

        /// A request mutated the session's transcript while it was in progress.
        ///
        /// Do not modify the transcript while a request is being processed.
        case transcriptMutationWhileResponding

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: LanguageModelSession.Error, b: LanguageModelSession.Error) -> Bool

        /// Hashes the essential components of this value by feeding them into the
        /// given hasher.
        ///
        /// Implement this method to conform to the `Hashable` protocol. The
        /// components used for hashing must be the same as the components compared
        /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
        /// with each of these components.
        ///
        /// - Important: In your implementation of `hash(into:)`,
        ///   don't call `finalize()` on the `hasher` instance provided,
        ///   or replace it with a different instance.
        ///   Doing so may become a compile-time error in the future.
        ///
        /// - Parameter hasher: The hasher to use when combining the components
        ///   of this instance.
        public func hash(into hasher: inout Hasher)

        /// The hash value.
        ///
        /// Hash values are not guaranteed to be equal across different executions of
        /// your program. Do not save hash values to use during a future execution.
        ///
        /// - Important: `hashValue` is deprecated as a `Hashable` requirement. To
        ///   conform to `Hashable`, implement the `hash(into:)` requirement instead.
        ///   The compiler provides an implementation for `hashValue` for you.
        public var hashValue: Int { get }
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession {

    /// Produces a response stream to a prompt.
    ///
    /// - Important: If running in the background, use the non-streaming
    /// ``LanguageModelSession/respond(to:options:)-(Prompt,_)`` method to
    /// reduce the likelihood of encountering ``LanguageModelError/rateLimited(_:)`` errors.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: A response stream that produces aggregated tokens.
    final public func streamResponse(to prompt: Prompt, options: GenerationOptions = GenerationOptions()) -> sending LanguageModelSession.ResponseStream<String>

    /// Produces a response stream to a prompt.
    ///
    /// - Important: If running in the background, use the non-streaming
    /// ``LanguageModelSession/respond(to:options:)-(Prompt,_)`` method to
    /// reduce the likelihood of encountering ``LanguageModelError/rateLimited(_:)`` errors.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: A response stream that produces aggregated tokens.
    final public func streamResponse(to prompt: String, options: GenerationOptions = GenerationOptions()) -> sending LanguageModelSession.ResponseStream<String>

    /// Produces a response stream to a prompt.
    ///
    /// - Important: If running in the background, use the non-streaming
    /// ``LanguageModelSession/respond(to:options:)-(Prompt,_)`` method to
    /// reduce the likelihood of encountering ``LanguageModelError/rateLimited(_:)`` errors.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: A response stream that produces aggregated tokens.
    final public func streamResponse(options: GenerationOptions = GenerationOptions(), @PromptBuilder prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<String>

    /// Produces a response stream to a prompt and schema.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Important: If running in the background, use the non-streaming
    /// ``LanguageModelSession/respond(to:options:)-(Prompt,_)`` method to
    /// reduce the likelihood of encountering ``LanguageModelError/rateLimited(_:)`` errors.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - schema: A schema to guide the output with.
    ///   - includeSchemaInPrompt: If `true`, injects the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: A response stream that produces ``GeneratedContent`` containing the fields and values defined in the schema.
    final public func streamResponse(to prompt: Prompt, schema: GenerationSchema, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions()) -> sending LanguageModelSession.ResponseStream<GeneratedContent>

    /// Produces a response stream to a prompt and schema.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Important: If running in the background, use the non-streaming
    /// ``LanguageModelSession/respond(to:options:)-(Prompt,_)`` method to
    /// reduce the likelihood of encountering ``LanguageModelError/rateLimited(_:)`` errors.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - schema: A schema to guide the output with.
    ///   - includeSchemaInPrompt: If `true`, injects the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: A response stream that produces ``GeneratedContent`` containing the fields and values defined in the schema.
    final public func streamResponse(to prompt: String, schema: GenerationSchema, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions()) -> sending LanguageModelSession.ResponseStream<GeneratedContent>

    /// Produces a response stream to a prompt and schema.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Important: If running in the background, use the non-streaming
    /// ``LanguageModelSession/respond(to:options:)-(Prompt,_)`` method to
    /// reduce the likelihood of encountering ``LanguageModelError/rateLimited(_:)`` errors.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - schema: A schema to guide the output with.
    ///   - includeSchemaInPrompt: If `true`, injects the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: A response stream that produces ``GeneratedContent`` containing the fields and values defined in the schema.
    final public func streamResponse(schema: GenerationSchema, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions(), @PromptBuilder prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<GeneratedContent>

    /// Produces a response stream to a prompt.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Important: If running in the background, use the non-streaming
    /// ``LanguageModelSession/respond(to:options:)-(Prompt,_)`` method to
    /// reduce the likelihood of encountering ``LanguageModelError/rateLimited(_:)`` errors.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - type: A type to produce as the response.
    ///   - includeSchemaInPrompt: If `true`, injects the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: A response stream that produces an instance of the `Generable` type.
    final public func streamResponse<Content>(to prompt: Prompt, generating type: Content.Type = Content.self, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions()) -> sending LanguageModelSession.ResponseStream<Content> where Content : Generable

    /// Produces a response stream to a prompt.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Important: If running in the background, use the non-streaming
    /// ``LanguageModelSession/respond(to:options:)-(Prompt,_)`` method to
    /// reduce the likelihood of encountering ``LanguageModelError/rateLimited(_:)`` errors.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - type: A type to produce as the response.
    ///   - includeSchemaInPrompt: If `true`, injects the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: A response stream that produces an instance of the `Generable` type.
    final public func streamResponse<Content>(to prompt: String, generating type: Content.Type = Content.self, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions()) -> sending LanguageModelSession.ResponseStream<Content> where Content : Generable

    /// Produces a response stream to a prompt.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Important: If running in the background, use the non-streaming
    /// ``LanguageModelSession/respond(to:options:)-(Prompt,_)`` method to
    /// reduce the likelihood of encountering ``LanguageModelError/rateLimited(_:)`` errors.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - type: A type to produce as the response.
    ///   - includeSchemaInPrompt: If `true`, injects the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: A response stream that produces an instance of the `Generable` type.
    final public func streamResponse<Content>(generating type: Content.Type = Content.self, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions(), @PromptBuilder prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<Content> where Content : Generable

    /// Produces a response stream to a prompt.
    ///
    /// - Important: If running in the background, use the non-streaming
    /// ``LanguageModelSession/respond(to:options:)-(Prompt,_)`` method to
    /// reduce the likelihood of encountering ``LanguageModelError/rateLimited(_:)`` errors.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - contextOptions: Settings that configure how the model is prompted.
    ///   - metadata: Metadata to attach to the request.
    /// - Returns: A response stream that produces aggregated tokens.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    final public func streamResponse(to prompt: Prompt, options: GenerationOptions = GenerationOptions(), contextOptions: ContextOptions = ContextOptions(), metadata: [String : any ConvertibleToGeneratedContent] = [:]) -> sending LanguageModelSession.ResponseStream<String>

    /// Produces a response stream to a prompt.
    ///
    /// - Important: If running in the background, use the non-streaming
    /// ``LanguageModelSession/respond(to:options:)-(Prompt,_)`` method to
    /// reduce the likelihood of encountering ``LanguageModelError/rateLimited(_:)`` errors.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - contextOptions: Settings that configure how the model is prompted.
    ///   - metadata: Metadata to attach to the request.
    /// - Returns: A response stream that produces aggregated tokens.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    final public func streamResponse(to prompt: String, options: GenerationOptions = GenerationOptions(), contextOptions: ContextOptions = ContextOptions(), metadata: [String : any ConvertibleToGeneratedContent] = [:]) -> sending LanguageModelSession.ResponseStream<String>

    /// Produces a response stream to a prompt.
    ///
    /// - Important: If running in the background, use the non-streaming
    /// ``LanguageModelSession/respond(to:options:)-(Prompt,_)`` method to
    /// reduce the likelihood of encountering ``LanguageModelError/rateLimited(_:)`` errors.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - contextOptions: Settings that configure how the model is prompted.
    ///   - metadata: Metadata to attach to the request.
    /// - Returns: A response stream that produces aggregated tokens.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    final public func streamResponse(options: GenerationOptions = GenerationOptions(), contextOptions: ContextOptions = ContextOptions(), metadata: [String : any ConvertibleToGeneratedContent] = [:], @PromptBuilder prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<String>

    /// Produces a response stream to a prompt and schema.
    ///
    /// Consider using the default value of `true` for ``ContextOptions/includeSchemaInPrompt``.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Important: If running in the background, use the non-streaming
    /// ``LanguageModelSession/respond(to:options:)-(Prompt,_)`` method to
    /// reduce the likelihood of encountering ``LanguageModelError/rateLimited(_:)`` errors.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - schema: A schema to guide the output with.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - contextOptions: Settings that configure how the model is prompted.
    ///   - metadata: Metadata to attach to the request.
    /// - Returns: A response stream that produces ``GeneratedContent`` containing the fields and values defined in the schema.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    final public func streamResponse(to prompt: Prompt, schema: GenerationSchema, options: GenerationOptions = GenerationOptions(), contextOptions: ContextOptions = ContextOptions(includeSchemaInPrompt: true), metadata: [String : any ConvertibleToGeneratedContent] = [:]) -> sending LanguageModelSession.ResponseStream<GeneratedContent>

    /// Produces a response stream to a prompt and schema.
    ///
    /// Consider using the default value of `true` for ``ContextOptions/includeSchemaInPrompt``.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Important: If running in the background, use the non-streaming
    /// ``LanguageModelSession/respond(to:options:)-(Prompt,_)`` method to
    /// reduce the likelihood of encountering ``LanguageModelError/rateLimited(_:)`` errors.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - schema: A schema to guide the output with.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - contextOptions: Settings that configure how the model is prompted.
    ///   - metadata: Metadata to attach to the request.
    /// - Returns: A response stream that produces ``GeneratedContent`` containing the fields and values defined in the schema.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    final public func streamResponse(to prompt: String, schema: GenerationSchema, options: GenerationOptions = GenerationOptions(), contextOptions: ContextOptions = ContextOptions(includeSchemaInPrompt: true), metadata: [String : any ConvertibleToGeneratedContent] = [:]) -> sending LanguageModelSession.ResponseStream<GeneratedContent>

    /// Produces a response stream to a prompt and schema.
    ///
    /// Consider using the default value of `true` for ``ContextOptions/includeSchemaInPrompt``.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Important: If running in the background, use the non-streaming
    /// ``LanguageModelSession/respond(to:options:)-(Prompt,_)`` method to
    /// reduce the likelihood of encountering ``LanguageModelError/rateLimited(_:)`` errors.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - schema: A schema to guide the output with.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - contextOptions: Settings that configure how the model is prompted.
    ///   - metadata: Metadata to attach to the request.
    /// - Returns: A response stream that produces ``GeneratedContent`` containing the fields and values defined in the schema.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    final public func streamResponse(schema: GenerationSchema, options: GenerationOptions = GenerationOptions(), contextOptions: ContextOptions = ContextOptions(includeSchemaInPrompt: true), metadata: [String : any ConvertibleToGeneratedContent] = [:], @PromptBuilder prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<GeneratedContent>

    /// Produces a response stream to a prompt.
    ///
    /// Consider using the default value of `true` for ``ContextOptions/includeSchemaInPrompt``.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Important: If running in the background, use the non-streaming
    /// ``LanguageModelSession/respond(to:options:)-(Prompt,_)`` method to
    /// reduce the likelihood of encountering ``LanguageModelError/rateLimited(_:)`` errors.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - type: A type to produce as the response.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - contextOptions: Settings that configure how the model is prompted.
    ///   - metadata: Metadata to attach to the request.
    /// - Returns: A response stream that produces an instance of the `Generable` type.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    final public func streamResponse<Content>(to prompt: Prompt, generating type: Content.Type = Content.self, options: GenerationOptions = GenerationOptions(), contextOptions: ContextOptions = ContextOptions(includeSchemaInPrompt: true), metadata: [String : any ConvertibleToGeneratedContent] = [:]) -> sending LanguageModelSession.ResponseStream<Content> where Content : Generable

    /// Produces a response stream to a prompt.
    ///
    /// Consider using the default value of `true` for ``ContextOptions/includeSchemaInPrompt``.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Important: If running in the background, use the non-streaming
    /// ``LanguageModelSession/respond(to:options:)-(Prompt,_)`` method to
    /// reduce the likelihood of encountering ``LanguageModelError/rateLimited(_:)`` errors.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - type: A type to produce as the response.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - contextOptions: Settings that configure how the model is prompted.
    ///   - metadata: Metadata to attach to the request.
    /// - Returns: A response stream that produces an instance of the `Generable` type.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    final public func streamResponse<Content>(to prompt: String, generating type: Content.Type = Content.self, options: GenerationOptions = GenerationOptions(), contextOptions: ContextOptions = ContextOptions(includeSchemaInPrompt: true), metadata: [String : any ConvertibleToGeneratedContent] = [:]) -> sending LanguageModelSession.ResponseStream<Content> where Content : Generable

    /// Produces a response stream to a prompt.
    ///
    /// Consider using the default value of `true` for ``ContextOptions/includeSchemaInPrompt``.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Important: If running in the background, use the non-streaming
    /// ``LanguageModelSession/respond(to:options:)-(Prompt,_)`` method to
    /// reduce the likelihood of encountering ``LanguageModelError/rateLimited(_:)`` errors.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - type: A type to produce as the response.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - contextOptions: Settings that configure how the model is prompted.
    ///   - metadata: Metadata to attach to the request.
    /// - Returns: A response stream that produces an instance of the `Generable` type.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    final public func streamResponse<Content>(generating type: Content.Type = Content.self, options: GenerationOptions = GenerationOptions(), contextOptions: ContextOptions = ContextOptions(includeSchemaInPrompt: true), metadata: [String : any ConvertibleToGeneratedContent] = [:], @PromptBuilder prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<Content> where Content : Generable

    /// Produces a response to a prompt.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: A string composed of the tokens produced by sampling model output.
    @discardableResult
    nonisolated(nonsending) final public func respond(to prompt: Prompt, options: GenerationOptions = GenerationOptions()) async throws -> LanguageModelSession.Response<String>

    /// Produces a response to a prompt.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: A string composed of the tokens produced by sampling model output.
    @discardableResult
    nonisolated(nonsending) final public func respond(to prompt: String, options: GenerationOptions = GenerationOptions()) async throws -> LanguageModelSession.Response<String>

    /// Produces a response to a prompt.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: A string composed of the tokens produced by sampling model output.
    @discardableResult
    nonisolated(nonsending) final public func respond(options: GenerationOptions = GenerationOptions(), @PromptBuilder prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<String>

    /// Produces a generated content type as a response to a prompt and schema.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - schema: A schema to guide the output with.
    ///   - includeSchemaInPrompt: If `true`, injects the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: ``GeneratedContent`` containing the fields and values defined in the schema.
    @discardableResult
    nonisolated(nonsending) final public func respond(to prompt: Prompt, schema: GenerationSchema, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions()) async throws -> LanguageModelSession.Response<GeneratedContent>

    /// Produces a generated content type as a response to a prompt and schema.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - schema: A schema to guide the output with.
    ///   - includeSchemaInPrompt: If `true`, injects the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: ``GeneratedContent`` containing the fields and values defined in the schema.
    @discardableResult
    nonisolated(nonsending) final public func respond(to prompt: String, schema: GenerationSchema, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions()) async throws -> LanguageModelSession.Response<GeneratedContent>

    /// Produces a generated content type as a response to a prompt and schema.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - schema: A schema to guide the output with.
    ///   - includeSchemaInPrompt: If `true`, injects the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: ``GeneratedContent`` containing the fields and values defined in the schema.
    @discardableResult
    nonisolated(nonsending) final public func respond(schema: GenerationSchema, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions(), @PromptBuilder prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<GeneratedContent>

    /// Produces a generable object as a response to a prompt.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - type: A type to produce as the response.
    ///   - includeSchemaInPrompt: If `true`, injects the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: An instance of the `Generable` type.
    @discardableResult
    nonisolated(nonsending) final public func respond<Content>(to prompt: Prompt, generating type: Content.Type = Content.self, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions()) async throws -> LanguageModelSession.Response<Content> where Content : Generable

    /// Produces a generable object as a response to a prompt.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - type: A type to produce as the response.
    ///   - includeSchemaInPrompt: If `true`, injects the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: An instance of the `Generable` type.
    @discardableResult
    nonisolated(nonsending) final public func respond<Content>(to prompt: String, generating type: Content.Type = Content.self, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions()) async throws -> LanguageModelSession.Response<Content> where Content : Generable

    /// Produces a generable object as a response to a prompt.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - type: A type to produce as the response.
    ///   - includeSchemaInPrompt: If `true`, injects the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: An instance of the `Generable` type.
    @discardableResult
    nonisolated(nonsending) final public func respond<Content>(generating type: Content.Type = Content.self, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions(), @PromptBuilder prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<Content> where Content : Generable

    /// Produces a response to a prompt.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - contextOptions: Settings that configure how the model is prompted.
    ///   - metadata: Metadata to attach to the request.
    /// - Returns: A string composed of the tokens produced by sampling model output.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    @discardableResult
    nonisolated(nonsending) final public func respond(to prompt: Prompt, options: GenerationOptions = GenerationOptions(), contextOptions: ContextOptions = ContextOptions(), metadata: [String : any ConvertibleToGeneratedContent] = [:]) async throws -> LanguageModelSession.Response<String>

    /// Produces a response to a prompt.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - contextOptions: Settings that configure how the model is prompted.
    ///   - metadata: Metadata to attach to the request.
    /// - Returns: A string composed of the tokens produced by sampling model output.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    @discardableResult
    nonisolated(nonsending) final public func respond(to prompt: String, options: GenerationOptions = GenerationOptions(), contextOptions: ContextOptions = ContextOptions(), metadata: [String : any ConvertibleToGeneratedContent] = [:]) async throws -> LanguageModelSession.Response<String>

    /// Produces a response to a prompt.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - contextOptions: Settings that configure how the model is prompted.
    ///   - metadata: Metadata to attach to the request.
    /// - Returns: A string composed of the tokens produced by sampling model output.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    @discardableResult
    nonisolated(nonsending) final public func respond(options: GenerationOptions = GenerationOptions(), contextOptions: ContextOptions = ContextOptions(), metadata: [String : any ConvertibleToGeneratedContent] = [:], @PromptBuilder prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<String>

    /// Produces a generated content type as a response to a prompt and schema.
    ///
    /// Consider using the default value of `true` for ``ContextOptions/includeSchemaInPrompt``.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - schema: A schema to guide the output with.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - contextOptions: Settings that configure how the model is prompted.
    ///   - metadata: Metadata to attach to the request.
    /// - Returns: ``GeneratedContent`` containing the fields and values defined in the schema.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    @discardableResult
    nonisolated(nonsending) final public func respond(to prompt: Prompt, schema: GenerationSchema, options: GenerationOptions = GenerationOptions(), contextOptions: ContextOptions = ContextOptions(includeSchemaInPrompt: true), metadata: [String : any ConvertibleToGeneratedContent] = [:]) async throws -> LanguageModelSession.Response<GeneratedContent>

    /// Produces a generated content type as a response to a prompt and schema.
    ///
    /// Consider using the default value of `true` for ``ContextOptions/includeSchemaInPrompt``.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - schema: A schema to guide the output with.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - contextOptions: Settings that configure how the model is prompted.
    ///   - metadata: Metadata to attach to the request.
    /// - Returns: ``GeneratedContent`` containing the fields and values defined in the schema.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    @discardableResult
    nonisolated(nonsending) final public func respond(to prompt: String, schema: GenerationSchema, options: GenerationOptions = GenerationOptions(), contextOptions: ContextOptions = ContextOptions(includeSchemaInPrompt: true), metadata: [String : any ConvertibleToGeneratedContent] = [:]) async throws -> LanguageModelSession.Response<GeneratedContent>

    /// Produces a generated content type as a response to a prompt and schema.
    ///
    /// Consider using the default value of `true` for ``ContextOptions/includeSchemaInPrompt``.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - schema: A schema to guide the output with.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - contextOptions: Settings that configure how the model is prompted.
    ///   - metadata: Metadata to attach to the request.
    /// - Returns: ``GeneratedContent`` containing the fields and values defined in the schema.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    @discardableResult
    nonisolated(nonsending) final public func respond(schema: GenerationSchema, options: GenerationOptions = GenerationOptions(), contextOptions: ContextOptions = ContextOptions(includeSchemaInPrompt: true), metadata: [String : any ConvertibleToGeneratedContent] = [:], @PromptBuilder prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<GeneratedContent>

    /// Produces a generable object as a response to a prompt.
    ///
    /// Consider using the default value of `true` for ``ContextOptions/includeSchemaInPrompt``.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - type: A type to produce as the response.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - contextOptions: Settings that configure how the model is prompted.
    ///   - metadata: Metadata to attach to the request.
    /// - Returns: An instance of the `Generable` type.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    @discardableResult
    nonisolated(nonsending) final public func respond<Content>(to prompt: Prompt, generating type: Content.Type = Content.self, options: GenerationOptions = GenerationOptions(), contextOptions: ContextOptions = ContextOptions(includeSchemaInPrompt: true), metadata: [String : any ConvertibleToGeneratedContent] = [:]) async throws -> LanguageModelSession.Response<Content> where Content : Generable

    /// Produces a generable object as a response to a prompt.
    ///
    /// Consider using the default value of `true` for ``ContextOptions/includeSchemaInPrompt``.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - type: A type to produce as the response.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - contextOptions: Settings that configure how the model is prompted.
    ///   - metadata: Metadata to attach to the request.
    /// - Returns: An instance of the `Generable` type.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    @discardableResult
    nonisolated(nonsending) final public func respond<Content>(to prompt: String, generating type: Content.Type = Content.self, options: GenerationOptions = GenerationOptions(), contextOptions: ContextOptions = ContextOptions(includeSchemaInPrompt: true), metadata: [String : any ConvertibleToGeneratedContent] = [:]) async throws -> LanguageModelSession.Response<Content> where Content : Generable

    /// Produces a generable object as a response to a prompt.
    ///
    /// Consider using the default value of `true` for ``ContextOptions/includeSchemaInPrompt``.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - type: A type to produce as the response.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - contextOptions: Settings that configure how the model is prompted.
    ///   - metadata: Metadata to attach to the request.
    /// - Returns: An instance of the `Generable` type.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    @discardableResult
    nonisolated(nonsending) final public func respond<Content>(generating type: Content.Type = Content.self, options: GenerationOptions = GenerationOptions(), contextOptions: ContextOptions = ContextOptions(includeSchemaInPrompt: true), metadata: [String : any ConvertibleToGeneratedContent] = [:], @PromptBuilder prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<Content> where Content : Generable
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession {

    /// An async sequence of snapshots of partially generated content.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    public struct ResponseStream<Content> where Content : Generable {
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession {

    /// Logs and serializes a feedback attachment that can be submitted to Apple.
    ///
    /// This method creates a structured feedback attachment containing the session's transcript
    /// and any provided feedback information. The attachment can be saved to a file and submitted
    /// to Apple using [Feedback Assistant](https://feedbackassistant.apple.com).
    ///
    /// If an error occurred during a previous response, any rejected entries that were rolled
    /// back from the transcript are included in the feedback data.
    ///
    /// ```swift
    /// let session = LanguageModelSession()
    /// let response = try await session.respond(to: "What is the capital of France?")
    ///
    /// // Create feedback for a helpful response
    /// let feedbackData = session.logFeedbackAttachment(sentiment: .positive)
    ///
    /// // Or create feedback for a problematic response
    /// let feedbackData = session.logFeedbackAttachment(
    ///     sentiment: .negative,
    ///     issues: [
    ///         LanguageModelFeedback.Issue(
    ///             category: .incorrect,
    ///             explanation: "The model provided outdated information"
    ///         )
    ///     ],
    ///     desiredOutput: Transcript.Entry.response(...)
    /// )
    /// ```
    ///
    /// If your `desiredOutput` is a string, use ``Transcript/Entry/response(_:)`` to turn your desired output into a
    /// ``Transcript`` entry:
    ///
    /// ```swift
    /// let text = Transcript.TextSegment(content: "The capital of France is Paris.")
    /// let segment = Transcript.Segment.text(text)
    /// let response = Transcript.Response(segments: [segment])
    /// let entry = Transcript.Entry.response(response)
    /// ```
    ///
    /// If your `desiredOutput` is a ``Generable`` type, turning that into a ``Transcript`` entry is slightly different:
    ///
    /// ```swift
    /// let customType = MyCustomType(...) // A generable type.
    /// let structure = Transcript.StructuredSegment(schemaName: String(describing: MyCustomType.self), content: customType.generatedContent)
    /// let segment = Transcript.Segment.structure(structure)
    /// let response = Transcript.Response(segments: [segment])
    /// let entry = Transcript.Entry.response(response)
    /// ```
    ///
    /// Finally, if you'd like to submit the feedback to Apple, write your feedback to a `.json` file and include the file as an
    /// attachment to [Feedback Assistant](https://feedbackassistant.apple.com). You can include one or many
    /// feedback attachments in the same file:
    ///
    /// ```swift
    /// let allFeedback = feedbackData + feedbackData2 + feedbackData3
    /// let url = URL(fileURLWithPath: "path/to/save/feedback.json")
    /// try allFeedback.write(to: url)
    /// ```
    ///
    /// - Parameters:
    ///   - sentiment: An optional sentiment rating about the model's output (positive, negative, or neutral).
    ///   - issues: An array of specific issues identified with the model's response. Defaults to an empty array.
    ///   - desiredOutput: An optional transcript entry showing what the desired output should have been.
    /// - Returns: A `Data` object containing the JSON-encoded feedback attachment that can be submitted to Feedback Assistant.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    @discardableResult
    final public func logFeedbackAttachment(sentiment: LanguageModelFeedback.Sentiment?, issues: [LanguageModelFeedback.Issue] = [], desiredOutput: Transcript.Entry? = nil) -> Data

    /// Logs and serializes a feedback attachment that includes the response text you expected.
    ///
    /// - Parameters:
    ///   - sentiment: An optional sentiment rating about the model's output.
    ///   - issues: An array of specific issues identified with the model's response. Defaults to
    ///     an empty array.
    ///   - desiredResponseText: The text the model should have produced, if you have one.
    /// - Returns: A `Data` object containing the JSON-encoded feedback attachment that can be
    ///   submitted to Feedback Assistant.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    @backDeployed(before: iOS 26.1, macOS 26.1, visionOS 26.1)
    @discardableResult
    final public func logFeedbackAttachment(sentiment: LanguageModelFeedback.Sentiment?, issues: [LanguageModelFeedback.Issue] = [], desiredResponseText: String?) -> Data

    /// Logs and serializes a feedback attachment that includes the content you expected.
    ///
    /// - Parameters:
    ///   - sentiment: An optional sentiment rating about the model's output.
    ///   - issues: An array of specific issues identified with the model's response. Defaults to
    ///     an empty array.
    ///   - desiredResponseContent: The content the model should’ve produced.
    /// - Returns: A `Data` object containing the JSON-encoded feedback attachment that can be
    ///   submitted to Feedback Assistant.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    @backDeployed(before: iOS 26.1, macOS 26.1, visionOS 26.1)
    @discardableResult
    final public func logFeedbackAttachment(sentiment: LanguageModelFeedback.Sentiment?, issues: [LanguageModelFeedback.Issue] = [], desiredResponseContent: (any ConvertibleToGeneratedContent)?) -> Data
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension LanguageModelSession.GenerationError {

    /// A refusal produced by a language model.
    ///
    /// Refusal errors indicate that the model chose not to respond to a prompt. To make the model
    /// explain why it refused, catch the refusal error and access one of its explanation properties.
    ///
    /// ```swift
    /// do {
    ///     let session = LanguageModelSession()
    ///     let response = try session.respond(to: "...")
    /// } catch error as LanguageModelSession.GenerationError.refusal(let refusal, _) {
    ///     let message = try await refusal.explanation
    ///     print(message)
    /// } catch {
    ///     print("Something went wrong: \(error)")
    /// }
    /// ```
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct Refusal : Sendable {
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension LanguageModelSession.GenerationError {

    /// The context in which the error occurred.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct Context : Sendable {

        /// A debug description to help developers diagnose issues during development.
        ///
        /// This string is not localized and is not appropriate for display to end users.
        public let debugDescription: String
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension LanguageModelSession.GenerationError {

    /// A string representation of the error description.
    public var errorDescription: String? { get }

    /// A string representation of the recovery suggestion.
    public var recoverySuggestion: String? { get }

    /// A string representation of the failure reason.
    public var failureReason: String? { get }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.AnyDynamicProfile {

    /// The content of the dynamic profile.
    public var body: Never { get }

    /// Creates an instance from the dynamic profile you specify.
    ///
    /// - Parameters:
    ///   - dynamicProfile: The dynamic profile.
    @export(implementation) public init(erasing dynamicProfile: some LanguageModelSession.DynamicProfile)
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.DynamicProfile {

    /// The profile type that a dynamic profile activates.
    public typealias Profile = LanguageModelSession.Profile

    /// The dynamic profile type that a dynamic profile's body composes.
    public typealias DynamicProfile = LanguageModelSession.DynamicProfile
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.DynamicProfile {

    /// Applies a modifier to the dynamic profile.
    public func modifier<Modifier>(_ modifier: Modifier) -> some LanguageModelSession.DynamicProfile where Modifier : LanguageModelSession.DynamicProfileModifier

}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.DynamicProfile {

    /// Sets the model.
    public func model(_ model: any LanguageModel) -> some LanguageModelSession.DynamicProfile


    /// Sets the model.
    public func model(_ model: some LanguageModel) -> some LanguageModelSession.DynamicProfile


    /// Sets the model temperature.
    public func temperature(_ temperature: Double?) -> some LanguageModelSession.DynamicProfile


    /// Sets the samping mode.
    public func samplingMode(_ samplingMode: GenerationOptions.SamplingMode?) -> some LanguageModelSession.DynamicProfile


    /// Sets the maximum response tokens.
    public func maximumResponseTokens(_ maximumResponseTokens: Int?) -> some LanguageModelSession.DynamicProfile


    /// Sets the reasoning level.
    public func reasoningLevel(_ reasoningLevel: ContextOptions.ReasoningLevel?) -> some LanguageModelSession.DynamicProfile


    /// Sets the tool-calling mode.
    public func toolCallingMode(_ toolCallingMode: GenerationOptions.ToolCallingMode?) -> some LanguageModelSession.DynamicProfile


    /// Applies a transformation to the history prior to invoking the model.
    public func historyTransform(_ transform: @escaping ([Transcript.Entry]) -> [Transcript.Entry]) -> some LanguageModelSession.DynamicProfile


    /// Sets the policy for managing the transcript when errors occur.
    public func transcriptErrorHandlingPolicy(_ transcriptErrorHandlingPolicy: TranscriptErrorHandlingPolicy?) -> some LanguageModelSession.DynamicProfile


    /// Runs an action before the model is invoked for this dynamic profile.
    ///
    /// When the `onPrompt` closure throws an error, the caller's `respond` or
    /// `response` propagates that error.
    ///
    /// Use this to observe or log prompts before generation begins:
    ///
    /// ```swift
    /// struct MyDynamicProfile: LanguageModelSession.DynamicProfile {
    ///   var body: some LanguageModelSession.DynamicProfile {
    ///     Profile {
    ///       Instructions("You are a helpful assistant.")
    ///     }
    ///     .onPrompt {
    ///       promptCount += 1
    ///     }
    ///   }
    /// }
    /// ```
    @export(implementation) public func onPrompt(perform action: nonisolated(nonsending) sending @escaping () async throws -> Void) -> some LanguageModelSession.DynamicProfile


    /// Runs an action before the model is invoked for this dynamic profile.
    ///
    /// When the `onPrompt` closure throws an error, the caller's `respond` or
    /// `response` propagates that error.
    ///
    /// Use this to observe or log prompts before generation begins:
    ///
    /// ```swift
    /// struct MyDynamicProfile: LanguageModelSession.DynamicProfile {
    ///   var body: some LanguageModelSession.DynamicProfile {
    ///     Profile {
    ///       Instructions("You are a helpful assistant.")
    ///     }
    ///     .onPrompt { prompt in
    ///       print("prompt: \(prompt)")
    ///       promptCount += 1
    ///     }
    ///   }
    /// }
    /// ```
    public func onPrompt(perform action: nonisolated(nonsending) sending @escaping (Transcript.Prompt) async throws -> Void) -> some LanguageModelSession.DynamicProfile


    /// Runs an action after this dynamic profile produces a response.
    ///
    /// When the `onResponse` closure throws an error, the caller's `respond` or
    /// `response` propagates that error.
    ///
    /// Use this to perform cleanup or state updates when a dynamic profile completes:
    ///
    /// ```swift
    /// struct MyDynamicProfile: LanguageModelSession.DynamicProfile {
    ///   var body: some LanguageModelSession.DynamicProfile {
    ///     Profile {
    ///       Instructions("You are a helpful assistant.")
    ///     }
    ///     .onResponse {
    ///       completedTasks += 1
    ///     }
    ///   }
    /// }
    /// ```
    @export(implementation) public func onResponse(perform action: nonisolated(nonsending) sending @escaping () async throws -> Void) -> some LanguageModelSession.DynamicProfile


    /// Runs an action after this dynamic profile produces a response.
    ///
    /// When the `onResponse` closure throws an error, the caller's `respond` or
    /// `response` propagates that error.
    ///
    /// Use this to perform cleanup or state updates when a dynamic profile completes:
    ///
    /// ```swift
    /// struct MyDynamicProfile: LanguageModelSession.DynamicProfile {
    ///   var body: some LanguageModelSession.DynamicProfile {
    ///     Profile {
    ///       Instructions("You are a helpful assistant.")
    ///     }
    ///     .onResponse { response in
    ///       print("response: \(response)")
    ///       completedTasks += 1
    ///     }
    ///   }
    /// }
    /// ```
    public func onResponse(perform action: nonisolated(nonsending) sending @escaping (Transcript.Response) async throws -> Void) -> some LanguageModelSession.DynamicProfile


    /// Runs an action whenever this dynamic profile produces reasoning.
    ///
    /// Reasoning is only produced by models that declare the `.reasoning` capability.
    ///
    /// When the `onReasoning` closure throws an error, the caller's `respond` or
    /// `response` propagates that error.
    ///
    /// Use this to observe or log the model's reasoning as it works toward a response:
    ///
    /// ```swift
    /// struct MyDynamicProfile: LanguageModelSession.DynamicProfile {
    ///   var body: some LanguageModelSession.DynamicProfile {
    ///     Profile {
    ///       Instructions("You are a helpful assistant.")
    ///     }
    ///     .onReasoning {
    ///       reasoningCount += 1
    ///     }
    ///   }
    /// }
    /// ```
    @export(implementation) public func onReasoning(perform action: nonisolated(nonsending) sending @escaping () async throws -> Void) -> some LanguageModelSession.DynamicProfile


    /// Runs an action whenever this dynamic profile produces reasoning.
    ///
    /// Reasoning is only produced by models that declare the `.reasoning` capability.
    ///
    /// When the `onReasoning` closure throws an error, the caller's `respond` or
    /// `response` propagates that error.
    ///
    /// Use this to observe or log the model's reasoning as it works toward a response:
    ///
    /// ```swift
    /// struct MyDynamicProfile: LanguageModelSession.DynamicProfile {
    ///   var body: some LanguageModelSession.DynamicProfile {
    ///     Profile {
    ///       Instructions("You are a helpful assistant.")
    ///     }
    ///     .onReasoning { reasoning in
    ///       print("reasoning: \(reasoning)")
    ///       reasoningCount += 1
    ///     }
    ///   }
    /// }
    /// ```
    public func onReasoning(perform action: nonisolated(nonsending) sending @escaping (Transcript.Reasoning) async throws -> Void) -> some LanguageModelSession.DynamicProfile


    /// Runs an action whenever this dynamic profile produces a data entry.
    ///
    /// Data entries are only produced by models that accept the entry's content type through
    /// ``LanguageModel/supportsDataEntryType(_:)``.
    ///
    /// When the `onDataEntry` closure throws an error, the caller's `respond` or `response`
    /// propagates that error.
    ///
    /// Use this to observe or log the custom data the model produces as it works toward a
    /// response.
    @available(iOS 27.3, macOS 27.3, watchOS 27.3, tvOS 27.3, *)
    @export(implementation) public func onDataEntry(perform action: nonisolated(nonsending) sending @escaping () async throws -> Void) -> some LanguageModelSession.DynamicProfile


    /// Runs an action whenever this dynamic profile produces a data entry.
    ///
    /// Data entries are only produced by models that accept the entry's content type through
    /// ``LanguageModel/supportsDataEntryType(_:)``.
    ///
    /// When the `onDataEntry` closure throws an error, the caller's `respond` or `response`
    /// propagates that error.
    ///
    /// Use this to observe or log the custom data the model produces as it works toward a
    /// response.
    @available(iOS 27.3, macOS 27.3, watchOS 27.3, tvOS 27.3, *)
    public func onDataEntry(perform action: nonisolated(nonsending) sending @escaping (Transcript.DataEntry) async throws -> Void) -> some LanguageModelSession.DynamicProfile


    /// Runs an action whenever a tool is called within this dynamic profile.
    ///
    /// When the `onToolCall` closure throws an error, the caller's `respond` or
    /// `response` propagates that error.
    ///
    /// Use this to track or log tool usage within a dynamic profile:
    ///
    /// ```swift
    /// struct MyDynamicProfile: LanguageModelSession.DynamicProfile {
    ///   var body: some LanguageModelSession.DynamicProfile {
    ///     Profile {
    ///       Instructions("You are a helpful assistant.")
    ///       SomeTool()
    ///     }
    ///     .onToolCall {
    ///       toolCallCount += 1
    ///     }
    ///   }
    /// }
    /// ```
    @export(implementation) public func onToolCall(perform action: nonisolated(nonsending) sending @escaping () async throws -> Void) -> some LanguageModelSession.DynamicProfile


    /// Runs an action whenever a tool is called within this dynamic profile.
    ///
    /// When the `onToolCall` closure throws an error, the caller's `respond` or
    /// `response` propagates that error.
    ///
    /// Use this to track or log tool usage within a dynamic profile:
    ///
    /// ```swift
    /// struct MyDynamicProfile: LanguageModelSession.DynamicProfile {
    ///   var body: some LanguageModelSession.DynamicProfile {
    ///     Profile {
    ///       Instructions("You are a helpful assistant.")
    ///       SomeTool()
    ///     }
    ///     .onToolCall { call in
    ///       print("called tool: \(call)")
    ///       toolCallCount += 1
    ///     }
    ///   }
    /// }
    /// ```
    public func onToolCall(perform action: nonisolated(nonsending) sending @escaping (Transcript.ToolCall) async throws -> Void) -> some LanguageModelSession.DynamicProfile


    /// Runs an action whenever a tool call output is received within this dynamic profile.
    ///
    /// When the `onToolOutput` closure throws an error, the caller's `respond` or
    /// `response` propagates that error.
    ///
    /// Use this to track or log tool output within a dynamic profile:
    ///
    /// ```swift
    /// struct MyDynamicProfile: LanguageModelSession.DynamicProfile {
    ///   var body: some LanguageModelSession.DynamicProfile {
    ///     Profile {
    ///       Instructions("You are a helpful assistant.")
    ///       SomeTool()
    ///     }
    ///     .onToolOutput {
    ///       toolOutputCount += 1
    ///     }
    ///   }
    /// }
    /// ```
    @export(implementation) public func onToolOutput(perform action: nonisolated(nonsending) sending @escaping () async throws -> Void) -> some LanguageModelSession.DynamicProfile


    /// Runs an action whenever a tool call output is received within this dynamic profile.
    ///
    /// When the `onToolOutput` closure throws an error, the caller's `respond` or
    /// `response` propagates that error.
    ///
    /// Use this to track or log tool output within a dynamic profile:
    ///
    /// ```swift
    /// struct MyDynamicProfile: LanguageModelSession.DynamicProfile {
    ///   var body: some LanguageModelSession.DynamicProfile {
    ///     Profile {
    ///       Instructions("You are a helpful assistant.")
    ///       SomeTool()
    ///     }
    ///     .onToolOutput { call, output in
    ///       print("Tool \(call) produced: \(output)")
    ///     }
    ///   }
    /// }
    /// ```
    public func onToolOutput(perform action: nonisolated(nonsending) sending @escaping (Transcript.ToolCall, Transcript.ToolOutput) async throws -> Void) -> some LanguageModelSession.DynamicProfile


    /// Runs an action when this dynamic profile becomes active.
    ///
    /// A profile becomes active when it is first included in the session's
    /// resolved configuration, or when it is re-included after being absent.
    /// Use this to set up state tied to the profile's lifecycle:
    ///
    /// ```swift
    /// struct MyDynamicProfile: LanguageModelSession.DynamicProfile {
    ///   var body: some LanguageModelSession.DynamicProfile {
    ///     Profile {
    ///       Instructions("You are a helpful assistant.")
    ///     }
    ///     .onActivate {
    ///       activeProfile = "assistant"
    ///     }
    ///   }
    /// }
    /// ```
    public func onActivate(perform action: sending @escaping @isolated(any) () async -> Void) -> some LanguageModelSession.DynamicProfile


    /// Runs an action when this dynamic profile becomes inactive.
    ///
    /// A profile becomes inactive when it is no longer included in the session's
    /// resolved configuration after previously being active. Use this to tear
    /// down state tied to the profile's lifecycle:
    ///
    /// ```swift
    /// struct MyDynamicProfile: LanguageModelSession.DynamicProfile {
    ///   var body: some LanguageModelSession.DynamicProfile {
    ///     Profile {
    ///       Instructions("You are a helpful assistant.")
    ///     }
    ///     .onDeactivate {
    ///       activeProfile = nil
    ///     }
    ///   }
    /// }
    /// ```
    public func onDeactivate(perform action: sending @escaping @isolated(any) () async -> Void) -> some LanguageModelSession.DynamicProfile

}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.DynamicProfile {

    /// A property wrapper that provides access to a session property from within a dynamic profile.
    public typealias SessionProperty = LanguageModelSession.SessionProperty
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.DynamicProfile {

    public typealias SessionState = LanguageModelSession.SessionState
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.DynamicProfile {

    public typealias SessionBinding = LanguageModelSession.SessionBinding
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.Profile {

    /// Creates a profile that contains dynamic instructions.
    ///
    /// - Parameters:
    ///   - dynamicInstructions: The dynamic instructions.
    public init(@DynamicInstructionsBuilder _ dynamicInstructions: () -> some DynamicInstructions)

    /// The content of the dynamic profile.
    public var body: Never { get }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.ConditionalDynamicProfile {

    /// The content of the dynamic profile.
    public var body: Never { get }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.DynamicProfileBuilder {

    /// Creates a builder with a block.
    @export(implementation) public static func buildBlock<T>(_ content: T) -> T where T : LanguageModelSession.DynamicProfile

    /// Creates a builder with the first component.
    @export(implementation) public static func buildEither<TrueContent, FalseContent>(first content: TrueContent) -> LanguageModelSession.ConditionalDynamicProfile<TrueContent, FalseContent> where TrueContent : LanguageModelSession.DynamicProfile, FalseContent : LanguageModelSession.DynamicProfile

    /// Creates a builder with the second component.
    @export(implementation) public static func buildEither<TrueContent, FalseContent>(second content: FalseContent) -> LanguageModelSession.ConditionalDynamicProfile<TrueContent, FalseContent> where TrueContent : LanguageModelSession.DynamicProfile, FalseContent : LanguageModelSession.DynamicProfile

    /// Creates a builder with a limited availability dynamic profile.
    ///
    /// - Parameter component: The dynamic profile.
    @export(implementation) public static func buildLimitedAvailability(_ component: some LanguageModelSession.DynamicProfile) -> LanguageModelSession.AnyDynamicProfile
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.DynamicProfileModifier {

    /// The dynamic profile type that a modifier's body returns.
    public typealias DynamicProfile = LanguageModelSession.DynamicProfile
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.DynamicProfileModifier {

    /// A property wrapper that provides access to a session property from within a
    /// dynamic profile modifier.
    public typealias SessionProperty = LanguageModelSession.SessionProperty
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.DynamicProfileModifierContent {

    /// The content of the dynamic profile.
    public var body: Never { get }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.ModifiedDynamicProfile {

    /// The content of the dynamic profile.
    public var body: Never { get }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.SessionProperty : Sendable where Value : Sendable {
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.SessionState : Sendable where Value : Sendable {
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.ToolCallError {

    /// A string representation of the error description.
    public var errorDescription: String? { get }
}

extension LanguageModelSession.Response : Sendable where Content : Sendable {
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.Usage {

    /// Token counts for the transcript submitted to the model.
    public struct Input : Sendable {

        /// The total number of input tokens from the transcript.
        public var totalTokenCount: Int

        /// The number of input tokens that were served from a cache.
        ///
        /// This value is always less than or equal to ``totalTokenCount``.
        public var cachedTokenCount: Int

        /// Creates an input token count.
        ///
        /// - Parameters:
        ///   - totalTokenCount: The total number of input tokens from the transcript.
        ///   - cachedTokenCount: The number of input tokens served from a cache.
        public init(totalTokenCount: Int, cachedTokenCount: Int)
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.Usage {

    /// Token counts for the output produced by the model.
    public struct Output : Sendable {

        /// The total number of output tokens.
        public var totalTokenCount: Int

        /// The number of output tokens that were part of the model's
        /// reasoning output.
        ///
        /// This value is always less than or equal to ``totalTokenCount``.
        /// A non-zero value requires the model to declare the
        /// ``LanguageModelCapabilities/Capability/reasoning`` capability.
        public var reasoningTokenCount: Int

        /// Creates an output token count.
        ///
        /// - Parameters:
        ///   - totalTokenCount: The total number of output tokens.
        ///   - reasoningTokenCount: The number of output tokens from reasoning.
        public init(totalTokenCount: Int, reasoningTokenCount: Int)
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.Usage {

    /// The total number of tokens involved in this generation, combining input and output counts.
    public var totalTokenCount: Int { get }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.Error : CustomDebugStringConvertible {

    /// A textual representation of this instance, suitable for debugging.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(reflecting:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `debugDescription` property for types that conform to
    /// `CustomDebugStringConvertible`:
    ///
    ///     struct Point: CustomDebugStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var debugDescription: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(reflecting: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `debugDescription` property.
    public var debugDescription: String { get }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.Error {

    /// A localized message describing what error occurred.
    public var errorDescription: String? { get }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.Error : Equatable {
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.Error : Hashable {
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.ResponseStream {

    /// A snapshot of partially generated content.
    public struct Snapshot {

        /// The content of the response.
        public var content: Content.PartiallyGenerated

        /// The raw content of the response.
        ///
        /// When `Content` is `GeneratedContent`, this is the same as `content`.
        public var rawContent: GeneratedContent

        /// The list of transcript entries.
        @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
        public var transcriptEntries: ArraySlice<Transcript.Entry>

        /// Information about how many tokens were used by this response.
        @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
        public var usage: LanguageModelSession.Usage
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.ResponseStream : AsyncSequence {

    /// The type of snapshot the stream produces.
    public typealias Element = LanguageModelSession.ResponseStream<Content>.Snapshot

    /// Creates the asynchronous iterator that produces elements of this
    /// asynchronous sequence.
    ///
    /// - Returns: An instance of the `AsyncIterator` type used to produce
    /// elements of the asynchronous sequence.
    public func makeAsyncIterator() -> LanguageModelSession.ResponseStream<Content>.AsyncIterator

    /// Returns the result from a streaming response, after it completes.
    ///
    /// If the streaming response was finished successfully before calling
    /// `collect()`, this method `Response` returns immediately.
    ///
    /// If the streaming response was finished with an error before calling
    /// `collect()`, this method propagates that error.
    nonisolated(nonsending) public func collect() async throws -> sending LanguageModelSession.Response<Content>
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.ResponseStream {

    /// An asynchronous iterator that produces snapshots of partially generated content.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    public struct AsyncIterator : AsyncIteratorProtocol {

        @available(macOS 26.0, iOS 26.0, tvOS 27.0, watchOS 27.0, *)
        public typealias Element = LanguageModelSession.ResponseStream<Content>.Snapshot
    }
}

@available(iOS 26.0, macOS 26.0, tvOS 27.3, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension LanguageModelSession.GenerationError.Refusal {

    /// An explanation for why the model refused to respond.
    @available(iOS 26.0, macOS 26.0, tvOS 27.3, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    nonisolated(nonsending) public var explanation: LanguageModelSession.Response<String> { get async throws }

    /// A stream containing an explanation about why the model refused to respond.
    @available(iOS 26.0, macOS 26.0, tvOS 27.3, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    public var explanationStream: LanguageModelSession.ResponseStream<String> { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension LanguageModelSession.GenerationError.Refusal {

    /// Creates a refusal for the transcript entries the model declined to respond to.
    ///
    /// - Parameter transcriptEntries: The entries leading up to the refusal, which the framework
    ///   uses to produce the refusal's explanation.
    public init(transcriptEntries: [Transcript.Entry])
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension LanguageModelSession.GenerationError.Context {

    /// Creates a context.
    ///
    /// - Parameters:
    ///   - debugDescription: The debug description to help developers diagnose issues during development.
    public init(debugDescription: String)
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension LanguageModelSession.ResponseStream.AsyncIterator {

    /// Asynchronously advances to the next element and returns it, or ends the
    /// sequence if there is no next element.
    ///
    /// - Returns: The next element, if it exists, or `nil` to signal the end of
    ///   the sequence.
    public mutating func next(isolation actor: isolated (any Actor)? = #isolation) async throws -> LanguageModelSession.ResponseStream<Content>.Snapshot?
}

/// A variant of Apple Foundation Models that runs on Private Cloud Compute to provide enhanced
/// capabilities while maintaining privacy guarantees.
///
/// To use the server-based model that powers Apple Intelligence, you change a single line of code
/// that you apply when creating your ``LanguageModelSession``.
///
/// ```swift
/// // Create a session with the server-side model.
/// let session = LanguageModelSession(model: PrivateCloudComputeLanguageModel())
/// let response = try await session.respond(to: "Analyze this document...")
/// ```
///
/// Before using the model, verify its availability. Model availability depends on whether the device and
/// region supports Apple Intelligence. For a list of supported devices,
/// see [Apple Intelligence](https://www.apple.com/apple-intelligence/).
///
/// > Important: To develop with PCC you must meet certain eligibility requirements. To learn more and
/// request access to the managed entitlement, see
/// [Accessing Private Cloud Compute](https://developer.apple.com/private-cloud-compute/).
@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
final public class PrivateCloudComputeLanguageModel : Sendable {

    @objc deinit
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel {

    /// The availability of the language model.
    final public var availability: PrivateCloudComputeLanguageModel.Availability { get }

    /// The usage quota for this model.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
    @available(tvOS, unavailable)
    final public var quotaUsage: PrivateCloudComputeLanguageModel.QuotaUsage { get }

    /// A Boolean value that indicates whether the system is entirely ready.
    final public var isAvailable: Bool { get }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel {

    /// Creates a Private Cloud Compute language model instance.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
    @available(tvOS, unavailable)
    public convenience init()
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel {

    /// The availability status for a specific PCC language model.
    @frozen public enum Availability : Equatable, Sendable {

        /// The system is ready to make requests.
        case available

        /// The system isn't ready for requests.
        case unavailable(PrivateCloudComputeLanguageModel.Availability.UnavailableReason)

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: PrivateCloudComputeLanguageModel.Availability, b: PrivateCloudComputeLanguageModel.Availability) -> Bool
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel : nonisolated Observable {
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel : LanguageModel {

    /// The capabilities of this language model.
    ///
    /// If a developer attempts to use capabilities that your model does not support,
    /// the system automatically throws an error for you instead of calling a respond method, like
    /// ``LanguageModelSession/respond(to:options:)-(Prompt,_)`` or
    /// ``LanguageModelSession/streamResponse(to:options:)-(Prompt,_)``.
    final public var capabilities: LanguageModelCapabilities { get }

    /// A configuration for an executor capable of running this model.
    final public var executorConfiguration: PrivateCloudComputeLanguageModel.Executor.Configuration { get }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel {

    /// An executor that responds to session requests using Private Cloud Compute.
    public struct Executor : LanguageModelExecutor {

        /// The model type this executor processes requests for.
        public typealias Model = PrivateCloudComputeLanguageModel

        /// Creates an executor from a configuration.
        public init(configuration: PrivateCloudComputeLanguageModel.Executor.Configuration)

        /// Loads assets into memory or pre-fills caches ahead of a request.
        ///
        /// - Note: The default implementation is a no-op.
        public func prewarm(model: PrivateCloudComputeLanguageModel.Executor.Model, transcript: Transcript)

        /// Creates a response stream containing deltas.
        ///
        /// - Parameters:
        ///    - request: The generation request.
        ///    - model: The model instance for this request, providing live model state.
        ///    - channel: A channel used to send events.
        ///
        /// - Note: If the model declares that it does not have a given capability
        /// via ``LanguageModel/capabilities``, then the system will automatically
        /// throw an error instead
        /// of invoking this method. You do not need to manually validate the request
        /// for any functionality captured by ``LanguageModelCapabilities``.
        nonisolated(nonsending) public func respond(to request: LanguageModelExecutorGenerationRequest, model: PrivateCloudComputeLanguageModel, streamingInto channel: LanguageModelExecutorGenerationChannel) async throws
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel {

    /// The maximum context size in tokens supported by the model.
    ///
    /// The context size represents the total number of tokens that can be used in a single session,
    /// including both input prompts and generated responses.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
    @available(tvOS, unavailable)
    nonisolated(nonsending) final public var contextSize: Int { get async throws }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel {

    /// Languages that the model supports.
    ///
    /// To check if a given locale is considered supported by the model, use ``supportsLocale(_:)``,
    /// which also takes language fallbacks into consideration.
    nonisolated(nonsending) final public var supportedLanguages: Set<Locale.Language> { get async throws }

    /// Returns a Boolean value that indicates whether the given locale is supported by the model.
    ///
    /// Use this method over ``supportedLanguages`` to check whether the given locale qualifies a
    /// person for using this model, as this method also takes language fallbacks into consideration.
    nonisolated(nonsending) final public func supportsLocale(_ locale: Locale = Locale.current) async throws -> Bool
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel {

    /// Errors that may occur when using Private Cloud Compute.
    public enum Error : Error, LocalizedError {

        /// An error that occurs when a network is available, but PCC is inaccessible.
        case networkFailure(PrivateCloudComputeLanguageModel.Error.NetworkFailure)

        /// The allotted usage quota has been reached.
        case quotaLimitReached(PrivateCloudComputeLanguageModel.Error.QuotaLimitReached)

        /// Services are unavailable.
        case serviceUnavailable(PrivateCloudComputeLanguageModel.Error.ServiceUnavailable)

        /// A localized message describing what error occurred.
        public var errorDescription: String? { get }
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel {

    /// The usage quota state for a Private Cloud Compute language model.
    ///
    /// A quota describes the model's per-user request budget and where the
    /// caller currently sits relative to it. Quotas are orthogonal to a
    /// model's availability — a model can be available even after its usage
    /// limit has been reached.
    public struct QuotaUsage : Sendable {

        /// The current quota status.
        public var status: PrivateCloudComputeLanguageModel.QuotaUsage.Status

        /// A suggestion the user can act on to increase their quota.
        ///
        /// A `nil` value indicates that the model provider does not surface an
        /// upgrade path through this API.
        public var limitIncreaseSuggestion: PrivateCloudComputeLanguageModel.QuotaUsage.LimitIncreaseSuggestion?

        /// The date at which the quota refreshes.
        ///
        /// A `nil` value indicates that the model provider has not reported a reset
        /// time. This may be because the provider's limit does not refresh on a
        /// fixed schedule, or because the provider does not expose this information.
        public var resetDate: Date?
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel.Availability {

    /// The reason the model is unavailable.
    public enum UnavailableReason : Equatable, Sendable {

        /// The device does not support Apple Intelligence.
        case deviceNotEligible

        /// The system is not yet ready to serve PCC requests.
        case systemNotReady

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: PrivateCloudComputeLanguageModel.Availability.UnavailableReason, b: PrivateCloudComputeLanguageModel.Availability.UnavailableReason) -> Bool

        /// Hashes the essential components of this value by feeding them into the
        /// given hasher.
        ///
        /// Implement this method to conform to the `Hashable` protocol. The
        /// components used for hashing must be the same as the components compared
        /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
        /// with each of these components.
        ///
        /// - Important: In your implementation of `hash(into:)`,
        ///   don't call `finalize()` on the `hasher` instance provided,
        ///   or replace it with a different instance.
        ///   Doing so may become a compile-time error in the future.
        ///
        /// - Parameter hasher: The hasher to use when combining the components
        ///   of this instance.
        public func hash(into hasher: inout Hasher)

        /// The hash value.
        ///
        /// Hash values are not guaranteed to be equal across different executions of
        /// your program. Do not save hash values to use during a future execution.
        ///
        /// - Important: `hashValue` is deprecated as a `Hashable` requirement. To
        ///   conform to `Hashable`, implement the `hash(into:)` requirement instead.
        ///   The compiler provides an implementation for `hashValue` for you.
        public var hashValue: Int { get }
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel.Executor {

    /// A configuration for an executor capable of running a Private Cloud Compute model.
    public struct Configuration : Hashable & Sendable {

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: PrivateCloudComputeLanguageModel.Executor.Configuration, b: PrivateCloudComputeLanguageModel.Executor.Configuration) -> Bool

        /// Hashes the essential components of this value by feeding them into the
        /// given hasher.
        ///
        /// Implement this method to conform to the `Hashable` protocol. The
        /// components used for hashing must be the same as the components compared
        /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
        /// with each of these components.
        ///
        /// - Important: In your implementation of `hash(into:)`,
        ///   don't call `finalize()` on the `hasher` instance provided,
        ///   or replace it with a different instance.
        ///   Doing so may become a compile-time error in the future.
        ///
        /// - Parameter hasher: The hasher to use when combining the components
        ///   of this instance.
        public func hash(into hasher: inout Hasher)

        /// The hash value.
        ///
        /// Hash values are not guaranteed to be equal across different executions of
        /// your program. Do not save hash values to use during a future execution.
        ///
        /// - Important: `hashValue` is deprecated as a `Hashable` requirement. To
        ///   conform to `Hashable`, implement the `hash(into:)` requirement instead.
        ///   The compiler provides an implementation for `hashValue` for you.
        public var hashValue: Int { get }
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel.Error : CustomDebugStringConvertible {

    /// A textual representation of this instance, suitable for debugging.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(reflecting:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `debugDescription` property for types that conform to
    /// `CustomDebugStringConvertible`:
    ///
    ///     struct Point: CustomDebugStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var debugDescription: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(reflecting: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `debugDescription` property.
    public var debugDescription: String { get }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel.Error {

    /// Information about a network problem that prevented a request from completing.
    public struct NetworkFailure : Sendable {

        /// A debug description of the network failure.
        public var debugDescription: String
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel.Error {

    /// Information about reaching a usage limit.
    ///
    /// A ``PrivateCloudComputeLanguageModel``  provides a ``LanguageModelError`` that
    /// you use to proactively respond to usage quota scenarios, like when a person is approaching their
    /// per-day request limit. When a person approaches or exceeds the daily quota, the framework
    /// provides a direct path for you to add system UI so the person can subscribe to iCloud+ to get
    /// more access.
    ///
    /// For more information about quota limits, see "Handle usage limits from using PCC"
    /// in <doc:adding-server-side-intelligence-with-private-cloud-compute>.
    public struct QuotaLimitReached : Sendable {

        /// A suggestion to increase the usage limit, if one exists.
        public var limitIncreaseSuggestion: PrivateCloudComputeLanguageModel.QuotaUsage.LimitIncreaseSuggestion?

        /// The date that the usage limit resets.
        public var resetDate: Date?

        /// A debug description of the usage limit.
        public var debugDescription: String
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel.Error {

    /// Information about the model service being unable to handle a request.
    public struct ServiceUnavailable : Sendable {

        /// A debug description of why the service is unavailable.
        public var debugDescription: String
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel.QuotaUsage {

    /// A Boolean value that indicates whether the usage limit has been reached.
    public var isLimitReached: Bool { get }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel.QuotaUsage {

    /// The quota status of a language model.
    public enum Status : Sendable {

        /// The model's usage is below its usage limit.
        case belowLimit(PrivateCloudComputeLanguageModel.QuotaUsage.Status.BelowLimit)

        /// The model's usage has reached its usage limit.
        case limitReached(PrivateCloudComputeLanguageModel.QuotaUsage.Status.LimitReached)
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel.QuotaUsage {

    /// An offer that a user can act on to increase their quota for a language model.
    public struct LimitIncreaseSuggestion : Sendable {
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel.Availability.UnavailableReason : Hashable {
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel.Error.NetworkFailure {

    /// Creates a network failure with the debug description you specify.
    public init(debugDescription: String)
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel.Error.QuotaLimitReached {

    /// Creates a quota limit reached instance.
    ///
    /// - Parameters:
    ///   - limitIncreaseSuggestion: The suggestion to increase the usage limit, if one exists.
    ///   - resetDate: The date that the usage limit resets.
    ///   - debugDescription: The debug description of the usage limit.
    public init(limitIncreaseSuggestion: PrivateCloudComputeLanguageModel.QuotaUsage.LimitIncreaseSuggestion? = nil, resetDate: Date? = nil, debugDescription: String)
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel.Error.ServiceUnavailable {

    /// Creates a service unavailable instance.
    ///
    /// - Parameter debugDescription: The debug description of why the service is unavailable.
    public init(debugDescription: String)
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel.QuotaUsage.Status {

    /// Information about usage that hasn't yet reached the usage limit.
    public struct BelowLimit : Sendable {

        /// A Boolean value that indicates whether usage is nearing the usage limit.
        public var isApproachingLimit: Bool
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel.QuotaUsage.Status {

    /// Information about usage that has reached the usage limit.
    public struct LimitReached : Sendable {
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension PrivateCloudComputeLanguageModel.QuotaUsage.LimitIncreaseSuggestion {

    /// Presents the limit increase flow to the user.
    public func show()
}

/// A prompt from a person to the model.
///
/// Prompts can contain content written by you, an outside source, or input directly from people using
/// your app. You can initialize a `Prompt` from a string literal:
///
/// ```swift
/// let prompt = Prompt("What are miniature schnauzers known for?")
/// ```
///
/// Use ``PromptBuilder`` to dynamically control the prompt's content based on your app's state. The
/// code below shows if the Boolean is `true`, the prompt includes a second line of text:
///
/// ```swift
/// let responseShouldRhyme = true
/// let prompt = Prompt {
///     "Answer the following question: Do Siberian Huskies love cold weather?"
///     if responseShouldRhyme {
///         "Your response MUST rhyme!"
///     }
/// }
/// ```
///
/// If your prompt includes input from people, consider wrapping the input in a string template with your
/// own prompt to better steer the model's response. For more information on handling inputs in your
/// prompts, see <doc:improving-the-safety-of-generative-model-output>.
///
/// Prompting the same session eventually leads to exceeding the context window size. You can recover
/// from this error by removing entries from the transcript and trying again. For more information on
/// managing the context window size, see <doc:managing-the-context-window>.
@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
public struct Prompt : Sendable {
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Prompt {

    /// Creates an instance with the content you specify.
    public init(_ content: some PromptRepresentable)
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Prompt : PromptRepresentable {

    /// An instance that represents a prompt.
    public var promptRepresentation: Prompt { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Prompt {

    /// Creates a prompt from the content of a builder closure.
    ///
    /// - Parameter content: A closure that produces the prompt to send to the model.
    public init(@PromptBuilder _ content: () throws -> Prompt) rethrows
}

/// A type that represents a prompt builder.
@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
@resultBuilder public struct PromptBuilder {
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension PromptBuilder {

    /// Creates a builder with a block.
    @export(implementation) public static func buildBlock<each P>(_ components: repeat each P) -> Prompt where repeat each P : PromptRepresentable

    /// Creates a builder with an array of prompts.
    @export(implementation) public static func buildArray(_ prompts: [some PromptRepresentable]) -> Prompt

    /// Creates a builder with the first component.
    @export(implementation) public static func buildEither(first component: some PromptRepresentable) -> Prompt

    /// Creates a builder with the second component.
    @export(implementation) public static func buildEither(second component: some PromptRepresentable) -> Prompt

    /// Creates a builder with an optional component.
    @export(implementation) public static func buildOptional(_ component: Prompt?) -> Prompt

    /// Creates a builder with a limited availability prompt.
    @export(implementation) public static func buildLimitedAvailability(_ prompt: some PromptRepresentable) -> Prompt

    /// Creates a builder with an expression.
    @export(implementation) public static func buildExpression<P>(_ expression: P) -> P where P : PromptRepresentable

    /// Creates a builder with a prompt expression.
    @export(implementation) public static func buildExpression(_ expression: Prompt) -> Prompt
}

/// A type whose value can represent a prompt.
///
/// - Important: Conformance to this protocol is provided automatically by the
/// `@Generable` macro, you should **not** override its implementations. Overriding
/// may negatively impact runtime performance and cause bugs.
///
/// For types that are not ``Generable``, you may provide your own implementation.
///
/// Experiment with different representations to find one that works well for
/// your type. Generally, any format that is easily understandable to humans
/// will work well for the model as well.
///
/// ```swift
/// struct FamousHistoricalFigure: PromptRepresentable {
///     var name: String
///     var biggestAccomplishment: String
///
///     var promptRepresentation: Prompt {
///         """
///         Famous Historical Figure:
///         - name: \(name)
///         - best known for: \(biggestAccomplishment)
///         """
///     }
/// }
///
/// let response = try await LanguageModelSession().respond {
///     "Tell me more about..."
///     FamousHistoricalFigure(
///         name: "Albert Einstein",
///         biggestAccomplishment: "Theory of Relativity"
///     )
/// }
/// ```
@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
public protocol PromptRepresentable {

    /// An instance that represents a prompt.
    @PromptBuilder var promptRepresentation: Prompt { get }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
@attached(accessor) @attached(peer, names: prefixed(__Key_)) public macro SessionPropertyEntry() = #externalMacro(module: "FoundationModelsMacros", type: "SessionPropertyEntryMacro")

/// A protocol for defining a custom session property key.
@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
public protocol SessionPropertyKey : SendableMetatype {

    /// The type of value that represent this property key.
    associatedtype Value

    /// The default value of the property key.
    static var defaultValue: Self.Value { get }
}

/// A container for property values.
///
/// Use session property values across your session. To help manage the context window, access
/// ``SessionPropertyValues/history`` to modify the transcript for the session:
///
/// ```swift
/// struct CompactingProfile: LanguageModelSession.DynamicProfile {
///     @SessionProperty(\.history)
///     var history
///
///     var body: some LanguageModelSession.DynamicProfile {
///         Profile {
///             // Custom instructions and tools that you define.
///         }
///         .onResponse { _ in
///             // Compact the history when the entries exceed a certain limit.
///             if history.count > 100 {
///                 history = Array(history.suffix(50))
///             }
///         }
///     }
/// }
/// ```
///
/// Because updating the transcript history can cause cache invalidations for some
/// models, carefully consider how you modify an existing transcript. For more
/// information, see <doc:optimizing-key-value-caching-in-language-model-sessions>.
///
/// Use ``SessionPropertyEntry()`` to create custom session properties.
@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
final public class SessionPropertyValues : Sendable {

    @objc deinit
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension SessionPropertyValues {

    /// The history portion of the session's transcript.
    final public var history: Transcript.HistoryView
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension SessionPropertyValues {

    /// Accesses the value stored for the given session property key.
    ///
    /// - Parameter key: The session property key type whose value to read or write.
    final public subscript<K>(key: K.Type) -> K.Value where K : SessionPropertyKey
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension SessionPropertyValues : nonisolated Observable {
}

/// An on-device Apple Foundation Model capable of text generation tasks.
///
/// The `SystemLanguageModel` refers to the on-device text foundation model that powers Apple
/// Intelligence. Use ``default`` to access the base version of the model and perform general-purpose
/// text generation tasks. To access a specialized version of the model, initialize the model
/// with ``UseCase`` to perform tasks like ``UseCase/contentTagging``. Apple periodically
/// updates `SystemLanguageModel` in routine OS updates to improve the on-device model's abilities
/// and performance. Currently, there are 3 model versions that align with:
///
/// - iOS, iPadOS, macOS, and visionOS **26.0 - 26.3**
/// - iOS, iPadOS, macOS, visionOS **26.4**
/// - iOS, iPadOS, macOS, and visionOS **27.0**
///
/// For more information about how model versions affect your app, see
/// <doc:updating-prompts-for-new-model-versions>.
///
/// Before you use the model, you need to verify its availability. Model availability depends on whether
/// the device and region supports Apple Intelligence. For a list of supported devices, see
/// [Apple Intelligence](https://www.apple.com/apple-intelligence/).
///
/// Use ``Availability`` to change what your app shows to people based on the availability condition:
///
/// ```swift
/// struct GenerativeView: View {
///     // Create a reference to the system language model.
///     private var model = SystemLanguageModel.default
///
///     var body: some View {
///         switch model.availability {
///         case .available:
///             // Show your intelligence UI.
///         case .unavailable(.deviceNotEligible):
///             // Show an alternative UI.
///         case .unavailable(.modelNotReady):
///             // The model isn't ready because it's downloading or because
///             // of other system reasons.
///         case .unavailable(let other):
///             // The model is unavailable for an unknown reason.
///         }
///     }
/// }
/// ```
@available(iOS 26.0, macOS 26.0, tvOS 27.3, *)
@available(watchOS, unavailable)
final public class SystemLanguageModel : Sendable {

    @objc deinit
}

@available(iOS 26.0, macOS 26.0, tvOS 27.3, *)
@available(watchOS, unavailable)
extension SystemLanguageModel {

    /// The availability of the language model.
    final public var availability: SystemLanguageModel.Availability { get }

    /// A Boolean value that indicates whether the system is entirely ready.
    final public var isAvailable: Bool { get }
}

@available(iOS 26.0, macOS 26.0, tvOS 27.3, *)
@available(watchOS, unavailable)
extension SystemLanguageModel {

    /// A type that represents the use case for prompting.
    @available(iOS 26.0, macOS 26.0, tvOS 27.3, *)
    public struct UseCase : Sendable, Equatable {

        /// A use case for general prompting.
        ///
        /// This is the default use case for the base version of the model.
        public static let general: SystemLanguageModel.UseCase

        /// A use case for content tagging.
        ///
        /// Content tagging produces a list of categorizing tags based on the input prompt. When specializing
        /// the model for the `contentTagging` use case, it always responds with tags. The tagging
        /// capabilities of the model include detecting topics, emotions, actions, and objects. For more
        /// information about content tagging, see <doc:categorizing-and-organizing-data-with-content-tags>.
        public static let contentTagging: SystemLanguageModel.UseCase

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: SystemLanguageModel.UseCase, b: SystemLanguageModel.UseCase) -> Bool
    }
}

@available(iOS 26.0, macOS 26.0, tvOS 27.3, *)
@available(watchOS, unavailable)
extension SystemLanguageModel : nonisolated Observable {
}

@available(iOS 27.0, macOS 27.0, tvOS 27.3, *)
@available(watchOS, unavailable)
extension SystemLanguageModel : LanguageModel {

    /// The capabilities of this language model.
    ///
    /// If a developer attempts to use capabilities that your model does not support,
    /// the system automatically throws an error for you instead of calling a respond method, like
    /// ``LanguageModelSession/respond(to:options:)-(Prompt,_)`` or
    /// ``LanguageModelSession/streamResponse(to:options:)-(Prompt,_)``.
    final public var capabilities: LanguageModelCapabilities { get }

    /// A configuration for an executor capable of running this model.
    final public var executorConfiguration: SystemLanguageModel.Executor.Configuration { get }
}

@available(iOS 27.0, macOS 27.0, tvOS 27.3, *)
@available(watchOS, unavailable)
extension SystemLanguageModel {

    /// An executor that responds to session requests using the on-device system model.
    public struct Executor : LanguageModelExecutor {

        /// The model type this executor processes requests for.
        public typealias Model = SystemLanguageModel

        /// Creates an executor from a configuration.
        public init(configuration: SystemLanguageModel.Executor.Configuration)

        /// Loads assets into memory or pre-fills caches ahead of a request.
        ///
        /// - Note: The default implementation is a no-op.
        public func prewarm(model: SystemLanguageModel.Executor.Model, transcript: Transcript)

        /// Creates a response stream containing deltas.
        ///
        /// - Parameters:
        ///    - request: The generation request.
        ///    - model: The model instance for this request, providing live model state.
        ///    - channel: A channel used to send events.
        ///
        /// - Note: If the model declares that it does not have a given capability
        /// via ``LanguageModel/capabilities``, then the system will automatically
        /// throw an error instead
        /// of invoking this method. You do not need to manually validate the request
        /// for any functionality captured by ``LanguageModelCapabilities``.
        nonisolated(nonsending) public func respond(to request: LanguageModelExecutorGenerationRequest, model: SystemLanguageModel, streamingInto channel: LanguageModelExecutorGenerationChannel) async throws
    }
}

@available(iOS 26.0, macOS 26.0, tvOS 27.3, *)
@available(watchOS, unavailable)
extension SystemLanguageModel {

    /// A set of controls that flag sensitive content from model input and output.
    @available(iOS 26.0, macOS 26.0, tvOS 27.3, *)
    public struct Guardrails : Sendable {
    }
}

@available(iOS 26.0, macOS 26.0, tvOS 27.3, *)
@available(watchOS, unavailable)
extension SystemLanguageModel {

    /// The availability status for a specific system language model.
    /// - SeeAlso: ``SystemLanguageModel/availability``
    @available(iOS 26.0, macOS 26.0, tvOS 27.3, *)
    @frozen public enum Availability : Equatable, Sendable {

        /// The system is ready to make requests.
        case available

        /// The system isn't ready for requests.
        case unavailable(SystemLanguageModel.Availability.UnavailableReason)

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: SystemLanguageModel.Availability, b: SystemLanguageModel.Availability) -> Bool
    }
}

@available(iOS 26.0, macOS 26.0, tvOS 27.3, *)
@available(watchOS, unavailable)
extension SystemLanguageModel {

    /// The base version of the model.
    ///
    /// The base model is a generic model that is useful for a
    /// wide variety of applications, but is not specialized to
    /// any particular use case.
    @available(iOS 26.0, macOS 26.0, tvOS 27.3, *)
    @available(watchOS, unavailable)
    public static var `default`: SystemLanguageModel { get }

    /// Creates a system language model instance for a specific use case.
    @available(iOS 26.0, macOS 26.0, tvOS 27.3, *)
    @available(watchOS, unavailable)
    public convenience init(useCase: SystemLanguageModel.UseCase = .general, guardrails: SystemLanguageModel.Guardrails = Guardrails.default)

    /// Creates the base version of the model with an adapter.
    @available(iOS 26.0, macOS 26.0, tvOS 27.3, *)
    @available(iOS, obsoleted: 27.0)
    @available(macOS, obsoleted: 27.0)
    @available(visionOS, obsoleted: 27.0)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    public convenience init(adapter: SystemLanguageModel.Adapter, guardrails: SystemLanguageModel.Guardrails = .default)

    /// Languages that the model supports.
    ///
    /// To check if a given locale is considered supported by the model, use ``supportsLocale(_:)``,
    /// which also takes language fallbacks into consideration.
    final public var supportedLanguages: Set<Locale.Language> { get }

    /// Returns a Boolean value that indicates whether the given locale is supported by the model.
    ///
    /// Use this method over ``supportedLanguages`` to check whether the given locale qualifies a
    /// person for using this model, as this method also takes language fallbacks into consideration.
    final public func supportsLocale(_ locale: Locale = Locale.current) -> Bool
}

@available(iOS 26.4, macOS 26.4, tvOS 27.3, *)
@available(watchOS, unavailable)
extension SystemLanguageModel {

    /// Returns the token count for the specified prompt.
    ///
    /// - Parameter prompt: The prompt to calculate the token count for.
    /// - Returns: The token count for the prompt.
    @available(iOS 26.4, macOS 26.4, tvOS 27.3, *)
    @available(watchOS, unavailable)
    nonisolated(nonsending) final public func tokenCount(for prompt: some PromptRepresentable) async throws -> Int

    /// Returns the token count for the specified instructions.
    ///
    /// - Parameter instructions: The instructions to calculate the token count for.
    /// - Returns: The token count for the instructions.
    @available(iOS 26.4, macOS 26.4, tvOS 27.3, *)
    @available(watchOS, unavailable)
    nonisolated(nonsending) final public func tokenCount(for instructions: Instructions) async throws -> Int

    /// Returns the token count for the specified tools.
    ///
    /// - Parameter tools: An array of tools to calculate the token count for.
    /// - Returns: The token count for the tools.
    @available(iOS 26.4, macOS 26.4, tvOS 27.3, *)
    @available(watchOS, unavailable)
    nonisolated(nonsending) final public func tokenCount(for tools: [any Tool]) async throws -> Int

    /// Returns the token count for the specified schema.
    ///
    /// - Parameter schema: The schema to calculate the token count for.
    /// - Returns: The token count for the schema.
    @available(iOS 26.4, macOS 26.4, tvOS 27.3, *)
    @available(watchOS, unavailable)
    nonisolated(nonsending) final public func tokenCount(for schema: GenerationSchema) async throws -> Int

    /// Returns the token count for the specified collection of transcript entries.
    ///
    /// - Parameter transcriptEntries: A collection of transcript entries to calculate the token count for.
    /// - Returns: The token count for the transcript.
    @available(iOS 26.4, macOS 26.4, tvOS 27.3, *)
    @available(watchOS, unavailable)
    nonisolated(nonsending) final public func tokenCount(for transcriptEntries: some Collection<Transcript.Entry>) async throws -> Int
}

@available(iOS 26.0, macOS 26.0, tvOS 27.3, *)
@available(watchOS, unavailable)
extension SystemLanguageModel {

    /// The maximum context size in tokens that the model supports.
    ///
    /// The context size represents the total number of tokens that can be used in a single session,
    /// including both input prompts and generated responses.
    ///
    /// - Returns: The context size, in tokens.
    /// - Throws: An error if the context size cannot be determined. Typically this is due to the model not being available or Apple Intelligence is disabled.
    @available(iOS 26.0, macOS 26.0, tvOS 27.3, *)
    @backDeployed(before: iOS 26.4, macOS 26.4, visionOS 26.4)
    final public var contextSize: Int { get }
}

@available(iOS 27.0, macOS 27.0, tvOS 27.3, *)
@available(watchOS, unavailable)
extension SystemLanguageModel {

    /// The variant of the on-device model backing this instance.
    final public var variant: SystemLanguageModel.Variant { get }
}

@available(iOS 27.0, macOS 27.0, tvOS 27.3, *)
@available(watchOS, unavailable)
extension SystemLanguageModel {

    /// The variant of an on-device model.
    public struct Variant : Sendable, Hashable {

        /// The user-facing name of the variant.
        ///
        /// For example, `"AFM 3 Core"` or `"AFM 3 Core Advanced"`.
        public let displayName: String

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: SystemLanguageModel.Variant, b: SystemLanguageModel.Variant) -> Bool

        /// Hashes the essential components of this value by feeding them into the
        /// given hasher.
        ///
        /// Implement this method to conform to the `Hashable` protocol. The
        /// components used for hashing must be the same as the components compared
        /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
        /// with each of these components.
        ///
        /// - Important: In your implementation of `hash(into:)`,
        ///   don't call `finalize()` on the `hasher` instance provided,
        ///   or replace it with a different instance.
        ///   Doing so may become a compile-time error in the future.
        ///
        /// - Parameter hasher: The hasher to use when combining the components
        ///   of this instance.
        public func hash(into hasher: inout Hasher)

        /// The hash value.
        ///
        /// Hash values are not guaranteed to be equal across different executions of
        /// your program. Do not save hash values to use during a future execution.
        ///
        /// - Important: `hashValue` is deprecated as a `Hashable` requirement. To
        ///   conform to `Hashable`, implement the `hash(into:)` requirement instead.
        ///   The compiler provides an implementation for `hashValue` for you.
        public var hashValue: Int { get }
    }
}

@available(iOS 26.0, macOS 26.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension SystemLanguageModel {

    /// An adapter for a language model.
    @available(iOS 26.0, macOS 26.0, *)
    @available(iOS, deprecated: 26.4, obsoleted: 27.0)
    @available(macOS, deprecated: 26.4, obsoleted: 27.0)
    @available(visionOS, deprecated: 26.4, obsoleted: 27.0)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    public struct Adapter {
    }
}

@available(iOS 27.0, macOS 27.0, tvOS 27.3, *)
@available(watchOS, unavailable)
extension SystemLanguageModel {

    /// An error specific to the on-device system language model.
    ///
    /// - Note: If your app deploys to iOS 26, macOS 26, or visionOS 26, where this error is
    ///   unavailable, use an availability check and fall back to
    ///   ``LanguageModelSession/GenerationError/assetsUnavailable(_:)``:
    ///
    ///   ```swift
    ///   do {
    ///       let response = try await session.respond(to: prompt)
    ///   } catch {
    ///       if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *),
    ///           let error = error as? SystemLanguageModel.Error
    ///       {
    ///           // Handle the error.
    ///       } else if case .assetsUnavailable = error as? LanguageModelSession.GenerationError {
    ///           // Handle the deprecated error.
    ///       }
    ///   }
    ///   ```
    public enum Error : LocalizedError {

        /// The assets required for the session are unavailable.
        ///
        /// This may happen if you forget to check model availability to begin with,
        /// or if the model assets are deleted. This can happen if the user disables
        /// Apple Intelligence while your app is running.
        case assetsUnavailable(SystemLanguageModel.Error.AssetsUnavailable)

        /// A localized message describing what error occurred.
        public var errorDescription: String? { get }
    }
}

@available(iOS 27.0, macOS 27.0, tvOS 27.3, *)
@available(watchOS, unavailable)
extension SystemLanguageModel.Executor {

    /// A configuration for an executor capable of running an on-device system model.
    public struct Configuration : Hashable & Sendable {

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: SystemLanguageModel.Executor.Configuration, b: SystemLanguageModel.Executor.Configuration) -> Bool

        /// Hashes the essential components of this value by feeding them into the
        /// given hasher.
        ///
        /// Implement this method to conform to the `Hashable` protocol. The
        /// components used for hashing must be the same as the components compared
        /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
        /// with each of these components.
        ///
        /// - Important: In your implementation of `hash(into:)`,
        ///   don't call `finalize()` on the `hasher` instance provided,
        ///   or replace it with a different instance.
        ///   Doing so may become a compile-time error in the future.
        ///
        /// - Parameter hasher: The hasher to use when combining the components
        ///   of this instance.
        public func hash(into hasher: inout Hasher)

        /// The hash value.
        ///
        /// Hash values are not guaranteed to be equal across different executions of
        /// your program. Do not save hash values to use during a future execution.
        ///
        /// - Important: `hashValue` is deprecated as a `Hashable` requirement. To
        ///   conform to `Hashable`, implement the `hash(into:)` requirement instead.
        ///   The compiler provides an implementation for `hashValue` for you.
        public var hashValue: Int { get }
    }
}

@available(iOS 26.0, macOS 26.0, tvOS 27.3, *)
@available(watchOS, unavailable)
extension SystemLanguageModel.Guardrails {

    /// Guardrails that default to ensuring that the system blocks unsafe content in prompts and responses.
    ///
    /// The `default` guardrail level means that all guardrails are turned on. When
    /// the guardrails block unsafe content from either the prompt input or model response,
    /// the framework throws a ``LanguageModelError/guardrailViolation(_:)`` error.
    public static let `default`: SystemLanguageModel.Guardrails

    /// Guardrails that allow for permissively transforming text input, including potentially unsafe
    /// content, to text responses.
    ///
    /// The `permissiveContentTransform` guardrail model lets the model handle potentially
    /// unsafe content, such as summarizing a news article. In this mode, requests you make to
    /// the model that generate a `String` will not throw ``LanguageModelError/guardrailViolation(_:)``
    /// errors. However, the model may still sometimes refuse to respond to a sensitive prompt, in which
    /// case it generates a `String` refusal message.
    ///
    /// When you generate responses other than `String`, this mode behaves the same way
    /// as ``SystemLanguageModel/Guardrails/default`` mode and throws
    /// ``LanguageModelError/guardrailViolation(_:)`` errors.
    public static let permissiveContentTransformations: SystemLanguageModel.Guardrails
}

@available(iOS 26.0, macOS 26.0, tvOS 27.3, *)
@available(watchOS, unavailable)
extension SystemLanguageModel.Availability {

    /// The reason the system language model is unavailable.
    @available(iOS 26.0, macOS 26.0, tvOS 27.3, *)
    public enum UnavailableReason : Equatable, Sendable {

        /// The device does not support Apple Intelligence.
        case deviceNotEligible

        /// Apple Intelligence is not enabled on the system.
        case appleIntelligenceNotEnabled

        /// The models aren't available on the user's device.
        ///
        /// Models are downloaded automatically based on factors
        /// like network status, battery level, and system load.
        case modelNotReady

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: SystemLanguageModel.Availability.UnavailableReason, b: SystemLanguageModel.Availability.UnavailableReason) -> Bool

        /// Hashes the essential components of this value by feeding them into the
        /// given hasher.
        ///
        /// Implement this method to conform to the `Hashable` protocol. The
        /// components used for hashing must be the same as the components compared
        /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
        /// with each of these components.
        ///
        /// - Important: In your implementation of `hash(into:)`,
        ///   don't call `finalize()` on the `hasher` instance provided,
        ///   or replace it with a different instance.
        ///   Doing so may become a compile-time error in the future.
        ///
        /// - Parameter hasher: The hasher to use when combining the components
        ///   of this instance.
        public func hash(into hasher: inout Hasher)

        /// The hash value.
        ///
        /// Hash values are not guaranteed to be equal across different executions of
        /// your program. Do not save hash values to use during a future execution.
        ///
        /// - Important: `hashValue` is deprecated as a `Hashable` requirement. To
        ///   conform to `Hashable`, implement the `hash(into:)` requirement instead.
        ///   The compiler provides an implementation for `hashValue` for you.
        public var hashValue: Int { get }
    }
}

@available(iOS 27.0, macOS 27.0, tvOS 27.3, *)
@available(watchOS, unavailable)
extension SystemLanguageModel.Variant {

    /// AFM 3 Core.
    public static var core3: SystemLanguageModel.Variant { get }

    /// AFM 3 Core Advanced.
    public static var coreAdvanced3: SystemLanguageModel.Variant { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(iOS, deprecated: 26.4, obsoleted: 27.0)
@available(macOS, deprecated: 26.4, obsoleted: 27.0)
@available(visionOS, deprecated: 26.4, obsoleted: 27.0)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension SystemLanguageModel.Adapter {

    /// Values read from the creator defined field of the adapter's metadata.
    public var creatorDefinedMetadata: [String : Any] { get }
}

/// A specialization of the system language model for custom use cases.
///
/// Use the base system model for most prompt engineering, guided generation, and tools. If you need to
/// specialize the model, train a custom `Adapter` to alter the system model weights and optimize it for
/// your custom task. Use custom adapters only if you're comfortable training foundation models in Python.
///
/// > Important: Be sure to re-train the adapter for every new version of the base system model that
/// Apple releases. Adapters consume a large amount of storage space and isn't recommended for
/// most apps.
///
/// For more on custom adapters, see [Get started with Foundation Models adapter training](https://developer.apple.com/apple-intelligence/foundation-models-adapter/).
@available(iOS 26.0, macOS 26.0, *)
@available(iOS, deprecated: 26.4, obsoleted: 27.0)
@available(macOS, deprecated: 26.4, obsoleted: 27.0)
@available(visionOS, deprecated: 26.4, obsoleted: 27.0)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension SystemLanguageModel.Adapter {

    /// Creates an adapter from the file URL.
    ///
    /// - Throws: An error of `AssetLoadingError` type when `fileURL`
    ///   is invalid.
    public init(fileURL: URL) throws

    /// Creates an adapter downloaded from the background assets framework.
    ///
    /// - Throws: An error of `AssetLoadingError` type when there are
    ///   no compatible asset packs with this adapter name downloaded.
    public init(name: String) throws

    /// Prepares an adapter before you use it with a language model session.
    ///
    /// Call this if your adapter has a draft model.
    @concurrent public func compile() async throws

    /// Gets all compatible adapter identifiers compatible with current system models.
    ///
    /// - Parameters:
    ///   - name: Name of the adapter.
    ///
    /// - Returns: All adapter identifiers compatible with current system models, listed in descending
    ///   order in terms of system preference. You can determine which asset pack or on-demand
    ///   resource to download with compatible adapter identifiers.
    ///
    ///   On devices that support Apple Intelligence, the result is guaranteed to be non-empty.
    @available(iOS 26.0, macOS 26.0, *)
    @available(iOS, deprecated: 26.4, obsoleted: 27.0)
    @available(macOS, deprecated: 26.4, obsoleted: 27.0)
    @available(visionOS, deprecated: 26.4, obsoleted: 27.0)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    public static func compatibleAdapterIdentifiers(name: String) -> [String]

    /// Removes all obsolete adapters that are no longer compatible with current system models.
    public static func removeObsoleteAdapters() throws
}

@available(iOS 26.0, macOS 26.0, *)
@available(iOS, deprecated: 26.4)
@available(macOS, deprecated: 26.4)
@available(visionOS, deprecated: 26.4)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension SystemLanguageModel.Adapter {

    /// An error that occurs while loading an adapter asset.
    @available(iOS 26.0, macOS 26.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    public enum AssetError : Error, LocalizedError {

        /// An error that happens if the provided asset files are invalid.
        case invalidAsset(SystemLanguageModel.Adapter.AssetError.Context)

        /// An error that happens if the provided adapter name is invalid.
        case invalidAdapterName(SystemLanguageModel.Adapter.AssetError.Context)

        /// An error that happens if there are no compatible adapters for the current system base model.
        case compatibleAdapterNotFound(SystemLanguageModel.Adapter.AssetError.Context)
    }
}

@available(iOS 27.0, macOS 27.0, tvOS 27.3, *)
@available(watchOS, unavailable)
extension SystemLanguageModel.Error : CustomDebugStringConvertible {

    /// A textual representation of this instance, suitable for debugging.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(reflecting:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `debugDescription` property for types that conform to
    /// `CustomDebugStringConvertible`:
    ///
    ///     struct Point: CustomDebugStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var debugDescription: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(reflecting: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `debugDescription` property.
    public var debugDescription: String { get }
}

@available(iOS 27.0, macOS 27.0, tvOS 27.3, *)
@available(watchOS, unavailable)
extension SystemLanguageModel.Error {

    /// Information about unavailable model assets.
    public struct AssetsUnavailable : Sendable {

        /// A description of why the assets are unavailable.
        public var debugDescription: String

        /// Creates an assets unavailable value.
        /// - Parameter debugDescription: A description of why the assets are unavailable.
        public init(debugDescription: String)
    }
}

@available(iOS 26.0, macOS 26.0, tvOS 27.3, *)
@available(watchOS, unavailable)
extension SystemLanguageModel.Availability.UnavailableReason : Hashable {
}

@available(iOS 26.0, macOS 26.0, *)
@available(iOS, deprecated: 26.4)
@available(macOS, deprecated: 26.4)
@available(visionOS, deprecated: 26.4)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension SystemLanguageModel.Adapter.AssetError {

    /// The context in which the error occurred.
    @available(iOS 26.0, macOS 26.0, *)
    @available(iOS, deprecated: 26.4)
    @available(macOS, deprecated: 26.4)
    @available(visionOS, deprecated: 26.4)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    public struct Context : Sendable {

        /// A debug description to help developers diagnose issues during development.
        ///
        /// This string is not localized and is not appropriate for display to end users.
        public let debugDescription: String
    }
}

@available(iOS 26.0, macOS 26.0, *)
@available(iOS, deprecated: 26.4)
@available(macOS, deprecated: 26.4)
@available(visionOS, deprecated: 26.4)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension SystemLanguageModel.Adapter.AssetError {

    /// A string representation of the error description.
    public var errorDescription: String? { get }

    /// A localized message describing how one might recover from the failure.
    public var recoverySuggestion: String? { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(iOS, deprecated: 26.4)
@available(macOS, deprecated: 26.4)
@available(visionOS, deprecated: 26.4)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension SystemLanguageModel.Adapter.AssetError.Context {

    public init(debugDescription: String)
}

/// A tool that a model can call to gather information at runtime or perform side effects.
///
/// Tool calling gives the model the ability to call your code to incorporate
/// up-to-date information like recent events and data from your app. A tool
/// includes a name and a description that the framework puts in the prompt to let
/// the model decide when and how often to call your tool.
///
/// A `Tool` defines a ``call(arguments:)`` method that takes arguments that conforms to
/// ``ConvertibleFromGeneratedContent``, and returns an output of any type that conforms to
/// ``PromptRepresentable``, allowing the model to understand and reason about in subsequent
/// interactions. Typically, ``Output`` is a `String` or any ``Generable`` types.
///
/// ```swift
/// struct FindContacts: Tool {
///     let name = "findContacts"
///     let description = "Finds a specific number of contacts"
///
///     @Generable
///     struct Arguments {
///         @Guide(description: "The number of contacts to get", .range(1...10))
///         let count: Int
///     }
///
///     func call(arguments: Arguments) async throws -> [String] {
///         var contacts: [CNContact] = []
///         // Fetch a number of contacts using the arguments.
///         let formattedContacts = contacts.map {
///             "\($0.givenName) \($0.familyName)"
///         }
///         return formattedContacts
///     }
/// }
/// ```
///
/// Tools must conform to <doc://com.apple.documentation/documentation/swift/sendable>
/// so the framework can run them concurrently. If the model needs to pass the output
/// of one tool as the input to another, it executes back-to-back tool calls.
///
/// You control the life cycle of your tool, so you can track the state of it between
/// calls to the model. For example, you might store a list of database records that
/// you don't want to reuse between tool calls.
///
/// Prompting the model with tools contributes to the available context window size.
/// When you provide a tool in your generation request, the framework puts the tool
/// definitions --- name, description, parameter information --- in the prompt so the
/// model can decide when and how often to call the tool. After calling your tool,
/// the framework returns the tool's output back to the model for further processing.
/// For more information on managing the context window size, see <doc:managing-the-context-window>.
@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
public protocol Tool<Arguments, Output> : Sendable {

    /// The output that this tool produces for the language model to reason about in subsequent
    /// interactions.
    ///
    /// Typically output is either a `String` or a ``Generable`` type.
    associatedtype Output : PromptRepresentable

    /// The arguments that this tool should accept.
    ///
    /// Typically arguments are either a ``Generable`` type or ``GeneratedContent``.
    associatedtype Arguments : ConvertibleFromGeneratedContent

    /// A unique name for the tool.
    ///
    /// Use whichever style reads best in your codebase, such as `get_weather`, `toggleDarkMode`,
    /// or `search contacts`.
    var name: String { get }

    /// A natural language description of when and how to use the tool.
    var description: String { get }

    /// A schema for the parameters this tool accepts.
    var parameters: GenerationSchema { get }

    /// A Boolean value that indicates whether the framework includes this tool's definition
    /// in the session's instructions.
    ///
    /// The default implementation is `true`
    ///
    /// - Note: This should only be `false` if the model has been trained to have
    /// innate knowledge of this tool. For zero-shot prompting, it should always be `true`.
    var includesSchemaInInstructions: Bool { get }

    /// Performs the tool's action when a language model wants to use this tool.
    ///
    /// If errors are thrown in the body of this method, the framework wraps them in a
    /// ``LanguageModelSession/ToolCallError`` and rethrows them at the call site
    /// of ``LanguageModelSession/respond(to:options:)-(Prompt,_)``.
    ///
    /// - Note: This method may be invoked concurrently with itself or with other tools.
    @concurrent func call(arguments: Self.Arguments) async throws -> Self.Output
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension Tool {

    /// A property wrapper that provides access to a session property from within a tool.
    public typealias SessionProperty = LanguageModelSession.SessionProperty
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension Tool {

    public typealias SessionState = LanguageModelSession.SessionState
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension Tool {

    public typealias SessionBinding = LanguageModelSession.SessionBinding
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Tool {

    /// A unique name for the tool.
    ///
    /// Use whichever style reads best in your codebase, such as `get_weather`, `toggleDarkMode`,
    /// or `search contacts`.
    public var name: String { get }

    /// A Boolean value that indicates whether the framework includes this tool's definition
    /// in the session's instructions.
    ///
    /// The default implementation is `true`
    ///
    /// - Note: This should only be `false` if the model has been trained to have
    /// innate knowledge of this tool. For zero-shot prompting, it should always be `true`.
    public var includesSchemaInInstructions: Bool { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Tool where Self.Arguments : Generable {

    /// A schema for the parameters this tool accepts.
    public var parameters: GenerationSchema { get }
}

/// A linear history of entries that reflect an interaction with a session.
///
/// Use a `Transcript` to visualize previous instructions, prompts and model responses. If you use tool
/// calling, a `Transcript` includes a history of tool calls and their results.
///
/// ```swift
/// struct HistoryView: View {
///     let session: LanguageModelSession
///
///     var body: some View {
///         ScrollView {
///             ForEach(session.transcript) { entry in
///                 switch entry {
///                 case let .instructions(instructions):
///                     MyInstructionsView(instructions)
///                 case let .prompt(prompt):
///                     MyPromptView(prompt)
///                 case let .reasoning(reasoning):
///                     MyReasoningView(reasoning)
///                 case let .toolCalls(toolCalls):
///                     MyToolCallsView(toolCalls)
///                 case let .toolOutput(toolOutput):
///                     MyToolOutputView(toolOutput)
///                 case let .response(response):
///                     MyResponseView(response)
///                 }
///             }
///         }
///     }
/// }
/// ```
///
/// When you create a new ``LanguageModelSession`` it doesn't contain the state of a
/// previous session. You can initialize a new session with a list of entries you
/// get from a session ``LanguageModelSession/transcript``:
///
/// ```swift
/// // Create a new session with the first and last entries from a previous session.
/// func newContextualSession(with originalSession: LanguageModelSession) -> LanguageModelSession {
///     let allEntries = originalSession.transcript
///
///     // Collect the entries to keep from the original session.
///     let entries = [allEntries.first, allEntries.last].compactMap { $0 }
///     let transcript = Transcript(entries: entries)
///
///     // Create a new session with the result and preload the session resources.
///     var session = LanguageModelSession(transcript: transcript)
///     session.prewarm()
///     return session
/// }
/// ```
@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
public struct Transcript : Sendable, Equatable {

    /// Creates a transcript.
    ///
    /// - Parameters:
    ///   - entries: An array of entries to seed the transcript.
    public init(entries: some Sequence<Transcript.Entry> = [])

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (a: Transcript, b: Transcript) -> Bool
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript : RandomAccessCollection {

    /// The type that represents a position of an entry in a transcript.
    public typealias Index = Int

    /// Accesses the entry at the specified position.
    ///
    /// - Parameter index: The position of the entry to access, which must be a valid index of
    ///   the transcript.
    public subscript(index: Transcript.Index) -> Transcript.Entry

    /// The position of the first element in a nonempty collection.
    ///
    /// If the collection is empty, `startIndex` is equal to `endIndex`.
    public var startIndex: Int { get }

    /// The collection's "past the end" position---that is, the position one
    /// greater than the last valid subscript argument.
    ///
    /// When you need a range that includes the last element of a collection, use
    /// the half-open range operator (`..<`) with `endIndex`. The `..<` operator
    /// creates a range that doesn't include the upper bound, so it's always
    /// safe to use with `endIndex`. For example:
    ///
    ///     let numbers = [10, 20, 30, 40, 50]
    ///     if let index = numbers.firstIndex(of: 30) {
    ///         print(numbers[index ..< numbers.endIndex])
    ///     }
    ///     // Prints "[30, 40, 50]"
    ///
    /// If the collection is empty, `endIndex` is equal to `startIndex`.
    public var endIndex: Int { get }

    /// A type that represents the indices that are valid for subscripting the
    /// collection, in ascending order.
    @available(macOS 26.0, iOS 26.0, tvOS 27.0, watchOS 27.0, *)
    public typealias Indices = Range<Transcript.Index>

    /// A type that provides the collection's iteration interface and
    /// encapsulates its iteration state.
    ///
    /// By default, a collection conforms to the `Sequence` protocol by
    /// supplying `IndexingIterator` as its associated `Iterator`
    /// type.
    @available(macOS 26.0, iOS 26.0, tvOS 27.0, watchOS 27.0, *)
    public typealias Iterator = IndexingIterator<Transcript>
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript {

    /// An entry in a transcript.
    ///
    /// An individual entry in a transcript may represent instructions from you
    /// to the model, a prompt from a user, tool calls, or a response generated
    /// by the model.
    @nonexhaustive public enum Entry : Sendable, Identifiable, Equatable {

        /// Instructions, typically provided by you, the developer.
        case instructions(Transcript.Instructions)

        /// A prompt, typically sourced from an end user.
        case prompt(Transcript.Prompt)

        /// A collection of tool calls generated by the model.
        case toolCalls(Transcript.ToolCalls)

        /// A tool output provided back to the model.
        case toolOutput(Transcript.ToolOutput)

        /// A response from the model.
        case response(Transcript.Response)

        /// Reasoning from the model.
        @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
        case reasoning(Transcript.Reasoning)

        /// An entry representing a custom type encoded as data.
        ///
        /// The `contentType` allows you to identify which type the data can be decoded as.
        @available(iOS 27.2, macOS 27.2, watchOS 27.2, tvOS 27.2, *)
        case data(Transcript.DataEntry)

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.Entry, b: Transcript.Entry) -> Bool

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(macOS 26.0, iOS 26.0, tvOS 27.0, watchOS 27.0, *)
        public typealias ID = String
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript {

    /// The types of segments that may be included in a transcript entry.
    @nonexhaustive public enum Segment : Sendable, Identifiable, Equatable {

        /// A segment containing text.
        case text(Transcript.TextSegment)

        /// A segment containing structured content.
        case structure(Transcript.StructuredSegment)

        /// A segment containing an attachment.
        @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
        case attachment(Transcript.AttachmentSegment)

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(macOS 26.0, iOS 26.0, tvOS 27.0, watchOS 27.0, *)
        public typealias ID = String
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript {

    /// A segment containing text.
    public struct TextSegment : Sendable, Identifiable, Equatable {

        /// The stable identity of the entity associated with this instance.
        public var id: String

        /// The text of the segment.
        public var content: String

        /// Creates a text segment that contains the text you provide.
        ///
        /// - Parameters:
        ///   - id: A unique identifier for the segment.
        ///   - content: The text of the segment.
        public init(id: String = UUID().uuidString, content: String)

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.TextSegment, b: Transcript.TextSegment) -> Bool

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(macOS 26.0, iOS 26.0, tvOS 27.0, watchOS 27.0, *)
        public typealias ID = String
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript {

    /// A segment containing structured content.
    public struct StructuredSegment : Sendable, Identifiable, Equatable {

        /// The stable identity of the entity associated with this instance.
        public var id: String

        /// A source that can be used to understand which type the content represents.
        @available(iOS, deprecated: 27.0, renamed: "schemaName")
        @available(macOS, deprecated: 27.0, renamed: "schemaName")
        @available(visionOS, deprecated: 27.0, renamed: "schemaName")
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public var source: String

        /// The content of the segment.
        public var content: GeneratedContent

        @available(iOS, deprecated: 27.0, renamed: "init(id:schemaName:content:)")
        @available(macOS, deprecated: 27.0, renamed: "init(id:schemaName:content:)")
        @available(visionOS, deprecated: 27.0, renamed: "init(id:schemaName:content:)")
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public init(id: String = UUID().uuidString, source: String, content: GeneratedContent)

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.StructuredSegment, b: Transcript.StructuredSegment) -> Bool

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(macOS 26.0, iOS 26.0, tvOS 27.0, watchOS 27.0, *)
        public typealias ID = String
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript {

    /// A segment containing attached files or images.
    public struct AttachmentSegment : Sendable, Identifiable, Equatable {

        /// The stable identity of the entity associated with this instance.
        public var id: String

        /// The attached file or image.
        public var content: Transcript.Attachment

        /// An optional label that identifies the attachment.
        public var label: String?

        /// Creates an attachment segment that wraps the content you provide.
        ///
        /// - Parameters:
        ///   - id: A unique identifier for the segment.
        ///   - content: The attached file or image.
        ///   - label: An optional label that identifies the attachment.
        public init(id: String = UUID().uuidString, content: Transcript.Attachment, label: String? = nil)

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.AttachmentSegment, b: Transcript.AttachmentSegment) -> Bool

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(macOS 27.0, iOS 27.0, tvOS 27.0, watchOS 27.0, *)
        public typealias ID = String
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript {

    /// The types of attached content.
    @nonexhaustive public enum Attachment : Sendable, Equatable {

        /// An attached image.
        case image(Transcript.ImageAttachment)

        /// An attached data payload identified by a content type identifier.
        @available(iOS 27.2, macOS 27.2, watchOS 27.2, tvOS 27.2, *)
        case data(Transcript.DataAttachment)

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.Attachment, b: Transcript.Attachment) -> Bool
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript {

    /// An image attachment in a transcript entry.
    public struct ImageAttachment : Sendable, Equatable {

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.ImageAttachment, b: Transcript.ImageAttachment) -> Bool
    }
}

@available(iOS 27.2, macOS 27.2, watchOS 27.2, tvOS 27.2, *)
extension Transcript {

    /// A data attachment payload in a serialized, portable format.
    ///
    /// A ``DataAttachment`` records the bytes and identifier of a value that a
    /// ``LanguageModel`` implementation opted into via
    /// ``LanguageModel/supportsDataAttachmentType(_:)``. It's what a
    /// ``DataAttachmentRepresentable``-conforming type produces from its
    /// ``DataAttachmentRepresentable/transcriptRepresentation``, and it
    /// round-trips through the transcript's `Codable` conformance so the
    /// transcript remains portable even in environments where the declaring
    /// package isn't installed.
    public struct DataAttachment : Sendable, Equatable {

        /// A `UTType` identifying how to interpret ``content``.
        ///
        /// Packages that ship data attachment payloads should declare a dedicated
        /// `UTType` conforming to `.data` (or a more specific format like `.json`)
        /// and expose it as a static extension member so consumers can match on it
        /// directly.
        public var contentType: UTType

        /// A raw binary representation of the attachment.
        public var content: Data

        /// Metadata pertinent to this attachment.
        public var metadata: GeneratedContent

        /// Creates a data attachment with the content type, content, and metadata
        /// you provide.
        ///
        /// - Parameters:
        ///   - contentType: A `UTType` identifying how to interpret `content`.
        ///   - content: A raw binary representation of the attachment.
        ///   - metadata: Metadata pertinent to this attachment.
        public init(contentType: UTType, content: Data, metadata: GeneratedContent = GeneratedContent(properties: [:]))

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.DataAttachment, b: Transcript.DataAttachment) -> Bool
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript {

    /// Instructions you provide to the model that define its behavior.
    ///
    /// Instructions are typically provided to define the role and behavior of the model. The model is
    /// typically trained to obey instructions over any commands it receives in prompts. This is a
    /// security mechanism to help mitigate prompt injection attacks.
    public struct Instructions : Sendable, Identifiable, Equatable {

        /// The stable identity of the entity associated with this instance.
        public var id: String

        /// The content of the instructions, in natural language.
        ///
        /// - Note: Instructions are often provided in English even when the
        /// users interact with the model in another language.
        public var segments: [Transcript.Segment]

        /// A list of tools made available to the model.
        public var toolDefinitions: [Transcript.ToolDefinition]

        /// Creates instructions that describe how you want the model to behave, in natural language.
        ///
        /// - Parameters:
        ///   - id: A unique identifier for this instructions segment.
        ///   - segments: An array of segments that make up the instructions.
        ///   - toolDefinitions: Tools that the model should be allowed to call.
        public init(id: String = UUID().uuidString, segments: [Transcript.Segment], toolDefinitions: [Transcript.ToolDefinition])

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.Instructions, b: Transcript.Instructions) -> Bool

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(macOS 26.0, iOS 26.0, tvOS 27.0, watchOS 27.0, *)
        public typealias ID = String
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript {

    /// A definition of a tool.
    public struct ToolDefinition : Sendable, Equatable {

        /// The tool's name.
        public var name: String

        /// A description of how and when to use the tool.
        public var description: String

        /// A schema that specifies the parameters of the tool.
        @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
        public var parameters: GenerationSchema

        /// Creates a tool definition with the name, description, and parameter schema you provide.
        ///
        /// - Parameters:
        ///   - name: The name of the tool.
        ///   - description: A description of how and when to use the tool.
        ///   - parameters: A schema that specifies the parameters of the tool.
        public init(name: String, description: String, parameters: GenerationSchema)
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript {

    /// A prompt from the user to the model.
    ///
    /// Prompts typically contain content sourced directly from the user,
    /// though you may choose to augment prompts by interpolating content from
    /// end users into a template that you control.
    public struct Prompt : Sendable, Identifiable, Equatable {

        /// The identifier of the prompt.
        public var id: String

        /// Ordered prompt segments.
        public var segments: [Transcript.Segment]

        /// Generation options associated with the prompt.
        public var options: GenerationOptions

        /// Configuration of the prompt.
        @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
        public var contextOptions: ContextOptions

        /// Metadata provided as part of this prompt.
        @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
        public var metadata: [String : GeneratedContent]

        /// An optional response format that describes the desired output structure.
        public var responseFormat: Transcript.ResponseFormat?

        /// Creates a prompt.
        ///
        /// - Parameters:
        ///   - id: A unique identifier for the prompt.
        ///   - metadata: Metadata provided as part of this prompt.
        ///   - segments: An array of segments that make up the prompt.
        ///   - options: Options that control how tokens are sampled from the distribution the model produces.
        ///   - responseFormat: A response format that describes the output structure.
        ///   - contextOptions: Settings that configure how the model is prompted.
        @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
        public init(id: String = UUID().uuidString, metadata: [String : any ConvertibleToGeneratedContent] = [:], segments: [Transcript.Segment], options: GenerationOptions = GenerationOptions(), responseFormat: Transcript.ResponseFormat? = nil, contextOptions: ContextOptions = ContextOptions())

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(macOS 26.0, iOS 26.0, tvOS 27.0, watchOS 27.0, *)
        public typealias ID = String
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript {

    /// A response format that the model must conform its output to.
    public struct ResponseFormat : Sendable, Equatable {

        /// The way the response format constrains the model's output.
        @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
        public let kind: Transcript.ResponseFormat.Kind

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.ResponseFormat, b: Transcript.ResponseFormat) -> Bool
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript {

    /// A collection of tool calls generated by the model.
    public struct ToolCalls : Sendable, Identifiable, Equatable {

        /// The stable identity of the entity associated with this instance.
        public var id: String

        /// Creates a collection that contains the tool calls you provide.
        ///
        /// - Parameters:
        ///   - id: A unique identifier for the collection of tool calls.
        ///   - calls: The tool calls to include, in the order the model generates them.
        public init<S>(id: String = UUID().uuidString, _ calls: S) where S : Sequence, S.Element == Transcript.ToolCall

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.ToolCalls, b: Transcript.ToolCalls) -> Bool

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(macOS 26.0, iOS 26.0, tvOS 27.0, watchOS 27.0, *)
        public typealias ID = String
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript {

    /// A tool call generated by the model containing the name of a tool and arguments to pass to it.
    public struct ToolCall : Sendable, Identifiable, Equatable {

        /// The stable identity of the entity associated with this instance.
        public var id: String

        /// The name of the tool being invoked.
        public var toolName: String

        /// Arguments to pass to the invoked tool.
        public var arguments: GeneratedContent

        /// Metadata produced by the model while generating this tool call.
        @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
        public var metadata: [String : GeneratedContent]

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(macOS 26.0, iOS 26.0, tvOS 27.0, watchOS 27.0, *)
        public typealias ID = String
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript {

    /// A tool output provided back to the model.
    public struct ToolOutput : Sendable, Identifiable, Equatable {

        /// A unique id for this tool output.
        public var id: String

        /// The name of the tool that produced this output.
        public var toolName: String

        /// Segments of the tool output.
        public var segments: [Transcript.Segment]

        /// Creates a tool output that provides the result of a tool call back to the model.
        ///
        /// - Parameters:
        ///   - id: A unique identifier for the tool output.
        ///   - toolName: The name of the tool that produced the output.
        ///   - segments: The segments that make up the output.
        public init(id: String, toolName: String, segments: [Transcript.Segment])

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.ToolOutput, b: Transcript.ToolOutput) -> Bool

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(macOS 26.0, iOS 26.0, tvOS 27.0, watchOS 27.0, *)
        public typealias ID = String
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript {

    /// A response from the model.
    public struct Response : Sendable, Identifiable, Equatable {

        /// The stable identity of the entity associated with this instance.
        public var id: String

        /// Version-aware identifiers for all assets used to generate this response.
        public var assetIDs: [String]

        /// Ordered response segments.
        public var segments: [Transcript.Segment]

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(macOS 26.0, iOS 26.0, tvOS 27.0, watchOS 27.0, *)
        public typealias ID = String
    }
}

@available(iOS 27.2, macOS 27.2, watchOS 27.2, tvOS 27.2, *)
extension Transcript {

    /// A top-level transcript entry payload in a serialized, portable format.
    ///
    /// A ``DataEntry`` records the bytes and identifier of a value that a
    /// ``LanguageModel`` implementation opted into via
    /// ``LanguageModel/supportsDataEntryType(_:)``. It's what a
    /// ``DataEntryRepresentable``-conforming type produces from its
    /// ``DataEntryRepresentable/transcriptRepresentation``, and it
    /// round-trips through the transcript's `Codable` conformance so the
    /// transcript remains portable even in environments where the declaring
    /// package isn't installed.
    public struct DataEntry : Sendable, Identifiable, Equatable {

        /// The stable identity of the entity associated with this instance.
        public var id: String

        /// A `UTType` identifying how to interpret ``content``.
        ///
        /// Packages that ship data entry payloads should declare a dedicated
        /// `UTType` conforming to `.data` (or a more specific format like `.json`)
        /// and expose it as a static extension member so consumers can match on it
        /// directly.
        public var contentType: UTType

        /// A raw binary representation of the entry.
        public var content: Data

        /// Metadata pertinent to this entry.
        public var metadata: GeneratedContent

        /// Creates a data entry with the content type, content, and metadata
        /// you provide.
        ///
        /// - Parameters:
        ///   - id: A unique identifier for the entry.
        ///   - contentType: A `UTType` identifying how to interpret `content`.
        ///   - content: A raw binary representation of the entry.
        ///   - metadata: Metadata pertinent to this entry.
        public init(id: String = UUID().uuidString, contentType: UTType, content: Data, metadata: GeneratedContent = GeneratedContent(properties: [:]))

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.DataEntry, b: Transcript.DataEntry) -> Bool

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(macOS 27.2, iOS 27.2, tvOS 27.2, watchOS 27.2, *)
        public typealias ID = String
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript {

    /// A reasoning entry from the model.
    public struct Reasoning : Sendable, Identifiable, Equatable {

        /// The stable identity of the entity associated with this instance.
        public var id: String

        /// Ordered reasoning segments.
        ///
        /// May be empty or a partial/summary representation; full text may not be
        /// available when `signature` is non-nil.
        public var segments: [Transcript.Segment]

        /// Opaque producer-supplied signature for this reasoning entry.
        ///
        /// When this is non-nil, `segments` may represent a partial summary or be
        /// empty; full reasoning text may not be available.
        public var signature: Data?

        /// Metadata produced by the model while generating this reasoning entry.
        public var metadata: [String : GeneratedContent]

        /// Creates a reasoning entry that contains the segments you provide.
        ///
        /// - Parameters:
        ///   - id: A unique identifier for the reasoning entry.
        ///   - metadata: Additional information to associate with the entry, keyed by name.
        ///   - segments: The reasoning segments, in order.
        ///   - signature: An opaque, producer-supplied signature for the reasoning entry, if any.
        public init(id: String = UUID().uuidString, metadata: [String : any ConvertibleToGeneratedContent] = [:], segments: [Transcript.Segment], signature: Data? = nil)

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(macOS 27.0, iOS 27.0, tvOS 27.0, watchOS 27.0, *)
        public typealias ID = String
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript : MutableCollection {

    /// A type representing the sequence's elements.
    @available(macOS 27.0, iOS 27.0, tvOS 27.0, watchOS 27.0, *)
    public typealias Element = Transcript.Entry

    /// A collection representing a contiguous subrange of this collection's
    /// elements. The subsequence shares indices with the original collection.
    ///
    /// The default subsequence type for collections that don't define their own
    /// is `Slice`.
    @available(macOS 27.0, iOS 27.0, tvOS 27.0, watchOS 27.0, *)
    public typealias SubSequence = Slice<Transcript>
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript : RangeReplaceableCollection {

    /// Creates a new, empty collection.
    public init()

    /// Replaces the specified subrange of elements with the given collection.
    ///
    /// This method has the effect of removing the specified range of elements
    /// from the collection and inserting the new elements at the same location.
    /// The number of new elements need not match the number of elements being
    /// removed.
    ///
    /// In this example, three elements in the middle of an array of integers are
    /// replaced by the five elements of a `Repeated<Int>` instance.
    ///
    ///      var nums = [10, 20, 30, 40, 50]
    ///      nums.replaceSubrange(1...3, with: repeatElement(1, count: 5))
    ///      print(nums)
    ///      // Prints "[10, 1, 1, 1, 1, 1, 50]"
    ///
    /// If you pass a zero-length range as the `subrange` parameter, this method
    /// inserts the elements of `newElements` at `subrange.startIndex`. Calling
    /// the `insert(contentsOf:at:)` method instead is preferred.
    ///
    /// Likewise, if you pass a zero-length collection as the `newElements`
    /// parameter, this method removes the elements in the given subrange
    /// without replacement. Calling the `removeSubrange(_:)` method instead is
    /// preferred.
    ///
    /// Calling this method may invalidate any existing indices for use with this
    /// collection.
    ///
    /// - Parameters:
    ///   - subrange: The subrange of the collection to replace. The bounds of
    ///     the range must be valid indices of the collection.
    ///   - newElements: The new elements to add to the collection.
    ///
    /// - Complexity: O(*n* + *m*), where *n* is length of this collection and
    ///   *m* is the length of `newElements`. If the call to this method simply
    ///   appends the contents of `newElements` to the collection, this method is
    ///   equivalent to `append(contentsOf:)`.
    public mutating func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: consuming C) where C : Collection, C.Element == Transcript.Entry
}

extension Transcript {

    /// A mutable view into the conversational entries of a transcript.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public struct HistoryView : MutableCollection, RandomAccessCollection, RangeReplaceableCollection, Sendable {

        /// The type of entry the view contains.
        public typealias Element = Transcript.Entry

        /// The type that represents a contiguous subrange of the view's entries.
        public typealias SubSequence = Transcript.HistoryView

        /// Creates a new, empty collection.
        public init()

        /// The position of the first element in a nonempty collection.
        ///
        /// If the collection is empty, `startIndex` is equal to `endIndex`.
        public var startIndex: Transcript.HistoryView.Index { get }

        /// The collection's "past the end" position---that is, the position one
        /// greater than the last valid subscript argument.
        ///
        /// When you need a range that includes the last element of a collection, use
        /// the half-open range operator (`..<`) with `endIndex`. The `..<` operator
        /// creates a range that doesn't include the upper bound, so it's always
        /// safe to use with `endIndex`. For example:
        ///
        ///     let numbers = [10, 20, 30, 40, 50]
        ///     if let index = numbers.firstIndex(of: 30) {
        ///         print(numbers[index ..< numbers.endIndex])
        ///     }
        ///     // Prints "[30, 40, 50]"
        ///
        /// If the collection is empty, `endIndex` is equal to `startIndex`.
        public var endIndex: Transcript.HistoryView.Index { get }

        /// Accesses the entry at the specified position in the history view.
        ///
        /// - Parameter position: The position of the entry to access.
        public subscript(position: Transcript.HistoryView.Index) -> Transcript.Entry

        /// Accesses the subsequence of entries within the specified bounds.
        ///
        /// - Parameter bounds: A range of valid indices in the view.
        public subscript(bounds: Range<Transcript.HistoryView.Index>) -> Transcript.HistoryView

        /// Replaces the specified subrange of elements with the given collection.
        ///
        /// This method has the effect of removing the specified range of elements
        /// from the collection and inserting the new elements at the same location.
        /// The number of new elements need not match the number of elements being
        /// removed.
        ///
        /// In this example, three elements in the middle of an array of integers are
        /// replaced by the five elements of a `Repeated<Int>` instance.
        ///
        ///      var nums = [10, 20, 30, 40, 50]
        ///      nums.replaceSubrange(1...3, with: repeatElement(1, count: 5))
        ///      print(nums)
        ///      // Prints "[10, 1, 1, 1, 1, 1, 50]"
        ///
        /// If you pass a zero-length range as the `subrange` parameter, this method
        /// inserts the elements of `newElements` at `subrange.startIndex`. Calling
        /// the `insert(contentsOf:at:)` method instead is preferred.
        ///
        /// Likewise, if you pass a zero-length collection as the `newElements`
        /// parameter, this method removes the elements in the given subrange
        /// without replacement. Calling the `removeSubrange(_:)` method instead is
        /// preferred.
        ///
        /// Calling this method may invalidate any existing indices for use with this
        /// collection.
        ///
        /// - Parameters:
        ///   - subrange: The subrange of the collection to replace. The bounds of
        ///     the range must be valid indices of the collection.
        ///   - newElements: The new elements to add to the collection.
        ///
        /// - Complexity: O(*n* + *m*), where *n* is length of this collection and
        ///   *m* is the length of `newElements`. If the call to this method simply
        ///   appends the contents of `newElements` to the collection, this method is
        ///   equivalent to `append(contentsOf:)`.
        public mutating func replaceSubrange<C>(_ subrange: Range<Transcript.HistoryView.Index>, with newElements: C) where C : Collection, C.Element == Transcript.Entry

        /// Adds an entry to the end of the history view.
        ///
        /// - Parameter newElement: The entry to append to the view.
        public mutating func append(_ newElement: Transcript.Entry)

        /// Adds the entries of a sequence to the end of the history view.
        ///
        /// - Parameter newElements: The entries to append, in order.
        public mutating func append(contentsOf newElements: some Sequence<Transcript.Entry>)

        /// A type that represents the indices that are valid for subscripting the
        /// collection, in ascending order.
        @available(macOS 27.0, iOS 27.0, tvOS 27.0, watchOS 27.0, *)
        public typealias Indices = Range<Transcript.HistoryView.Index>

        /// A type that provides the collection's iteration interface and
        /// encapsulates its iteration state.
        ///
        /// By default, a collection conforms to the `Sequence` protocol by
        /// supplying `IndexingIterator` as its associated `Iterator`
        /// type.
        @available(macOS 27.0, iOS 27.0, tvOS 27.0, watchOS 27.0, *)
        public typealias Iterator = IndexingIterator<Transcript.HistoryView>
    }

    /// The transcript entries excluding the leading instructions entry, if present.
    ///
    /// Use `history` to access just the conversational entries — prompts, responses,
    /// tool calls, and tool outputs — without the initial instructions that were used
    /// to configure the session.
    ///
    /// When reading, if the first entry in the transcript is an ``Entry/instructions(_:)``
    /// entry, it is excluded from the returned view. All other entries, including any
    /// subsequent instructions entries, are included.
    ///
    /// When writing, the new value replaces all entries except the leading instructions
    /// entry, which is preserved.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public var history: Transcript.HistoryView
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript : Codable {

    /// Creates a new instance by decoding from the given decoder.
    ///
    /// This initializer throws an error if reading from the decoder fails, or
    /// if the data read is corrupted or otherwise invalid.
    ///
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: any Decoder) throws

    /// Encodes this value into the given encoder.
    ///
    /// If the value fails to encode anything, `encoder` will encode an empty
    /// keyed container in its place.
    ///
    /// This function throws an error if any values are invalid for the given
    /// encoder's format.
    ///
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: any Encoder) throws
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.Entry {

    /// The stable identity of the entity associated with this instance.
    public var id: String { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.Entry : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.Segment {

    /// The stable identity of the entity associated with this instance.
    public var id: String { get }

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (lhs: Transcript.Segment, rhs: Transcript.Segment) -> Bool
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.Segment : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.TextSegment : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.StructuredSegment {

    /// A name that can be used to understand which type the content represents.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    @backDeployed(before: iOS 27.0, macOS 27.0, visionOS 27.0)
    public var schemaName: String

    /// Creates a structured segment that contains the generated content you provide.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the segment.
    ///   - schemaName: A name that describes which type the content represents.
    ///   - content: The structured content of the segment.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public init(id: String = UUID().uuidString, schemaName: String, content: GeneratedContent)
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.StructuredSegment : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.AttachmentSegment : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.ImageAttachment {

    /// The URL of the original image asset, if the attachment was created from a URL.
    public var url: URL? { get }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.ImageAttachment {

    /// The image as a Core Graphics image.
    public var cgImage: CGImage { get }

    /// The image as a Core Image image.
    public var ciImage: CIImage { get }

    /// Returns the image as a pixel buffer, optionally resampled to a given resolution and pixel format.
    ///
    /// - Parameters:
    ///   - resolution: The desired resolution of the pixel buffer. Defaults to the image's original resolution.
    ///   - pixelFormat: The pixel format of the pixel buffer. Defaults to `kCVPixelFormatType_32BGRA`.
    public func pixelBuffer(resolution: CGSize? = nil, pixelFormat: OSType? = nil) throws -> CVReadOnlyPixelBuffer

    /// The display orientation of the image.
    public var orientation: CGImagePropertyOrientation { get }

    /// Creates an image attachment from a Core Graphics image.
    public init(_ cgImage: CGImage, orientation: CGImagePropertyOrientation? = nil)

    /// Creates an image attachment from a Core Image image.
    ///
    /// - Parameters:
    ///   - ciImage: The Core Image image to attach.
    ///   - orientation: The display orientation to apply to the image, or empty to use the
    ///     image's default orientation.
    public init(_ ciImage: CIImage, orientation: CGImagePropertyOrientation? = nil)

    /// Creates an image attachment from a pixel buffer.
    public init(_ pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil)

    /// Creates an image attachment from a file URL pointing to an image.
    public init(imageURL: URL, orientation: CGImagePropertyOrientation? = nil)
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.Instructions : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.ToolDefinition {

    /// Creates a tool definition that describes the tool you provide.
    ///
    /// - Parameter tool: The tool whose name, description, and parameters describe the definition.
    public init(tool: some Tool)

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (lhs: Transcript.ToolDefinition, rhs: Transcript.ToolDefinition) -> Bool
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.Prompt {

    /// Creates a prompt.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the prompt.
    ///   - segments: An array of segments that make up the prompt.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - responseFormat: A response format that describes the output structure.
    public init(id: String = UUID().uuidString, segments: [Transcript.Segment], options: GenerationOptions = GenerationOptions(), responseFormat: Transcript.ResponseFormat? = nil)

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (lhs: Transcript.Prompt, rhs: Transcript.Prompt) -> Bool
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.Prompt : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.ResponseFormat {

    /// A name associated with the response format.
    public var name: String { get }

    /// Creates a response format with type you specify.
    ///
    /// - Parameters:
    ///   - type: A ``Generable`` type to use as the response format.
    public init<Content>(type: Content.Type) where Content : Generable

    /// Creates a response format with a schema.
    ///
    /// - Parameters:
    ///   - schema: A schema to use as the response format.
    public init(schema: GenerationSchema)
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.ResponseFormat {

    /// A representation of the different ways a response format can constrain model output.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    @nonexhaustive public enum Kind : Sendable {

        /// A format that constrains the model's output to a generation schema.
        case schema(GenerationSchema)
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.ResponseFormat : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.ToolCalls : RandomAccessCollection {

    /// Accesses the tool call at the specified position.
    ///
    /// - Parameter position: The position of the tool call to access, which must be a valid index
    ///   of the collection.
    public subscript(position: Int) -> Transcript.ToolCall { get }

    /// The position of the first element in a nonempty collection.
    ///
    /// If the collection is empty, `startIndex` is equal to `endIndex`.
    public var startIndex: Int { get }

    /// The collection's "past the end" position---that is, the position one
    /// greater than the last valid subscript argument.
    ///
    /// When you need a range that includes the last element of a collection, use
    /// the half-open range operator (`..<`) with `endIndex`. The `..<` operator
    /// creates a range that doesn't include the upper bound, so it's always
    /// safe to use with `endIndex`. For example:
    ///
    ///     let numbers = [10, 20, 30, 40, 50]
    ///     if let index = numbers.firstIndex(of: 30) {
    ///         print(numbers[index ..< numbers.endIndex])
    ///     }
    ///     // Prints "[30, 40, 50]"
    ///
    /// If the collection is empty, `endIndex` is equal to `startIndex`.
    public var endIndex: Int { get }

    /// A type representing the sequence's elements.
    @available(macOS 26.0, iOS 26.0, tvOS 27.0, watchOS 27.0, *)
    public typealias Element = Transcript.ToolCall

    /// A type that represents a position in the collection.
    ///
    /// Valid indices consist of the position of every element and a
    /// "past the end" position that's not valid for use as a subscript
    /// argument.
    @available(macOS 26.0, iOS 26.0, tvOS 27.0, watchOS 27.0, *)
    public typealias Index = Int

    /// A type that represents the indices that are valid for subscripting the
    /// collection, in ascending order.
    @available(macOS 26.0, iOS 26.0, tvOS 27.0, watchOS 27.0, *)
    public typealias Indices = Range<Int>

    /// A type that provides the collection's iteration interface and
    /// encapsulates its iteration state.
    ///
    /// By default, a collection conforms to the `Sequence` protocol by
    /// supplying `IndexingIterator` as its associated `Iterator`
    /// type.
    @available(macOS 26.0, iOS 26.0, tvOS 27.0, watchOS 27.0, *)
    public typealias Iterator = IndexingIterator<Transcript.ToolCalls>

    /// A collection representing a contiguous subrange of this collection's
    /// elements. The subsequence shares indices with the original collection.
    ///
    /// The default subsequence type for collections that don't define their own
    /// is `Slice`.
    @available(macOS 26.0, iOS 26.0, tvOS 27.0, watchOS 27.0, *)
    public typealias SubSequence = Slice<Transcript.ToolCalls>
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.ToolCalls : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.ToolCall {

    /// Creates a tool call that invokes a tool with the arguments you provide.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the tool call.
    ///   - toolName: The name of the tool to invoke.
    ///   - arguments: The arguments to pass to the invoked tool.
    public init(id: String, toolName: String, arguments: GeneratedContent)

    /// Creates a tool call that invokes a tool with the metadata and arguments you provide.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the tool call.
    ///   - metadata: Additional information to associate with the tool call, keyed by name.
    ///   - toolName: The name of the tool to invoke.
    ///   - arguments: The arguments to pass to the invoked tool.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public init(id: String, metadata: [String : any ConvertibleToGeneratedContent], toolName: String, arguments: GeneratedContent)

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (lhs: Transcript.ToolCall, rhs: Transcript.ToolCall) -> Bool
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.ToolCall : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.ToolOutput : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.Response {

    /// Metadata associated with generating the response.
    @available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
    @backDeployed(before: iOS 27.0, macOS 27.0, visionOS 27.0)
    public var metadata: [String : GeneratedContent] { get }

    /// Creates a response that contains the segments you provide.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the response.
    ///   - assetIDs: A list of identifiers for the assets used to generate the response.
    ///   - segments: The segments of the response, in order.
    public init(id: String = UUID().uuidString, assetIDs: [String], segments: [Transcript.Segment])

    /// Creates a response that contains the metadata and segments you provide.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the response.
    ///   - metadata: Additional information to associate with the response, keyed by name.
    ///   - segments: The segments of the response, in order.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public init(id: String = UUID().uuidString, metadata: [String : any ConvertibleToGeneratedContent] = [:], segments: [Transcript.Segment])

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (lhs: Transcript.Response, rhs: Transcript.Response) -> Bool
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.Response : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 27.2, macOS 27.2, watchOS 27.2, tvOS 27.2, *)
extension Transcript.DataEntry : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.Reasoning {

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (lhs: Transcript.Reasoning, rhs: Transcript.Reasoning) -> Bool
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.Reasoning {

    /// A textual representation of the reasoning entry.
    public var description: String { get }
}

extension Transcript.HistoryView {

    /// A position of an entry within a history view.
    @available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
    public struct Index : Comparable, Hashable, Sendable, Strideable {

        /// Returns a Boolean value indicating whether the value of the first
        /// argument is less than that of the second argument.
        ///
        /// This function is the only requirement of the `Comparable` protocol. The
        /// remainder of the relational operator functions are implemented by the
        /// standard library for any type that conforms to `Comparable`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func < (lhs: Transcript.HistoryView.Index, rhs: Transcript.HistoryView.Index) -> Bool

        /// Returns the distance from this value to the given value, expressed as a 
        /// stride.
        ///
        /// If this type's `Stride` type conforms to `BinaryInteger`, then for two
        /// values `x` and `y`, and a distance `n = x.distance(to: y)`,
        /// `x.advanced(by: n) == y`. Using this method with types that have a
        /// noninteger `Stride` may result in an approximation.
        ///
        /// - Parameter other: The value to calculate the distance to.
        /// - Returns: The distance from this value to `other`.
        ///
        /// - Complexity: O(1)
        public func distance(to other: Transcript.HistoryView.Index) -> Int

        /// Returns a value that is offset the specified distance from this value.
        ///
        /// Use the `advanced(by:)` method in generic code to offset a value by a
        /// specified distance. If you're working directly with numeric values, use
        /// the addition operator (`+`) instead of this method.
        ///
        ///     func addOne<T: Strideable>(to x: T) -> T
        ///         where T.Stride: ExpressibleByIntegerLiteral
        ///     {
        ///         return x.advanced(by: 1)
        ///     }
        ///
        ///     let x = addOne(to: 5)
        ///     // x == 6
        ///     let y = addOne(to: 3.5)
        ///     // y = 4.5
        ///
        /// If this type's `Stride` type conforms to `BinaryInteger`, then for a
        /// value `x`, a distance `n`, and a value `y = x.advanced(by: n)`,
        /// `x.distance(to: y) == n`. Using this method with types that have a
        /// noninteger `Stride` may result in an approximation. If the result of
        /// advancing by `n` is not representable as a value of this type, then a
        /// runtime error may occur.
        ///
        /// - Parameter n: The distance to advance this value.
        /// - Returns: A value that is offset from this value by `n`.
        ///
        /// - Complexity: O(1)
        public func advanced(by n: Int) -> Transcript.HistoryView.Index

        /// A type that represents the distance between two values.
        @available(macOS 27.0, iOS 27.0, tvOS 27.0, watchOS 27.0, *)
        public typealias Stride = Int

        /// Hashes the essential components of this value by feeding them into the
        /// given hasher.
        ///
        /// Implement this method to conform to the `Hashable` protocol. The
        /// components used for hashing must be the same as the components compared
        /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
        /// with each of these components.
        ///
        /// - Important: In your implementation of `hash(into:)`,
        ///   don't call `finalize()` on the `hasher` instance provided,
        ///   or replace it with a different instance.
        ///   Doing so may become a compile-time error in the future.
        ///
        /// - Parameter hasher: The hasher to use when combining the components
        ///   of this instance.
        public func hash(into hasher: inout Hasher)

        /// The hash value.
        ///
        /// Hash values are not guaranteed to be equal across different executions of
        /// your program. Do not save hash values to use during a future execution.
        ///
        /// - Important: `hashValue` is deprecated as a `Hashable` requirement. To
        ///   conform to `Hashable`, implement the `hash(into:)` requirement instead.
        ///   The compiler provides an implementation for `hashValue` for you.
        public var hashValue: Int { get }
    }
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.HistoryView : ExpressibleByArrayLiteral {

    /// The type of entry an array literal contains when it creates a history view.
    public typealias ArrayLiteralElement = Transcript.Entry

    /// Creates an instance initialized with the given elements.
    public init(arrayLiteral elements: Transcript.Entry...)
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension Transcript.ResponseFormat.Kind : Equatable {

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (lhs: Transcript.ResponseFormat.Kind, rhs: Transcript.ResponseFormat.Kind) -> Bool
}

/// Options for controlling how a language model session manages the transcript when errors occur.
@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
public struct TranscriptErrorHandlingPolicy : Sendable {

    /// A policy that reverts the transcript back to the state it was in just before the most recent request.
    public static let revertTranscript: TranscriptErrorHandlingPolicy

    /// A policy that keeps the current transcript as is.
    ///
    /// The last entry of the transcript may be partially generated.
    public static let preserveTranscript: TranscriptErrorHandlingPolicy
}

/// A dynamic instructions type that represents a tuple.
@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
public struct TupleDynamicInstructions<each Content> : DynamicInstructions where repeat each Content : DynamicInstructions {

    /// Creates a dynamic instructions instance that represents a tuple.
    ///
    /// - Parameters:
    ///   - contents: The elements of the tuple.
    public init(_ contents: repeat each Content)

    /// The type of dynamic instructions that represent these instructions.
    @available(macOS 27.0, iOS 27.0, tvOS 27.0, watchOS 27.0, *)
    public typealias Body = Never
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension Optional : DynamicInstructions where Wrapped : DynamicInstructions {

    /// The content of the dynamic instructions.
    public var body: Never { get }

    /// The type of dynamic instructions that represent these instructions.
    @available(macOS 27.0, iOS 27.0, tvOS 27.0, watchOS 27.0, *)
    public typealias Body = Never
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension Never : DynamicInstructions {

    /// The content of the dynamic instructions.
    public var body: Never { get }

    /// The type of dynamic instructions that represent these instructions.
    @available(macOS 27.0, iOS 27.0, tvOS 27.0, watchOS 27.0, *)
    public typealias Body = Never
}

@available(iOS 27.0, macOS 27.0, watchOS 27.0, tvOS 27.0, *)
extension Never : LanguageModelSession.DynamicProfile {
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Optional where Wrapped : Generable {

    /// A representation of partially generated content for the wrapped type.
    public typealias PartiallyGenerated = Wrapped.PartiallyGenerated
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Optional : ConvertibleToGeneratedContent, PromptRepresentable, InstructionsRepresentable where Wrapped : ConvertibleToGeneratedContent {

    /// This instance represented as generated content.
    ///
    /// Conformance to this protocol is provided by the `@Generable` macro.
    /// You can provide a manual implementation to map values onto properties using
    /// different names. Use the generated content property as shown below, to
    /// manually return a new ``GeneratedContent`` with the properties you specify.
    ///
    /// ```swift
    /// struct Person: ConvertibleToGeneratedContent {
    ///    var name: String
    ///    var age: Int
    ///
    ///    var generatedContent: GeneratedContent {
    ///        GeneratedContent(properties: [
    ///            "firstName": name,
    ///            "ageInYears": age
    ///        ])
    ///    }
    /// }
    /// ```
    ///
    /// - Important: If your type also conforms to ``ConvertibleFromGeneratedContent``,
    /// it is critical that this implementation be symmetrical with ``ConvertibleFromGeneratedContent/init(_:)``.
    public var generatedContent: GeneratedContent { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Bool : Generable {

    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema { get }

    /// Creates an instance from content generated by a model.
    ///
    /// Conformance to this protocol is provided by the `@Generable` macro.
    /// You can provide a manual implementation to map values onto properties using
    /// different names. To manually initialize your type from generated content,
    /// decode the values as shown below:
    ///
    /// ```swift
    /// struct Person: ConvertibleFromGeneratedContent {
    ///     var name: String
    ///     var age: Int
    ///
    ///     init(_ content: GeneratedContent) {
    ///         self.name = try content.value(forProperty: "firstName")
    ///         self.age = try content.value(forProperty: "ageInYears")
    ///     }
    /// }
    /// ```
    ///
    /// - Important: If your type also conforms to ``ConvertibleToGeneratedContent``,
    /// it is critical that this implementation be symmetrical with ``ConvertibleToGeneratedContent/generatedContent``.
    ///
    /// - SeeAlso: `@Generable` macro ``Generable(description:)``
    public init(_ content: GeneratedContent) throws

    /// This instance represented as generated content.
    ///
    /// Conformance to this protocol is provided by the `@Generable` macro.
    /// You can provide a manual implementation to map values onto properties using
    /// different names. Use the generated content property as shown below, to
    /// manually return a new ``GeneratedContent`` with the properties you specify.
    ///
    /// ```swift
    /// struct Person: ConvertibleToGeneratedContent {
    ///    var name: String
    ///    var age: Int
    ///
    ///    var generatedContent: GeneratedContent {
    ///        GeneratedContent(properties: [
    ///            "firstName": name,
    ///            "ageInYears": age
    ///        ])
    ///    }
    /// }
    /// ```
    ///
    /// - Important: If your type also conforms to ``ConvertibleFromGeneratedContent``,
    /// it is critical that this implementation be symmetrical with ``ConvertibleFromGeneratedContent/init(_:)``.
    public var generatedContent: GeneratedContent { get }

    /// An instance that represents a prompt.
    public var promptRepresentation: Prompt { get }

    /// An instance that represents the instructions.
    public var instructionsRepresentation: Instructions { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension String : Generable {

    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema { get }

    /// Creates an instance from content generated by a model.
    ///
    /// Conformance to this protocol is provided by the `@Generable` macro.
    /// You can provide a manual implementation to map values onto properties using
    /// different names. To manually initialize your type from generated content,
    /// decode the values as shown below:
    ///
    /// ```swift
    /// struct Person: ConvertibleFromGeneratedContent {
    ///     var name: String
    ///     var age: Int
    ///
    ///     init(_ content: GeneratedContent) {
    ///         self.name = try content.value(forProperty: "firstName")
    ///         self.age = try content.value(forProperty: "ageInYears")
    ///     }
    /// }
    /// ```
    ///
    /// - Important: If your type also conforms to ``ConvertibleToGeneratedContent``,
    /// it is critical that this implementation be symmetrical with ``ConvertibleToGeneratedContent/generatedContent``.
    ///
    /// - SeeAlso: `@Generable` macro ``Generable(description:)``
    public init(_ content: GeneratedContent) throws

    /// This instance represented as generated content.
    ///
    /// Conformance to this protocol is provided by the `@Generable` macro.
    /// You can provide a manual implementation to map values onto properties using
    /// different names. Use the generated content property as shown below, to
    /// manually return a new ``GeneratedContent`` with the properties you specify.
    ///
    /// ```swift
    /// struct Person: ConvertibleToGeneratedContent {
    ///    var name: String
    ///    var age: Int
    ///
    ///    var generatedContent: GeneratedContent {
    ///        GeneratedContent(properties: [
    ///            "firstName": name,
    ///            "ageInYears": age
    ///        ])
    ///    }
    /// }
    /// ```
    ///
    /// - Important: If your type also conforms to ``ConvertibleFromGeneratedContent``,
    /// it is critical that this implementation be symmetrical with ``ConvertibleFromGeneratedContent/init(_:)``.
    public var generatedContent: GeneratedContent { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Int : Generable {

    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema { get }

    /// Creates an instance from content generated by a model.
    ///
    /// Conformance to this protocol is provided by the `@Generable` macro.
    /// You can provide a manual implementation to map values onto properties using
    /// different names. To manually initialize your type from generated content,
    /// decode the values as shown below:
    ///
    /// ```swift
    /// struct Person: ConvertibleFromGeneratedContent {
    ///     var name: String
    ///     var age: Int
    ///
    ///     init(_ content: GeneratedContent) {
    ///         self.name = try content.value(forProperty: "firstName")
    ///         self.age = try content.value(forProperty: "ageInYears")
    ///     }
    /// }
    /// ```
    ///
    /// - Important: If your type also conforms to ``ConvertibleToGeneratedContent``,
    /// it is critical that this implementation be symmetrical with ``ConvertibleToGeneratedContent/generatedContent``.
    ///
    /// - SeeAlso: `@Generable` macro ``Generable(description:)``
    public init(_ content: GeneratedContent) throws

    /// This instance represented as generated content.
    ///
    /// Conformance to this protocol is provided by the `@Generable` macro.
    /// You can provide a manual implementation to map values onto properties using
    /// different names. Use the generated content property as shown below, to
    /// manually return a new ``GeneratedContent`` with the properties you specify.
    ///
    /// ```swift
    /// struct Person: ConvertibleToGeneratedContent {
    ///    var name: String
    ///    var age: Int
    ///
    ///    var generatedContent: GeneratedContent {
    ///        GeneratedContent(properties: [
    ///            "firstName": name,
    ///            "ageInYears": age
    ///        ])
    ///    }
    /// }
    /// ```
    ///
    /// - Important: If your type also conforms to ``ConvertibleFromGeneratedContent``,
    /// it is critical that this implementation be symmetrical with ``ConvertibleFromGeneratedContent/init(_:)``.
    public var generatedContent: GeneratedContent { get }

    /// An instance that represents a prompt.
    public var promptRepresentation: Prompt { get }

    /// An instance that represents the instructions.
    public var instructionsRepresentation: Instructions { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Float : Generable {

    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema { get }

    /// Creates an instance from content generated by a model.
    ///
    /// Conformance to this protocol is provided by the `@Generable` macro.
    /// You can provide a manual implementation to map values onto properties using
    /// different names. To manually initialize your type from generated content,
    /// decode the values as shown below:
    ///
    /// ```swift
    /// struct Person: ConvertibleFromGeneratedContent {
    ///     var name: String
    ///     var age: Int
    ///
    ///     init(_ content: GeneratedContent) {
    ///         self.name = try content.value(forProperty: "firstName")
    ///         self.age = try content.value(forProperty: "ageInYears")
    ///     }
    /// }
    /// ```
    ///
    /// - Important: If your type also conforms to ``ConvertibleToGeneratedContent``,
    /// it is critical that this implementation be symmetrical with ``ConvertibleToGeneratedContent/generatedContent``.
    ///
    /// - SeeAlso: `@Generable` macro ``Generable(description:)``
    public init(_ content: GeneratedContent) throws

    /// This instance represented as generated content.
    ///
    /// Conformance to this protocol is provided by the `@Generable` macro.
    /// You can provide a manual implementation to map values onto properties using
    /// different names. Use the generated content property as shown below, to
    /// manually return a new ``GeneratedContent`` with the properties you specify.
    ///
    /// ```swift
    /// struct Person: ConvertibleToGeneratedContent {
    ///    var name: String
    ///    var age: Int
    ///
    ///    var generatedContent: GeneratedContent {
    ///        GeneratedContent(properties: [
    ///            "firstName": name,
    ///            "ageInYears": age
    ///        ])
    ///    }
    /// }
    /// ```
    ///
    /// - Important: If your type also conforms to ``ConvertibleFromGeneratedContent``,
    /// it is critical that this implementation be symmetrical with ``ConvertibleFromGeneratedContent/init(_:)``.
    public var generatedContent: GeneratedContent { get }

    /// An instance that represents a prompt.
    public var promptRepresentation: Prompt { get }

    /// An instance that represents the instructions.
    public var instructionsRepresentation: Instructions { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Double : Generable {

    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema { get }

    /// Creates an instance from content generated by a model.
    ///
    /// Conformance to this protocol is provided by the `@Generable` macro.
    /// You can provide a manual implementation to map values onto properties using
    /// different names. To manually initialize your type from generated content,
    /// decode the values as shown below:
    ///
    /// ```swift
    /// struct Person: ConvertibleFromGeneratedContent {
    ///     var name: String
    ///     var age: Int
    ///
    ///     init(_ content: GeneratedContent) {
    ///         self.name = try content.value(forProperty: "firstName")
    ///         self.age = try content.value(forProperty: "ageInYears")
    ///     }
    /// }
    /// ```
    ///
    /// - Important: If your type also conforms to ``ConvertibleToGeneratedContent``,
    /// it is critical that this implementation be symmetrical with ``ConvertibleToGeneratedContent/generatedContent``.
    ///
    /// - SeeAlso: `@Generable` macro ``Generable(description:)``
    public init(_ content: GeneratedContent) throws

    /// This instance represented as generated content.
    ///
    /// Conformance to this protocol is provided by the `@Generable` macro.
    /// You can provide a manual implementation to map values onto properties using
    /// different names. Use the generated content property as shown below, to
    /// manually return a new ``GeneratedContent`` with the properties you specify.
    ///
    /// ```swift
    /// struct Person: ConvertibleToGeneratedContent {
    ///    var name: String
    ///    var age: Int
    ///
    ///    var generatedContent: GeneratedContent {
    ///        GeneratedContent(properties: [
    ///            "firstName": name,
    ///            "ageInYears": age
    ///        ])
    ///    }
    /// }
    /// ```
    ///
    /// - Important: If your type also conforms to ``ConvertibleFromGeneratedContent``,
    /// it is critical that this implementation be symmetrical with ``ConvertibleFromGeneratedContent/init(_:)``.
    public var generatedContent: GeneratedContent { get }

    /// An instance that represents a prompt.
    public var promptRepresentation: Prompt { get }

    /// An instance that represents the instructions.
    public var instructionsRepresentation: Instructions { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Decimal : Generable {

    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema { get }

    /// Creates an instance from content generated by a model.
    ///
    /// Conformance to this protocol is provided by the `@Generable` macro.
    /// You can provide a manual implementation to map values onto properties using
    /// different names. To manually initialize your type from generated content,
    /// decode the values as shown below:
    ///
    /// ```swift
    /// struct Person: ConvertibleFromGeneratedContent {
    ///     var name: String
    ///     var age: Int
    ///
    ///     init(_ content: GeneratedContent) {
    ///         self.name = try content.value(forProperty: "firstName")
    ///         self.age = try content.value(forProperty: "ageInYears")
    ///     }
    /// }
    /// ```
    ///
    /// - Important: If your type also conforms to ``ConvertibleToGeneratedContent``,
    /// it is critical that this implementation be symmetrical with ``ConvertibleToGeneratedContent/generatedContent``.
    ///
    /// - SeeAlso: `@Generable` macro ``Generable(description:)``
    public init(_ content: GeneratedContent) throws

    /// This instance represented as generated content.
    ///
    /// Conformance to this protocol is provided by the `@Generable` macro.
    /// You can provide a manual implementation to map values onto properties using
    /// different names. Use the generated content property as shown below, to
    /// manually return a new ``GeneratedContent`` with the properties you specify.
    ///
    /// ```swift
    /// struct Person: ConvertibleToGeneratedContent {
    ///    var name: String
    ///    var age: Int
    ///
    ///    var generatedContent: GeneratedContent {
    ///        GeneratedContent(properties: [
    ///            "firstName": name,
    ///            "ageInYears": age
    ///        ])
    ///    }
    /// }
    /// ```
    ///
    /// - Important: If your type also conforms to ``ConvertibleFromGeneratedContent``,
    /// it is critical that this implementation be symmetrical with ``ConvertibleFromGeneratedContent/init(_:)``.
    public var generatedContent: GeneratedContent { get }

    /// An instance that represents a prompt.
    public var promptRepresentation: Prompt { get }

    /// An instance that represents the instructions.
    public var instructionsRepresentation: Instructions { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Array : Generable where Element : Generable {

    /// A representation of partially generated content, as an array of partially generated elements.
    public typealias PartiallyGenerated = [Element.PartiallyGenerated]

    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Array : ConvertibleToGeneratedContent where Element : ConvertibleToGeneratedContent {

    /// This instance represented as generated content.
    ///
    /// Conformance to this protocol is provided by the `@Generable` macro.
    /// You can provide a manual implementation to map values onto properties using
    /// different names. Use the generated content property as shown below, to
    /// manually return a new ``GeneratedContent`` with the properties you specify.
    ///
    /// ```swift
    /// struct Person: ConvertibleToGeneratedContent {
    ///    var name: String
    ///    var age: Int
    ///
    ///    var generatedContent: GeneratedContent {
    ///        GeneratedContent(properties: [
    ///            "firstName": name,
    ///            "ageInYears": age
    ///        ])
    ///    }
    /// }
    /// ```
    ///
    /// - Important: If your type also conforms to ``ConvertibleFromGeneratedContent``,
    /// it is critical that this implementation be symmetrical with ``ConvertibleFromGeneratedContent/init(_:)``.
    public var generatedContent: GeneratedContent { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Array : ConvertibleFromGeneratedContent where Element : ConvertibleFromGeneratedContent {

    /// Creates an instance from content generated by a model.
    ///
    /// Conformance to this protocol is provided by the `@Generable` macro.
    /// You can provide a manual implementation to map values onto properties using
    /// different names. To manually initialize your type from generated content,
    /// decode the values as shown below:
    ///
    /// ```swift
    /// struct Person: ConvertibleFromGeneratedContent {
    ///     var name: String
    ///     var age: Int
    ///
    ///     init(_ content: GeneratedContent) {
    ///         self.name = try content.value(forProperty: "firstName")
    ///         self.age = try content.value(forProperty: "ageInYears")
    ///     }
    /// }
    /// ```
    ///
    /// - Important: If your type also conforms to ``ConvertibleToGeneratedContent``,
    /// it is critical that this implementation be symmetrical with ``ConvertibleToGeneratedContent/generatedContent``.
    ///
    /// - SeeAlso: `@Generable` macro ``Generable(description:)``
    public init(_ content: GeneratedContent) throws
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Never : Generable {

    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema { get }

    /// Creates an instance from content generated by a model.
    ///
    /// Conformance to this protocol is provided by the `@Generable` macro.
    /// You can provide a manual implementation to map values onto properties using
    /// different names. To manually initialize your type from generated content,
    /// decode the values as shown below:
    ///
    /// ```swift
    /// struct Person: ConvertibleFromGeneratedContent {
    ///     var name: String
    ///     var age: Int
    ///
    ///     init(_ content: GeneratedContent) {
    ///         self.name = try content.value(forProperty: "firstName")
    ///         self.age = try content.value(forProperty: "ageInYears")
    ///     }
    /// }
    /// ```
    ///
    /// - Important: If your type also conforms to ``ConvertibleToGeneratedContent``,
    /// it is critical that this implementation be symmetrical with ``ConvertibleToGeneratedContent/generatedContent``.
    ///
    /// - SeeAlso: `@Generable` macro ``Generable(description:)``
    public init(_ content: GeneratedContent) throws

    /// This instance represented as generated content.
    ///
    /// Conformance to this protocol is provided by the `@Generable` macro.
    /// You can provide a manual implementation to map values onto properties using
    /// different names. Use the generated content property as shown below, to
    /// manually return a new ``GeneratedContent`` with the properties you specify.
    ///
    /// ```swift
    /// struct Person: ConvertibleToGeneratedContent {
    ///    var name: String
    ///    var age: Int
    ///
    ///    var generatedContent: GeneratedContent {
    ///        GeneratedContent(properties: [
    ///            "firstName": name,
    ///            "ageInYears": age
    ///        ])
    ///    }
    /// }
    /// ```
    ///
    /// - Important: If your type also conforms to ``ConvertibleFromGeneratedContent``,
    /// it is critical that this implementation be symmetrical with ``ConvertibleFromGeneratedContent/init(_:)``.
    public var generatedContent: GeneratedContent { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension String : InstructionsRepresentable {

    /// An instance that represents the instructions.
    public var instructionsRepresentation: Instructions { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Array : InstructionsRepresentable where Element : InstructionsRepresentable {

    /// An instance that represents the instructions.
    public var instructionsRepresentation: Instructions { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension String : PromptRepresentable {

    /// An instance that represents a prompt.
    public var promptRepresentation: Prompt { get }
}

@available(iOS 26.0, macOS 26.0, watchOS 27.0, tvOS 27.0, *)
extension Array : PromptRepresentable where Element : PromptRepresentable {

    /// An instance that represents a prompt.
    public var promptRepresentation: Prompt { get }
}


// MARK: - UIKit Additions

import UIKit

// Available when UIKit is imported with FoundationModels
@available(iOS 27.0, watchOS 27.0, *)
@available(tvOS, unavailable)
extension Attachment where Content == ImageAttachmentContent {

    public init(_ uiImage: UIImage, orientation: UIImage.Orientation? = nil)
}

