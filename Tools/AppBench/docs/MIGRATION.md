# Migration from Foundation Models Framework Benchmark

The original repository measured one sustained text-generation prompt. AppBench keeps
that workload as the `synthetic-throughput` scenario and expands the repository around
practical app evaluation.

## Names

| Before | After |
| --- | --- |
| Foundation Models Framework Benchmark | Foundation Models AppBench |
| `BenchmarkCore` module | `AppBenchCore` module |
| `BenchmarkCLI` | `AppBenchCLI` |
| `./benchmark` | `./appbench` |

The `BenchmarkCore` package product and `./benchmark` wrapper remain temporarily for
compatibility. Swift source should import `AppBenchCore`.

## Metric Correction

The old `tokensPerSecond` value divided prompt plus response tokens by total duration.
That overstated generation speed.

AppBench reports:

- TTFT separately.
- Output tokens only.
- Decode duration after the first streamed output.
- The complete first cumulative stream snapshot excluded from decode throughput.
- Output characters per second as a tokenizer-independent companion.
- Exact system tokenizer counts on on-device OS 26.4+ runs, with explicit
  `tokenCountSource` provenance for every trial.

Historical values from the old README should not be compared directly with new
AppBench output throughput.

## Existing Traces

Existing `.trace` captures remain useful for validating fallback token estimates and
examining framework behavior across OS builds. They are ignored by Git because they
are large generated artifacts.

## Foundation Lab Consolidation

AppBench now lives at `Tools/AppBench` in Foundation Models Framework Lab. The Lab's
root package exports the portable `AppBenchCore`, `BenchmarkCore`, and `appbench`
products, while `BenchmarkCore/Package.swift` remains available for focused package
development and the device runner keeps its existing local package reference.

Apple Evaluations support moved to `Tools/AppBench/Evaluations/Package.swift`.
That package requires macOS 27 and Xcode 27, and is intentionally absent from the
root iOS-compatible product graph.

The canonical commands from the Lab repository root are:

```bash
swift run appbench list
swift test --filter AppBench
```

Official Mac results still come from the CLI. Official iPhone and iPad results still
require `AppBenchDeviceRunner` on a physical Apple Intelligence device.
