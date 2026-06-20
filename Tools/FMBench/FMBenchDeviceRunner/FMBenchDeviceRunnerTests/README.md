# FMBench Live Tests

`FMBenchLiveTests` runs a real Foundation Models scenario through `FMBenchCore`.
It is intentionally a smoke test rather than the primary benchmark runner.

## Run

1. Open `FMBenchDeviceRunner.xcodeproj`.
2. Select My Mac or a physical Apple Intelligence iPhone or iPad.
3. Run `FMBenchLiveTests/testPracticalTaskCaptureScenario`.

The test asserts that one measured trial completed and prints the same Markdown
report used by the CLI. Simulators may report that the system model is unavailable.

For publishable on-device Mac measurements, use the CLI with five warmups and twenty
measured repetitions:

```bash
swift run fmbench --suite quick --warmups 5 --repetitions 20
```

For Mac PCC or publishable iPhone and iPad measurements, use `FMBenchDeviceRunner`
on physical hardware with the same protocol. The PCC smoke test requires Xcode 27,
the managed entitlement, and a provisioning profile that contains it. Simulator and
live-test output are diagnostic, not publishable benchmark evidence.

Do not add fixed performance thresholds to live tests. Throughput and latency vary
by hardware, OS build, thermal state, and background load; compare recorded
distributions instead.
