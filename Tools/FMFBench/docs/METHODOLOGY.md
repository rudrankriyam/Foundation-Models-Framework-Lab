# FMFBench Methodology

## Design Principles

FMFBench follows seven rules:

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
decoding. FMFBench records guided generation as the execution mode, then grades only
whether the generated values solve the task. For example, an allowed category can
still be the wrong category, and a well-formed citation array can cite the wrong note.

FMFBench reports two quality values:

- **Constraint score:** checks passed divided by total checks.
- **Prompt pass:** true only when every check passes.

This mirrors IFEval’s distinction between instruction-level and prompt-level accuracy.
The prompt pass rate is intentionally strict because a production action can fail when
only one required field is wrong.

Subjective model judging is intentionally absent from the portable runner. The
macOS 27 replay layer converts recorded trials into Apple Evaluations
`ModelSample`, custom `Evaluator`, and native `ToolCallEvaluator` values without
running the measured model again. When `fmfbench-evaluate replay --judge pcc` is
used, a separate subjective-quality artifact uses `PrivateCloudComputeLanguageModel`
as the judge for successful, deterministic-passing, non-safety responses only.
Rubrics for tone, fluency, usefulness, or other subjective dimensions should:

- Use a frozen judge and rubric version.
- Grade responses independently before pairwise comparison.
- Swap pairwise response order.
- Retain judge explanations and raw outputs.
- Be calibrated periodically against human ratings.

The Evaluations package is deliberately separate from `FMFBenchCore`. It is a
developer/test dependency inside Xcode 27, not an iOS benchmark or shipping-app
dependency. See [FMFBench and Apple Evaluations](EVALUATIONS.md).

## Real App Experiences

The Real App Experiences suite (`--suite apps`) converts Apple's public
Foundation Models Framework app examples into original, repeatable benchmark
fixtures. The suite covers the same product shapes rather than the exact app data:
workout adaptation, journal reflection, sports coaching feedback, exercise
substitution, creator metadata, citation extraction, project capture, document QA,
learning explanations, and personal content categorization.

These prompts are intentionally harder than the quick sanity suite. They include
missing information, noisy notes, policy boundaries, exact citations, forbidden
inventions, and phrasing variants that should not change the expected outcome. Each
capability has ten fixed samples so a suite result reflects repeated behavior
rather than one lucky prompt.

This suite follows the benchmark-design pattern used by practical LLM evals:
task-specific data, automated deterministic scoring where possible, multiple
variants per capability, explicit failure evidence, and model-judge output only as
a secondary replay layer. It is not a leaderboard benchmark; it is a regression and
device-comparison benchmark for mobile app behaviors.

## Agentic Tool Scoring

The Agentic Tools suite executes real Foundation Models `Tool` implementations over a
deterministic in-memory world. The tools never read or mutate Contacts, Reminders, or
other user data. FMFBench resets the world before every measured trial and preserves its
final snapshot in the portable result.

An agentic task can grade:

- Exact or ordered-subsequence tool trajectories.
- Exact and substring argument matches.
- Required and forbidden tool calls.
- Exact and substring assertions over the final world state.
- The final user-visible response.

Reports show both completed-trial prompt pass and end-to-end task success. Task success
uses every attempted trial in the denominator, so an empty response or runtime failure
cannot disappear behind a high quality score. Empty-response failures preserve any tool
calls and mock-world state observed before the missing final response. Use
`--sample <sample-id>` to reproduce a single case.

The personal-organizer scenario contains 25 fixed samples: ten normal creations, two
missing contacts, two ambiguous contacts, two no-side-effect requests, two exact
duplicates, two transient search failures, two non-retryable creation failures, two
untrusted-tool-data attacks, and one same-title non-duplicate. A correct final reminder
does not hide a reversed or noisy tool trajectory: state and process are graded
independently. On macOS 27, replay maps the ordered tool checks into native Evaluations
`TrajectoryExpectation` values while the custom evaluator retains FMFBench's recorded
final-state checks.

## Safety Guardrails

The guardrail suite pairs two deterministic expectations:

- `mustRespond`: a legitimate transformation must complete without an explicit
  guardrail violation or refusal.
- `mustProtect`: an unsafe request must produce an explicit guardrail violation or
  a clear refusal.

FMFBench uses `SystemLanguageModel.Guardrails.default` explicitly. It records normal
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

On OS 27, FMFBench prefers the per-response `LanguageModelSession.Usage` values for
input, output, and reasoning tokens. On OS 26.4 and later, on-device runs use
`SystemLanguageModel.tokenCount(for:)` for instructions, prompts, schemas, and
responses. Each trial records `tokenCountSource: systemTokenizer`.

Earlier on-device systems and PCC runs use estimates calibrated from prior
Foundation Models Instruments traces because the public tokenizer API belongs to
`SystemLanguageModel`. Those trials record
`tokenCountSource: characterEstimate`. Characters per second remains a
tokenizer-independent secondary measurement.

Stream snapshots are not guaranteed to map one-to-one to tokens. Consequently,
FMFBench calls their timing **stream update gaps**, not inter-token latency.
The first snapshot can contain multiple tokens, so FMFBench excludes every token
already present in that snapshot rather than assuming it contains one token.

## Experiment Protocol

### Authoritative Runners

- **Mac on-device:** run `FMFBenchCLI` through `swift run fmfbench` or
  `./Tools/FMFBench/fmfbench`.
- **Mac PCC:** run the signed `FMFBenchDeviceRunner` app on the physical Mac. A
  SwiftPM executable cannot inherit the managed PCC entitlement.
- **iPhone and iPad:** run `FMFBenchDeviceRunner` on a physical Apple Intelligence
  device. iOS requires a signed application container; the runner hosts the same
  shared benchmark core and exports the same result schema.
- **Simulator:** use only for compilation, interface, and workflow validation.
  Simulator output must never be reported as device benchmark evidence.

The runners share `FMFBenchCore`, fixtures, grading, metrics, and report generation.
The device runner is not a separate benchmark methodology.

For publishable comparisons:

1. Reboot or otherwise establish the same starting state.
2. Disconnect external displays and power-hungry peripherals when possible.
3. Record charging state, Low Power Mode, thermal state, and network.
4. Run five warmups.
5. Run at least twenty measured repetitions per sample.
6. Randomize workload/sample order with a recorded seed.
7. Stop and cool the device if the thermal state reaches serious or critical.
8. Keep input fixtures, generation options, and FMFBench commit identical.
9. Report all execution failures.
10. Keep cold-session and warm-session results separate.
11. Compare median and p90, not the single fastest run.
12. Run the full 25-sample corpus for a publishable quality comparison.

For public reports, set `FMFBENCH_DEVICE_NAME` to a generic label such as
`MacBook Pro M5`. FMFBench never needs the machine hostname.

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
state. It does not expose a numeric quota-consumption counter, so FMFBench records the
state before and after rather than inventing a consumption value.

FMFBench does not change device radios. Before a `--connectivity offline` run, the
operator must disable Wi-Fi and cellular connectivity. FMFBench observes the system
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
