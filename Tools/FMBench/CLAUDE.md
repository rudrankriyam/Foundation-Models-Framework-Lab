# Foundation Models FMBench

## Purpose

FMBench evaluates practical Foundation Models workloads across Apple devices, OS
builds, the on-device model, and Private Cloud Compute. Quality and performance must
always remain separate metrics.

## Requirements

- Swift 6.2+
- Xcode 26+ for the OS 26-compatible core
- Xcode 27 for PCC code paths
- Apple Intelligence enabled on supported physical hardware

## Commands

```bash
swift run fmbench list
swift run fmbench --suite quick --model on-device --repetitions 3
swift run fmbench --suite agentic --warmups 0 --repetitions 1
swift test --filter FMBench

DEVELOPER_DIR=/Users/rudrank/Downloads/Xcode-beta.app/Contents/Developer \
  xcodebuild -project Tools/FMBench/FMBenchDeviceRunner/FMBenchDeviceRunner.xcodeproj \
  -scheme FMBenchDeviceRunner \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Architecture

- `Tools/FMBench/BenchmarkCore/Sources/FMBenchCore`: scenarios, deterministic
  graders, mocked agent worlds, model runner, metrics, statistics, environment
  capture, and reports.
- `Tools/FMBench/BenchmarkCore/Sources/FMBenchCLI`: canonical runner for official
  on-device Mac results.
- `Tools/FMBench/FMBenchDeviceRunner/FMBenchDeviceRunner`: signed iOS and macOS
  harness for Mac PCC and physical-device iPhone and iPad results.
- `Tools/FMBench/BenchmarkCore/Tests/FMBenchCoreTests`: offline grading/statistics
  tests.
- `Tools/FMBench/FMBenchDeviceRunner/FMBenchDeviceRunnerTests`: live model smoke
  test.

## Rules

- Keep OS 26 compatibility unless a file is compiler- and availability-gated.
- Prefer deterministic checks over LLM judges.
- Prompt pass requires every check to pass.
- Output throughput must use output tokens and decode duration only.
- Never call snapshot timing inter-token latency.
- Preserve failures in reports.
- Include OS build, thermal state, Low Power Mode, and timestamp.
- PCC results are service measurements, not device inference measurements.
- Add new scenarios using synthetic fixtures, clear provenance, and inspectable checks.
- Keep agentic tools deterministic and isolated from real user data and side effects.
- Never publish simulator results. Use the CLI for Mac on-device runs and the signed
  runner for Mac PCC and physical iPhone or iPad runs.
- Do not commit raw `.trace` bundles.

Read `docs/METHODOLOGY.md` before changing metrics or evaluation behavior.
