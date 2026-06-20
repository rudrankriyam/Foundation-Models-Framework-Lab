# Benchmark Research Notes

This document records the evaluation literature and Apple material used to
design FMFBench. It is a design audit, not a claim that the starter corpus is a
complete model benchmark.

## Main Conclusion

A useful application benchmark needs three separate views:

1. Did the feature satisfy the app's concrete requirements?
2. How did the response feel to the user in latency and delivery?
3. Under what device, OS, model, thermal, power, and service conditions did it run?

A single accuracy score or tokens-per-second value cannot answer all three.
FMFBench therefore keeps semantic quality, performance, failures, and
environment metadata separate.

## Apple Foundation Model Reports

### Apple Intelligence Foundation Language Models, 2024

[Paper](https://arxiv.org/abs/2407.21075)

Apple evaluates model capability with public benchmarks, internal
feature-shaped tasks, human preference evaluation, safety evaluation, and
efficiency measurements. The important lesson for FMFBench is that the
production feature is the final unit of evaluation. A general model score does
not establish whether a notification summary, rewrite, or app action works.

### Apple Intelligence Foundation Language Models, 2025

[Paper](https://arxiv.org/abs/2507.13575) |
[Apple overview](https://machinelearning.apple.com/research/apple-foundation-models-tech-report-2025)

The 2025 report expands multilingual, multimodal, tool-use, and locale-specific
evaluation. Apple combines public benchmarks and human grading, checks
optimization regressions, and builds targeted safety datasets for tasks such as
summarization and question answering. The report also explicitly positions the
on-device model for bounded app tasks rather than general world-knowledge chat.

FMFBench adopts four lessons:

- Use app-shaped tasks such as extraction, summarization, classification, and
  grounded question answering.
- Retain failures and compare optimized/runtime behavior, not only abstract
  model quality.
- Keep locale expansion and safety-sensitive feature datasets on the roadmap.
- Avoid claiming that a small practical suite measures general intelligence.

### Third-Generation Apple Foundation Models, 2026

[Apple announcement](https://machinelearning.apple.com/research/introducing-third-generation-of-apple-foundation-models)

Apple announced the third model generation on June 8, 2026, spanning
on-device and Private Cloud Compute models. Apple says updated evaluations and
benchmarks will arrive in a technical report later in 2026. Until that report
exists, FMFBench should identify the exact OS build and observed runtime
behavior instead of inventing a public model-version label.

## General Evaluation Research

### HELM

[Holistic Evaluation of Language Models](https://arxiv.org/abs/2211.09110)

HELM argues for scenario coverage, multiple metrics, standardized conditions,
raw-output transparency, and explicit disclosure of what is missing. FMFBench
uses named scenarios, separate quality and efficiency metrics, environment
snapshots, raw responses, and a limitations section for the same reasons.

### IFEval

[Instruction-Following Evaluation for Large Language Models](https://arxiv.org/abs/2311.07911)

IFEval uses objectively verifiable instructions and distinguishes individual
instruction accuracy from strict prompt-level accuracy. FMFBench mirrors this
with constraint score and prompt pass. This is especially appropriate for app
actions where one wrong date, category, source, or required fact can invalidate
an otherwise fluent response.

### Berkeley Function Calling Leaderboard

[BFCL](https://proceedings.mlr.press/v267/patil25a.html)

BFCL treats tool choice and arguments as executable behavior rather than prose.
FMFBench's grounded explanation and exercise substitution workloads execute
real deterministic tools and grade the selected tool plus typed arguments.
Call-order, state-change, and recovery datasets remain future extensions.

### RULER

[RULER](https://arxiv.org/abs/2404.06654)

RULER shows that long-context evaluation should vary task complexity and
context length instead of relying on a single retrieval pattern. FMFBench now
includes a deterministic key-retrieval context suite and records context
utilization. A publishable long-context study should still sweep document
count, distractors, answer position, and utilization.

### G-Eval

[G-Eval](https://arxiv.org/abs/2303.16634)

G-Eval demonstrates rubric-based model grading for subjective text quality.
It also reinforces that judge prompts and model choice are part of the
experiment. FMFBench starts with deterministic checks. Any future model judge
must be versioned, retain rationales, and be calibrated against human labels.

### MT-Bench and Chatbot Arena

[Paper](https://arxiv.org/abs/2306.05685)

This work studies human preference and LLM-as-a-judge evaluation, including
position, verbosity, and self-enhancement biases. For FMFBench, pairwise judges
should swap response order, avoid treating longer answers as automatically
better, and report agreement with human raters.

## Client Performance Research

### Mobile LLM Performance Benchmarking

[Paper](https://arxiv.org/abs/2410.03613)

Mobile inference quality is inseparable from latency, battery, resource use,
and dynamic hardware behavior. FMFBench records hardware, OS build, thermal
state, total memory, observed resident memory, and Low Power Mode. Direct energy
and utilization sampling remain future work.

### Metron

[Paper](https://arxiv.org/abs/2407.07000)

Aggregate throughput can hide stalls in token delivery. FMFBench therefore
records cumulative stream-update timing and the maximum gap, while avoiding the
false claim that each Foundation Models snapshot equals one token.

### MLPerf Client

[Benchmark](https://mlcommons.org/benchmarks/client/)

MLPerf Client separates time to first token from generation rate. FMFBench does
the same and excludes all tokens present in the first cumulative stream snapshot
from decode throughput.

## Apple Evaluations Framework

[Meet the Evaluations framework](https://developer.apple.com/videos/play/wwdc2026/298/) |
[Create robust evaluations for agentic apps](https://developer.apple.com/videos/play/wwdc2026/299/)

Apple's OS 27 Evaluations framework provides datasets, per-sample evaluators,
metrics, aggregation, Swift Testing integration, Xcode reports, synthetic sample
generation, and model judges. It is the right home for deep feature-quality
evaluation in an OS 27-only app.

FMFBench is complementary:

- It keeps an OS 26-compatible runner.
- It captures TTFT, decode rate, stream gaps, thermals, power state, hardware,
  OS build, and raw portable JSON.
- It compares physical devices and PCC service behavior outside an Xcode test
  report.
- Its macOS 27 replay package produces Evaluations `ModelSample`, deterministic
  `Evaluator`, and native `ToolCallEvaluator` values from recorded responses.
- The standalone `xceval` CLI reads, streams, compares, and extracts generic
  `.xcevalresult` JSON without requiring the Xcode report UI or FMFBench code.

The two systems should share datasets and grading definitions, not duplicate
truth in two unrelated corpora.

See [FMFBench and Apple Evaluations](EVALUATIONS.md) for the full Apple resource
inventory, Xcode folder disambiguation, result schema, producer/consumer boundary,
and verified Xcode 27 beta behavior.

## Safety Trigger Design

FMFBench's safety suite follows a general evaluation principle: test both expected
triggers and closely related expected non-triggers. This exposes false positives as
well as missed protection. Safety outcomes are deterministic ship-blocking signals;
they are not averaged away by latency or subjective quality scores.

The suite uses newly authored, domain-neutral fixtures and Apple's default Foundation
Models guardrails.

## Deliberate Non-Tests

Guided-generation structure is not a quality test in FMFBench. Foundation
Models constrains the output during decoding, so testing whether the resulting
JSON has the requested schema mostly tests the framework contract. FMFBench
instead tests whether the constrained values are semantically correct.

The benchmark also avoids a single composite score. Quality, latency, service
availability, and resource behavior have different meanings and should remain
inspectable.
