# FMBench Methodology

## Design Principles

FMBench follows seven rules:

1. Evaluate deployment-shaped scenarios rather than a single generic prompt.
2. Keep quality, latency, and resource context as separate measurements.
3. Prefer deterministic, inspectable graders whenever an answer can be verified.
4. Report distributions and failures, not only successful averages.
5. Preserve the complete fixture, response, environment, OS build, and timestamp.
6. Separate common OS 26/27 workloads from OS 27-only capability tests.
7. Keep safety trigger tests separate from general app-quality scores.

These rules draw from:

- [HELM](https://arxiv.org/abs/2211.09110): scenario and metric coverage, standardized conditions, and explicit incompleteness.
- [IFEval](https://arxiv.org/abs/2311.07911): interpretable verifiable instructions plus prompt-level and instruction-level accuracy.
- [BFCL](https://proceedings.mlr.press/v267/patil25a.html): structural evaluation for tool and function calls.
- [RULER](https://arxiv.org/abs/2404.06654): configurable task complexity and context length beyond simple retrieval.
- [G-Eval](https://arxiv.org/abs/2303.16634): rubric-based subjective evaluation and documented evaluator bias.
- [MT-Bench and Chatbot Arena](https://arxiv.org/abs/2306.05685): human preference, judge agreement, and position/verbosity/self-enhancement biases.
- [Mobile LLM inference benchmarking](https://arxiv.org/abs/2410.03613): user-facing latency, energy, and system-state concerns on mobile hardware.
- [Metron](https://arxiv.org/abs/2407.07000): token delivery stalls can be hidden by aggregate throughput.
- [MLPerf Client](https://mlcommons.org/benchmarks/client/): TTFT and post-first-token generation rate as separate client metrics.
- Apple’s [2024 AFM report](https://arxiv.org/abs/2407.21075) and
  [2025 AFM report](https://arxiv.org/abs/2507.13575): public benchmarks,
  human evaluation, feature-specific evaluation, and quality regression checks after optimization.

## Quality Scoring

Each fixture has deterministic checks such as:

- Exact generated fields.
- Required and forbidden text.
- Semantically required array members.
- Maximum or minimum word count.
- Exact source citations.
- Expected tool selection and typed arguments.

Guided generation schema conformance is not scored as quality. The framework enforces
the JSON shape, property types, enum choices, and schema-level array bounds during
decoding. FMBench records guided generation as the execution mode, then grades only
whether the generated values solve the task. For example, an allowed category can
still be the wrong category, and a well-formed citation array can cite the wrong note.

FMBench reports two quality values:

- **Constraint score:** checks passed divided by total checks.
- **Prompt pass:** true only when every check passes.

This mirrors IFEval’s distinction between instruction-level and prompt-level accuracy.
The prompt pass rate is intentionally strict because a production action can fail when
only one required field is wrong.

Subjective model judging is intentionally absent from the portable runner. The
macOS 27 `FMBenchReplayEvaluation` converts recorded trials into Apple Evaluations
`ModelSample`, custom `Evaluator`, and native `ToolCallEvaluator` values without
running the model again. Future rubrics for tone, fluency, or usefulness should:

- Use a frozen judge and rubric version.
- Grade responses independently before pairwise comparison.
- Swap pairwise response order.
- Retain judge explanations and raw outputs.
- Be calibrated periodically against human ratings.

The Evaluations package is deliberately separate from `FMBenchCore`. It is a
developer/test dependency inside Xcode 27, not an iOS benchmark or shipping-app
dependency. See [FMBench and Apple Evaluations](EVALUATIONS.md).

## Safety Guardrails

The guardrail suite pairs two deterministic expectations:

- `mustRespond`: a legitimate transformation must complete without an explicit
  guardrail violation or refusal.
- `mustProtect`: an unsafe request must produce an explicit guardrail violation or
  a clear refusal.

FMBench uses `SystemLanguageModel.Guardrails.default` explicitly. It records normal
responses, framework guardrail violations, and refusals separately. A false positive
or missed protection is a critical safety failure and causes the CLI to exit nonzero.

These checks measure observable behavior, not the internal policy category that caused
a block. Refusal detection uses a small transparent phrase matcher and should be
reviewed alongside the preserved response text.

## Performance Scoring

For each request:

- `TTFT = first stream update - request start`
- `decode duration = final update - first stream update`
- `output tokens/sec = (final output tokens - first snapshot tokens) / decode duration`
- `end-to-end duration = final update - request start`

Prompt tokens are never included in output throughput.

On OS 27, FMBench prefers the per-response `LanguageModelSession.Usage` values for
input, output, and reasoning tokens. On OS 26.4 and later, on-device runs use
`SystemLanguageModel.tokenCount(for:)` for instructions, prompts, schemas, and
responses. Each trial records `tokenCountSource: systemTokenizer`.

Earlier on-device systems and PCC runs use estimates calibrated from prior
Foundation Models Instruments traces because the public tokenizer API belongs to
`SystemLanguageModel`. Those trials record
`tokenCountSource: characterEstimate`. Characters per second remains a
tokenizer-independent secondary measurement.

Stream snapshots are not guaranteed to map one-to-one to tokens. Consequently,
FMBench calls their timing **stream update gaps**, not inter-token latency.
The first snapshot can contain multiple tokens, so FMBench excludes every token
already present in that snapshot rather than assuming it contains one token.

## Experiment Protocol

### Authoritative Runners

- **Mac:** run `FMBenchCLI` through `swift run fmbench` or
  `./Tools/FMBench/fmbench`. This is the only authoritative surface for publishable
  macOS results.
- **iPhone and iPad:** run `FMBenchDeviceRunner` on a physical Apple Intelligence
  device. iOS requires a signed application container; the runner exists only to host
  the shared benchmark core and export its results.
- **Simulator:** use only for compilation, interface, and workflow validation.
  Simulator output must never be reported as device benchmark evidence.

The runners share `FMBenchCore`, fixtures, grading, metrics, and report generation.
The device runner is not a separate benchmark methodology.

For publishable comparisons:

1. Reboot or otherwise establish the same starting state.
2. Disconnect external displays and power-hungry peripherals when possible.
3. Record charging state, Low Power Mode, thermal state, and network.
4. Run five warmups.
5. Run at least twenty measured repetitions per sample.
6. Randomize workload/sample order with a recorded seed.
7. Stop and cool the device if the thermal state reaches serious or critical.
8. Keep input fixtures, generation options, and FMBench commit identical.
9. Report all execution failures.
10. Keep cold-session and warm-session results separate.
11. Compare median and p90, not the single fastest run.
12. Run the full 25-sample corpus for a publishable quality comparison.

For public reports, set `FMBENCH_DEVICE_NAME` to a generic label such as
`MacBook Pro M5`. FMBench never needs the machine hostname.

The quick suite defaults to one sample per workload so iteration remains practical.
Use `--all-samples` to run its complete per-workload corpus without assuming a fixed
sample count. The full suite runs all 25 samples per workload unless `--samples`
limits it. One repetition is acceptable for exploratory development but must not be
presented as a stable device ranking.

## OS Comparisons

An OS comparison requires the same hardware. A Mac-versus-iPhone comparison is a
device comparison even when both run the same OS generation.

OS 26 and OS 27 results can differ because of:

- Foundation model weights.
- Framework behavior.
- Compiler and SDK behavior.
- Runtime scheduling and memory management.
- Guided-generation implementation.
- Tool-calling behavior.
- Thermal and power policies.

The report therefore records the OS build, not only the major version.

The visual workload is OS 27-only and is not part of the common OS comparison. A
strict OS 26 versus OS 27 comparison must select only workloads available on both.

## PCC Comparisons

PCC is a service benchmark:

- Record connection type and approximate location separately.
- Run enough repetitions to expose network variance.
- Keep PCC reasoning configuration fixed.
- Timestamp results because the server model can change independently.
- Never combine PCC throughput with on-device throughput in a single device ranking.
- Record quota and availability failures instead of dropping them.
- Run fallback enabled and disabled as separate configurations.

Apple's PCC quota API exposes below-limit, approaching-limit, limit-reached, and reset
state. It does not expose a numeric quota-consumption counter, so FMBench records the
state before and after rather than inventing a consumption value.

FMBench does not change device radios. Before a `--connectivity offline` run, the
operator must disable Wi-Fi and cellular connectivity. FMBench observes the system
network path at run start and refuses the experiment unless no active path is
available. It marks offline success only after that check and only when the executed
model is on-device.

PCC requires OS 27, an Apple Intelligence-capable device with Apple Intelligence
enabled, service availability, and Apple’s managed entitlement.

## Known Limitations

- Each workload has five semantic cases expressed through five prompt phrasings; this
  is useful for regression testing but not statistically representative of every app.
- PCC and pre-26.4 token counts are estimated without Instruments.
- Energy use is not yet sampled directly.
- Peak memory is the highest process resident-memory sample observed at request start,
  stream updates, and request end, not a continuous system-wide peak.
- Snapshot timing cannot provide true token-level jitter.
- The practical scenarios are English-only.
- Deterministic checks measure specified requirements, not every aspect of usefulness.
- PCC cannot be reproduced without entitlement and stable network conditions.
- The synthetic visual fixture tests image grounding, not broad real-world vision.
