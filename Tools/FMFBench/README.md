# Foundation Models FMFBench

Foundation Models FMFBench measures real application workloads across Apple devices,
OS releases, the on-device system model, and Private Cloud Compute.

FMFBench is maintained in
[`Tools/FMFBench`](https://github.com/rudrankriyam/Foundation-Models-Framework-Lab/tree/main/Tools/FMFBench)
inside Foundation Models Framework Lab. Its original Git history is preserved here.

It reports **quality and performance separately**. A fast incorrect response remains
incorrect; a high-quality response does not hide poor latency.

Guided generation structure is not counted as quality. FMFBench grades the semantic
values inside a framework-constrained response, not JSON validity that decoding already
guarantees.

## Included Scenarios

The starter corpus uses synthetic, reproducible inputs modeled after app experiences
Apple highlighted in its
[Foundation Models framework app showcase](https://www.apple.com/newsroom/2025/09/apples-foundation-models-framework-unlocks-new-intelligent-app-experiences/).

| Workload | App pattern | Primary quality signal |
| --- | --- | --- |
| Natural-language task parsing | Stuff, OmniFocus | Exact date, list, title, and tags |
| Workout generation | SmartGym, 7 Minute Workout | Constraint compliance |
| Journal summarization | Stoic, Gratitude | Grounding, completeness, and length |
| Classification | Motivation, Streaks, Vocabulary | Exact category |
| Grounded explanation | CellWalk, Platzi | Tool selection, arguments, and grounding |
| Exercise substitution | Train Fitness | Tool arguments and recommendation validity |
| Document question answering | Signeasy, Agenda | Answer and citation accuracy |
| Citation extraction | Essayist | Exact bibliographic fields |
| Creative writing | Detail | Instruction and length compliance |
| Visual recommendation | VLLO, SwingVision | Image-grounded recommendation |
| Contact-grounded reminder | Synthetic personal organizer | Ordered tool calls and final world state |
| Synthetic sustained generation | Original repository workload | Decode throughput |

Each of the ten Practical workloads has 25 fixed samples: five semantic cases across
five prompt phrasings. The app inputs and generated image fixture are original and
synthetic. App names describe the product pattern that inspired each workload; FMFBench
does not reproduce proprietary app data.

FMFBench also includes a separate 50-sample **Safety Guardrails** suite. It measures:

- False positives: benign sensitive-content transformations must receive a useful response.
- Expected protection: unsafe requests must produce an Apple guardrail violation or refusal.
- Explicit guardrail violations and model refusals as distinct outcomes.
- Critical safety failures when protection is missed or a legitimate task is blocked.

The safety fixtures are original, domain-neutral prompts authored specifically for
FMFBench.

The **Agentic Tools** suite runs real Foundation Models `Tool` implementations against
an isolated in-memory world. Its 25 fixed samples cover normal multi-step creation,
missing and ambiguous contacts, lookup-only and preview-only requests, exact duplicate
prevention, transient search retries, non-retryable creation failures, untrusted tool
data, and same-title reminders at different times. FMFBench grades the ordered trajectory,
typed arguments, user-visible outcome, and final world state. The fixture resets before
every trial; it never reads Contacts or writes Reminders on the device.

The **Real App Experiences** suite is inspired by Apple's public Foundation Models
Framework app showcase. It turns the public app patterns into original,
deterministically graded fixtures for workout adaptation, journal reflection, sports
feedback, exercise substitution, creator metadata, citation extraction, project
capture, document QA, learning explanations, and policy-grounded support replies.

## Metrics

Every measured trial records:

- End-to-end task success: passing trials divided by all attempts, including failures.
- Prompt-level pass: every deterministic constraint passed.
- Constraint score: fraction of individual checks passed.
- End-to-end duration.
- Time to first token (TTFT).
- Decode duration.
- Output tokens per second, using Apple's tokenizer for on-device OS 26.4+ runs.
- Output characters per second.
- Stream update count and maximum stream-update gap.
- Input, output, and reasoning token usage where OS 27 exposes it.
- Runtime model context size and per-trial context utilization.
- Starting, ending, and peak observed process memory.
- Starting, ending, and worst observed thermal state.
- Tool names and typed arguments.
- Ordered tool trajectories and mocked final-state assertions.
- Requested model, executed model, and fallback reason.
- PCC quota state before and after the run.
- Device, chip, total memory, OS version/build, locale, and Low Power Mode.

Decode throughput uses **output tokens only** and excludes TTFT. On older on-device
systems and PCC runs, FMFBench records a calibrated character estimate and marks
the source in each trial.

Each scenario summary reports median, p90, mean, range, standard deviation, prompt
pass, constraint score, and execution failure rate.

## Run

Requirements:

- Xcode 26 or newer.
- macOS 26 or newer for the CLI.
- iOS/iPadOS 26 or macOS 26 or newer for the signed runner.
- Apple Intelligence enabled on a supported physical device.
- Xcode 27 and the PCC-entitled, signed device runner for Private Cloud Compute.

```bash
# List workloads
swift run fmfbench list

# Practical quick suite, five warmups and twenty measured repetitions
swift run fmfbench --suite quick --model on-device

# Every sample in the Practical Quick suite
swift run fmfbench --suite quick --all-samples --model on-device

# Full 250-sample practical corpus with export
swift run fmfbench --suite full --warmups 5 --repetitions 20 \
  --json Tools/FMFBench/Results/macbook-m5-macos-27.json \
  --markdown Tools/FMFBench/Results/macbook-m5-macos-27.md

# Compare cold sessions with reused conversational sessions
swift run fmfbench --suite quick --session warm --seed 20260929

# Stateful multi-tool execution with a resettable synthetic world
swift run fmfbench --suite agentic --warmups 0 --repetitions 1 --no-randomize

# Real app experience prompts
swift run fmfbench --suite apps --warmups 0 --repetitions 1 --no-randomize

# Real app experience prompts through the signed Foundation Lab Agent Bridge using PCC
swift run fmfbench-bridge-run --output /tmp/fmfbench-apps-pcc

# Reproduce one exact case and preserve tool/state evidence for empty responses
swift run fmfbench --suite agentic --sample personal-organizer-012 --warmups 0

# Original sustained-generation workload
swift run fmfbench --suite performance --repetitions 20

# Long-context retrieval and explicit offline experiment label
swift run fmfbench --suite context --connectivity offline

# Guardrail trigger and false-positive suite
swift run fmfbench --suite guardrails --warmups 5 --repetitions 20

```

`swift run fmfbench` is not a publishable PCC path because the SwiftPM executable
does not inherit an app target's managed entitlement. Use the signed
`FMFBenchDeviceRunner` on a physical Mac, iPhone, or iPad for PCC measurements.

`./Tools/FMFBench/fmfbench` and `./Tools/FMFBench/benchmark` remain available as
path-independent compatibility wrappers.
Set `FMFBENCH_DEVICE_NAME` when you want a friendly public label; otherwise
FMFBench uses the non-personal hardware identifier rather than the machine
hostname.

To pair a run with Apple's Foundation Models Instrument:

```bash
Tools/FMFBench/BenchmarkCore/run-trace.sh \
  --suite quick --samples 1 --repetitions 1 --no-randomize
```

## Apple Evaluations on macOS 27

FMFBench keeps Apple’s Evaluations framework out of the portable benchmark package
and the signed runner. A separate macOS 27 package replays recorded FMFBench
responses into native `.xcevalresult` files without invoking the model again.

```bash
# Create a native evaluation result from a portable FMFBench JSON report.
Tools/FMFBench/fmfbench-evaluate replay \
  Tools/FMFBench/Results/run.json \
  --output /tmp/fmfbench-evaluations \
  --format json

# Add a PCC model-judge artifact for subjective quality.
# The deterministic replay artifact remains the primary result.
Tools/FMFBench/fmfbench-evaluate replay \
  Tools/FMFBench/Results/run.json \
  --output /tmp/fmfbench-evaluations \
  --judge pcc \
  --format json

# Run a live PCC judge from Terminal through the signed Foundation Lab app.
# First build and launch Foundation Lab with development signing, then enable
# Agent Bridge in Settings with ~/.afm as the bridge folder.
Tools/FMFBench/fmfbench-evaluate replay \
  Tools/FMFBench/Results/run.json \
  --output /tmp/fmfbench-evaluations \
  --judge bridge-pcc \
  --format json

# Inspect, stream, compare, or export results without opening Xcode.
xceval doctor --output json
xceval inspect result.xcevalresult --output json
xceval report result.xcevalresult --output json
xceval samples result.xcevalresult --output jsonl
xceval compare baseline.xcevalresult candidate.xcevalresult --output json

# Run replay, validation, report generation, failure extraction, and datasets.
# FMFBENCH_RESULT is relative to Tools/FMFBench.
xceval pipeline Tools/FMFBench/xceval.pipeline.json \
  --set FMFBENCH_RESULT=Results/run.json \
  --force
```

The generic [`xceval`](https://github.com/rudrankriyam/Evaluations-Framework-CLI)
CLI is a separate public tool and does not know about FMFBench’s JSON schema.
See
[FMFBench and Apple Evaluations](docs/EVALUATIONS.md) for the framework locations,
storage format, Xcode integration, beta caveats, and complete Apple resource list.

For official SystemLanguageModel versus PrivateCloudComputeLanguageModel comparison,
run the same suite, sample selection, repetition count, seed, and session mode for
each model. Replay both JSON reports with `--judge pcc`, then compare the resulting
deterministic artifacts and the additional subjective-quality artifacts separately.
The PCC judge artifact only includes successful, deterministic-passing, non-safety
responses, so quota is not spent on rows that the hard grader already rejected.
Live PCC judging requires the running `fmfbench-evaluate` executable to be signed
with `com.apple.developer.private-cloud-compute`; an unsigned SwiftPM CLI process
cannot inherit that managed entitlement. For local terminal smoke tests, use
`--judge bridge-pcc` after launching a signed Foundation Lab macOS app with Agent
Bridge enabled. That mode writes a bridge judge JSON report instead of a native
`.xcevalresult`, but still uses `PrivateCloudComputeLanguageModel` inside the
entitled app process.

## Execution Surfaces

Official on-device Mac results come from `FMFBenchCLI` through `swift run fmfbench` or
the compatibility wrapper. PCC requires a signed application container, so official
Mac PCC results use `FMFBenchDeviceRunner` instead.

iOS does not provide a standalone CLI environment for this framework. Official iPhone
and iPad results therefore also use the signed `FMFBenchDeviceRunner` harness. Open
`Tools/FMFBench/FMFBenchDeviceRunner/FMFBenchDeviceRunner.xcodeproj`, select My Mac or a
physical iPhone or iPad, and run the `FMFBenchDeviceRunner` scheme. For PCC, its explicit
App ID, provisioning profile, and executable signature must all contain
`com.apple.developer.private-cloud-compute`.

The device runner provides controls for:

- Practical Quick, Practical Full, Agentic Tools, Safety Guardrails, and Synthetic
  Performance suites.
- On-device and PCC execution.
- Five-warmup/twenty-run publishable defaults.
- One sample or all available samples per workload.
- Cold or reused sessions and randomized order.
- PCC reasoning level and on-device fallback.
- Normal or user-induced offline experiment labels.
- Per-scenario prompt pass, constraint score, median TTFT, and median output speed.
- Markdown report copying.

Simulator runs are only for build and interface validation. They are not valid
benchmark results, even if a model happens to report availability.

## OS 26 vs OS 27

Use the same physical device, fixtures, sampling, warmups, and repetition count.

Recommended initial matrix:

| Device | OS | Model |
| --- | --- | --- |
| MacBook Pro M5 | macOS 26 | On-device |
| MacBook Pro M5 | macOS 27 | On-device |
| MacBook Pro M5 | macOS 27 | PCC |
| iPhone 16 Pro Max | iOS 26 | On-device |
| iPhone 16 Pro Max | iOS 27 | On-device |
| iPhone 16 Pro Max | iOS 27 | PCC |

PCC measures end-to-end service behavior, including network and server time. It is not
a measurement of the client device’s inference speed. PCC can change server-side
without an OS update, so every result retains its timestamp and OS build. FMFBench
records Apple's qualitative quota state; the API does not expose numeric request or
token consumption.

See [Methodology](docs/METHODOLOGY.md),
[Research Notes](docs/RESEARCH_NOTES.md),
[OS 26 vs OS 27](docs/OS_26_VS_27.md),
[PCC Notes](docs/PCC.md),
[Device Matrix](docs/DEVICE_MATRIX.md), and
[Migration Notes](docs/MIGRATION.md).

## Current Baseline

The first curated baseline was captured on June 12, 2026, using a MacBook Pro
with Apple M5 and 32 GB of memory on macOS 27 beta build `26A5353q`.

- Practical suite: 25/25 measured trials passed every semantic check.
- Synthetic sustained generation: median TTFT `0.413s`, median decode rate
  `55.35 tok/s`.
- Thermal state remained nominal and Low Power Mode was off.
- An unsigned SwiftPM PCC attempt failed before generation and is retained as a
  runner-authorization failure, not a PCC service-availability result.

That baseline predates the 250-sample practical corpus and is retained as historical
performance data. It must not be compared as if it were a run of the expanded suite.

See [Results](Results/README.md) for the reports and the limits on interpreting
this single-device baseline. Pre-FMFBench community measurements are preserved
in [Legacy Results](docs/LEGACY_RESULTS.md), but their throughput formula is not
comparable with current reports.

## Package

The Lab's root `Package.swift` exports:

- `FMFBenchCore`: scenarios, graders, runner, statistics, and reports.
- `BenchmarkCore`: compatibility product that exposes the `FMFBenchCore` module.
- `fmfbench`: command-line experiment runner backed by the `FMFBenchCLI` target.

The nested `BenchmarkCore/Package.swift` exports the same portable products and keeps
the original `FMFBenchCLI` executable product for focused package development.
`Tools/FMFBench/Evaluations/Package.swift` is a separate macOS 27 developer-tool
package that exports `FMFBenchEvaluations` and the FMFBench-specific
`fmfbench-evaluate` replay command. Generic artifact tooling lives in `xceval`.

## License

MIT. See [LICENSE](LICENSE).
