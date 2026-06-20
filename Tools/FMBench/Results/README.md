# Results

Generated benchmark reports belong here. Commit only curated comparison reports; raw
local runs are ignored by default.

Each published result should include:

- JSON report.
- Markdown summary.
- FMBench commit SHA.
- Device and OS build.
- Model selection.
- Network notes for PCC.
- Any Instruments trace reference stored outside Git.

Native `.xcevalresult`, `.xcresult`, and JSON Lines history files are generated
developer artifacts and are ignored by Git. Use the standalone `xceval` CLI to
inspect, stream, compare, or export them, then publish only intentionally curated
summaries alongside the portable FMBench JSON.

## June 12, 2026 M5 Baseline

Environment: MacBook Pro `Mac17,2`, Apple M5, 32 GB, macOS 27.0 beta build
`26A5353q`, nominal thermal state, Low Power Mode off.

| Run | Measured trials | Result |
| --- | ---: | --- |
| Practical Quick, on-device | 25 | 25 prompt passes, 0 failures |
| Synthetic Performance, on-device | 5 | Median TTFT 0.413s, median decode 55.35 tok/s |
| Notification summary, PCC attempt | 1 | Unavailable before first output |

Files:

- `macbook-pro-m5-macos27-26A5353q-on-device-quick-2026-06-12.json`
- `macbook-pro-m5-macos27-26A5353q-on-device-quick-2026-06-12.md`
- `macbook-pro-m5-macos27-26A5353q-on-device-performance-2026-06-12.json`
- `macbook-pro-m5-macos27-26A5353q-on-device-performance-2026-06-12.md`
- `macbook-pro-m5-macos27-26A5353q-pcc-attempt-2026-06-12.json`
- `macbook-pro-m5-macos27-26A5353q-pcc-attempt-2026-06-12.md`

All successful on-device trials use Apple's system tokenizer. Decode throughput
excludes every token already present in the first cumulative stream snapshot.
This is a single-device baseline, not an OS 26 versus OS 27 conclusion.

This baseline was captured before commit `72b930a`, which expanded FMBench to ten
practical workloads and 25 samples per workload. Preserve these files as historical
evidence; do not compare their pass count directly with the expanded corpus.
