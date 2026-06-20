# Foundation Models FMFBench

## Purpose

FMFBench evaluates practical Foundation Models workloads across Apple devices, OS
builds, the on-device model, and Private Cloud Compute. Quality and performance must
always remain separate metrics.

## Requirements

- Swift 6.2+
- Xcode 26+ for the OS 26-compatible core
- Xcode 27 for PCC code paths
- Apple Intelligence enabled on supported physical hardware

## Commands

```bash
swift run fmfbench list
swift run fmfbench --suite quick --model on-device --repetitions 3
swift run fmfbench --suite agentic --warmups 0 --repetitions 1
swift test --filter FMFBench

DEVELOPER_DIR=/Users/rudrank/Downloads/Xcode-beta.app/Contents/Developer \
  xcodebuild -project Tools/FMFBench/FMFBenchDeviceRunner/FMFBenchDeviceRunner.xcodeproj \
  -scheme FMFBenchDeviceRunner \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Architecture

- `Tools/FMFBench/BenchmarkCore/Sources/FMFBenchCore`: scenarios, deterministic
  graders, mocked agent worlds, model runner, metrics, statistics, environment
  capture, and reports.
- `Tools/FMFBench/BenchmarkCore/Sources/FMFBenchCLI`: canonical runner for official
  on-device Mac results.
- `Tools/FMFBench/FMFBenchDeviceRunner/FMFBenchDeviceRunner`: signed iOS and macOS
  harness for Mac PCC and physical-device iPhone and iPad results.
- `Tools/FMFBench/BenchmarkCore/Tests/FMFBenchCoreTests`: offline grading/statistics
  tests.
- `Tools/FMFBench/FMFBenchDeviceRunner/FMFBenchDeviceRunnerTests`: live model smoke
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
