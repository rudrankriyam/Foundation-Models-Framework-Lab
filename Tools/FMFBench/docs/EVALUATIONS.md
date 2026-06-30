# FMFBench and Apple Evaluations

FMFBench uses Apple’s Evaluations framework as a **macOS 27 evaluation control
plane**, not as the benchmark runner and not as an iOS application dependency.

This integration was verified with Xcode 27 beta build `27A5194q` on macOS 27
build `26A5353q`.

## Recommendation

Keep the responsibilities separate:

1. `FMFBenchCore` runs deployment-shaped workloads and records portable JSON.
2. The macOS-only `FMFBenchEvaluations` package replays those recorded responses
   through deterministic Evaluations metrics.
3. The FMFBench-specific `fmfbench-evaluate` command creates native
   `.xcevalresult` files.
4. The standalone, generic
   [`xceval`](https://github.com/rudrankriyam/Evaluations-Framework-CLI) CLI
   runs the complete replay pipeline and inspects, reports, streams, compares,
   and exports those artifacts for automation.
5. Xcode and Swift Testing remain available when a human wants the native report
   UI or a test should attach an evaluation result.

The replay step does **not** call the language model again. Re-running a model
would produce a different response and would detach the quality result from the
TTFT, throughput, thermal, memory, fallback, and device evidence captured by the
original FMFBench trial.

Apple makes Evaluations available on macOS, iOS, watchOS, and visionOS 27, with
tvOS unavailable. FMFBench’s macOS-only boundary is an intentional product and
tooling decision, not a claim that Apple lacks other platform binaries. The
shipping signed runner continues to use only `FMFBenchCore` on iOS and macOS.

## Data Flow

```text
FMFBench runner
  |
  | portable FMFBench JSON
  v
fmfbench-evaluate replay (macOS 27)
  |
  | Evaluation.run(info:)
  v
.xcevalresult JSON
  |                             \
  | xceval pipeline/report       \ Swift Testing .evaluates
  | xceval compare                v
  v                          .xcresult attachment
agent-readable JSON               |
                                  | xceval export
                                  | (xcresulttool export evaluations)
                                  v
                             .xcevalresult + manifest.json
```

## Xcode Framework Folders

Several folders named `Frameworks` exist inside Xcode or a project. They do not
mean the same thing.

| Location | Meaning | Use it? |
| --- | --- | --- |
| `Xcode.app/Contents/Developer/Platforms/<Platform>.platform/Developer/Library/Frameworks/Evaluations.framework` | Public Evaluations developer framework and Swift interface | Yes, from macOS 27 evaluation/test tooling |
| `Xcode.app/Contents/Frameworks/IDEEvaluationKit.framework` | Private Xcode IDE implementation detail | No |
| `Xcode.app/Contents/SharedFrameworks/MLEvaluation*.framework` | Other private/legacy ML evaluation support | No |
| `<Platform>.sdk/System/Library/Frameworks` | Frameworks shipped by the OS SDK | Evaluations is not located here |
| An Xcode project’s `Frameworks` group or link phase | Project metadata, not a filesystem framework repository | Do not confuse it with the developer framework path |
| A built app’s `Contents/Frameworks` or `Frameworks` directory | Embedded runtime dependencies | Do not embed Evaluations in a shipping app |

The FMFBench package manifest adds the developer framework search path and an Xcode
`Contents` runpath. `Tools/FMFBench/fmfbench-evaluate` discovers Xcode installations
under `/Applications`, `~/Applications`, and `~/Downloads`, or honors an explicit
`DEVELOPER_DIR`. The standalone `xceval` binary does not link the framework.

## What Apple Stores

### Direct runs

`Evaluation.run(info:)` returns `EvaluationResult`. Calling
`saveJSON(to:includeReportMetadata:)` writes a plain JSON file with the
`.xcevalresult` extension.

The Xcode 27 beta result contains these top-level keys:

- `evaluationID`
- `resultID`
- `startTime`
- `endTime`
- `durationInMilliseconds`
- `evaluationInfo`
- `reportMetadata`
- `results`
- `summary`

Each result row contains serialized input, response, expected value, and one
entry per metric. Metric entries record their evaluator kind, pass/fail/score/
ignore kind, numeric or Boolean value, and optional rationale.

FMFBench keeps its internal record ID in the serialized input sample and leaves
the framework's `Expected` column empty. FMFBench workloads usually express
expected behavior as constraints and tool trajectories rather than one exact
response. Storing the record UUID as `Expected` would make Xcode and generic
reporting tools show a false subject-versus-expected mismatch on every row.

The `Input` column is itself a JSON string containing the model sample input and
expected output metadata. Consumers must decode it a second time if they need the
prompt fields.

### Swift Testing and Xcode

The `.evaluates` Swift Testing trait attaches an `.xcevalresult` file to the test.
Xcode stores that attachment inside the test’s `.xcresult` bundle.

Xcode 27 exposes the following command:

```bash
xcrun xcresulttool export evaluations \
  --path Tests.xcresult \
  --output-path ExportedEvaluations
```

The export directory contains:

- One or more `.xcevalresult` JSON files.
- `manifest.json`, currently a JSON array of test records and their attachments.
- Test identifiers, destination/configuration metadata, attachment names,
  timestamps, and failure association.

`xcresulttool export evaluations --schema` reports `0.4.0` as the default
export schema version in the tested beta. That version is command metadata; the
emitted `manifest.json` does not currently include a `schemaVersion` field.

`--test-id` narrows the export and `--only-failures` exports only attachments
associated with failed tests.

## Public Framework Surface

The public Xcode 27 interface includes:

- `Evaluation`, `Evaluation.run(info:)`, and the `.evaluates` test trait.
- `ModelSample`, `ArrayLoader`, `JSONLoader`, and `StreamLoader`.
- Custom `Evaluator` values and pass, fail, score, or ignore `Metric` values.
- `MetricsAggregator` groups with mean, median, extrema, variance, and custom
  aggregation.
- `EvaluationResult` summary and detailed DataFrames plus JSON and JSON Lines
  persistence.
- `StructuredTranscript` and `Transcript.structuredTranscript`.
- `TrajectoryExpectation`, `ToolExpectation`, argument matchers, and
  `ToolCallEvaluator`.
- `ModelJudgeEvaluator`, score dimensions, pairwise judging, and judge prompts.
- `SampleGenerator` with session providers, sampling strategies, validation,
  accepted samples, and rejected samples.

FMFBench uses deterministic evaluators and native tool trajectory evaluation as
the primary replay artifact. When explicitly requested, `fmfbench-evaluate` also
writes a separate subjective-quality artifact that uses
`PrivateCloudComputeLanguageModel` as a model judge for successful,
deterministic-passing, non-safety responses. The judge scores genuinely
subjective criteria and should still be calibrated against human ratings before
its aggregate scores are treated as release evidence.

## Command-Line Tools

FMFBench owns only the producer command because it understands FMFBench’s portable
result schema and deterministic graders:

```bash
# Convert a recorded FMFBench run into a native evaluation result.
Tools/FMFBench/fmfbench-evaluate replay \
  Tools/FMFBench/Results/run.json \
  --output /tmp/fmfbench-evaluations \
  --format json

# Also write a PCC-judged subjective-quality artifact.
Tools/FMFBench/fmfbench-evaluate replay \
  Tools/FMFBench/Results/run.json \
  --output /tmp/fmfbench-evaluations \
  --judge pcc \
  --format json

# Also write a live PCC judge report through Foundation Lab Agent Bridge.
Tools/FMFBench/fmfbench-evaluate replay \
  Tools/FMFBench/Results/run.json \
  --output /tmp/fmfbench-evaluations \
  --judge bridge-pcc \
  --format json
```

Generic artifact operations live in the public `xceval` repository. It emits a
stable `xceval/v1` JSON envelope, provides JSONL sample streaming for agents, and
can return Apple’s exact JSON document.

```bash
# Verify Xcode and framework discovery, including Xcode in ~/Downloads.
xceval doctor --output json

# Read metadata, aggregate metrics, and every sample row.
xceval inspect \
  /tmp/fmfbench-evaluations/FMFBenchReplayEvaluation-*.xcevalresult \
  --output json

# Recreate the data behind Xcode's report, including distributions and issues.
xceval report result.xcevalresult --output json

# Return only metadata and aggregate metrics.
xceval inspect result.xcevalresult \
  --summary-only \
  --output json

# Stream one normalized result row per line.
xceval samples result.xcevalresult --output jsonl

# Return Apple’s exact JSON document.
xceval inspect result.xcevalresult --output raw-json

# Compute generic aggregate metric deltas.
xceval compare \
  baseline.xcevalresult \
  candidate.xcevalresult \
  --output json

# Export evaluation attachments from an Xcode test result.
xceval export Tests.xcresult \
  --output-path /tmp/exported-evaluations \
  --output json
```

The checked-in pipeline runs the FMFBench replay command and writes one
analysis directory containing the selected native result, logs, validation,
Xcode-style report data, metric profiles, failing samples, and extracted
datasets:

```bash
# FMFBENCH_RESULT is relative to Tools/FMFBench.
xceval pipeline Tools/FMFBench/xceval.pipeline.json \
  --set FMFBENCH_RESULT=Results/run.json \
  --force
```

Add a `baseline` path and explicit `gates` to a local copy of the manifest when
the comparison policy is known. The shared manifest intentionally does not
guess whether a recorded failure, latency change, or PCC attempt should fail a
particular release workflow.

`fmfbench-evaluate replay` accepts both the current FMFBench result schema and the
repository’s historical June 2026 result schema. `xceval compare` reports raw
deltas without assuming whether higher or lower is better; an FMFBench policy
layer can apply metric-specific regression thresholds later.

Warmup failures remain in the portable FMFBench report for diagnostics but are
excluded from Evaluations replay samples. They are setup failures, not measured
benchmark trials, and must not lower the execution-success aggregate.

## Why `xceval` Uses Raw JSON

The framework remains the authority for producing `.xcevalresult` files.
The standalone CLI deliberately parses the JSON artifact directly, matching
Apple’s `DatasetExtractor` sample.

In Xcode 27 beta build `27A5194q`, verification found two round-trip issues in the
convenience APIs:

- `EvaluationResult.loadJSON` rejected one valid result produced by
  `EvaluationResult.saveJSON`.
- `groupedSummary` crashed after loading a valid exported result because a
  TabularData column had an unexpected runtime type.

The on-disk JSON remained valid and complete. A tolerant parser is therefore a
better automation boundary during the beta, while `--output raw-json` preserves
all Apple fields for future schema changes.

## FMFBench Metrics

The replay evaluation keeps execution, quality, latency, throughput, resources,
and safety separate:

- Execution success.
- Deterministic FMFBench prompt pass.
- Deterministic FMFBench constraint score.
- Safety pass where a safety expectation exists.
- Native tool-call all-pass and percentage metrics where tool expectations exist.
- Ordered agentic trajectories, with mocked final-state checks replayed by FMFBench's
  deterministic evaluator.
- Original duration and TTFT.
- Original output tokens per second.
- Original peak resident memory when recorded.

With `--judge pcc`, the additional subjective artifact reports:

- PCC-judged helpfulness.
- PCC-judged clarity.
- PCC-judged completeness.

The subjective artifact is intentionally filtered to deterministic-passing,
non-safety responses. This saves PCC quota and keeps hard failures in the
deterministic report where they belong.

Live PCC judging requires the `fmfbench-evaluate` process to be signed with
`com.apple.developer.private-cloud-compute`. Without that managed entitlement,
the command fails before constructing `PrivateCloudComputeLanguageModel` so the
Apple framework does not terminate the process.

For local terminal smoke tests, `--judge bridge-pcc` uses Foundation Lab's Agent
Bridge instead of constructing PCC in the SwiftPM process. Build and launch the
macOS app with development signing, enable Agent Bridge with `~/.afm` as the
bridge folder, then run replay from Terminal. This writes a FMFBench-owned JSON
report named `FMFBenchBridgeSubjectiveQuality-*.json` with per-sample PCC scores,
rationales, aggregate means, and observed token usage. It is separate from the
native `.xcevalresult` path because the judge inference happens inside the signed
app host.

Metrics with no source values are not aggregated. This avoids meaningless `NaN`
summary values while preserving ignored per-row metrics and their rationales.

## Apple Resources

Framework and design:

- [Evaluations documentation](https://developer.apple.com/documentation/evaluations)
- [Designing effective evaluations](https://developer.apple.com/documentation/evaluations/designing-effective-evaluations)
- [Designing datasets to test your feature](https://developer.apple.com/documentation/evaluations/designing-evaluation-datasets)
- [Evaluating language model responses](https://developer.apple.com/documentation/evaluations/evaluating-language-model-responses)
- [Designing specific, measurable criteria](https://developer.apple.com/documentation/evaluations/designing-evaluation-criteria)
- [Designing effective model-as-judge evaluators](https://developer.apple.com/documentation/evaluations/designing-effective-model-judges)
- [Scoring with model-as-judge evaluators](https://developer.apple.com/documentation/evaluations/scoring-with-model-as-judge-evaluators)
- [Generating synthetic datasets](https://developer.apple.com/documentation/evaluations/generating-synthetic-evaluation-datasets)
- [Evaluating tool-calling behavior](https://developer.apple.com/documentation/evaluations/evaluating-tool-calling-behavior)

WWDC26:

- [Meet the Evaluations framework](https://developer.apple.com/videos/play/wwdc2026/298/)
- [Create robust evaluations for agentic apps](https://developer.apple.com/videos/play/wwdc2026/299/)
- [Improve prompts by hill-climbing evaluations](https://developer.apple.com/videos/play/wwdc2026/335/)
- [What’s new in the Foundation Models framework](https://developer.apple.com/videos/play/wwdc2026/241/)

Sample code:

- [Book Tracker: Using Evaluations to evaluate an intelligent feature](https://developer.apple.com/documentation/evaluations/book-tracker-using-evaluations-to-evaluate-an-intelligent-feature)

Apple’s sample demonstrates deterministic metrics, model judges, tool-call
trajectories, synthetic sample generation, judge calibration, hill climbing, and
a `DatasetExtractor` command-line target that reads `.xcevalresult` as JSON.
