# Migration from Foundation Models Framework Benchmark

The original repository measured one sustained text-generation prompt. FMFBench keeps
that workload as the `synthetic-throughput` scenario and expands the repository around
practical app evaluation.

## Names

| Before | After |
| --- | --- |
| Foundation Models Framework Benchmark | Foundation Models FMFBench |
| `BenchmarkCore` module | `FMFBenchCore` module |
| `BenchmarkCLI` | `FMFBenchCLI` |
| `./benchmark` | `./fmfbench` |

The `BenchmarkCore` package product and `./benchmark` wrapper remain temporarily for
compatibility. Swift source should import `FMFBenchCore`.

## Metric Correction

The old `tokensPerSecond` value divided prompt plus response tokens by total duration.
That overstated generation speed.

FMFBench reports:

- TTFT separately.
- Output tokens only.
- Decode duration after the first streamed output.
- The complete first cumulative stream snapshot excluded from decode throughput.
- Output characters per second as a tokenizer-independent companion.
- Exact system tokenizer counts on on-device OS 26.4+ runs, with explicit
  `tokenCountSource` provenance for every trial.

Historical values from the old README should not be compared directly with new
FMFBench output throughput.

## Existing Traces

Existing `.trace` captures remain useful for validating fallback token estimates and
examining framework behavior across OS builds. They are ignored by Git because they
are large generated artifacts.

## Foundation Lab Consolidation

FMFBench now lives at `Tools/FMFBench` in Foundation Models Framework Lab. The Lab's
root package exports the portable `FMFBenchCore`, `BenchmarkCore`, and `fmfbench`
products, while `BenchmarkCore/Package.swift` remains available for focused package
development and the device runner keeps its existing local package reference.

Apple Evaluations support moved to `Tools/FMFBench/Evaluations/Package.swift`.
That package requires macOS 27 and Xcode 27, and is intentionally absent from the
root iOS-compatible product graph.

The canonical commands from the Lab repository root are:

```bash
swift run fmfbench list
swift test --filter FMFBench
```

Official Mac results still come from the CLI. Official iPhone and iPad results still
require `FMFBenchDeviceRunner` on a physical Apple Intelligence device.
