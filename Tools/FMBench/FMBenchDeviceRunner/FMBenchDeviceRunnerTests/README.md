# FMBench Live Tests

`FMBenchLiveTests` runs a real Foundation Models scenario through `FMBenchCore`.
It is intentionally a smoke test rather than the primary benchmark runner.

## Run

1. Open `FMBenchDeviceRunner.xcodeproj`.
2. Select a physical Apple Intelligence iPhone or iPad.
3. Run `FMBenchLiveTests/testPracticalTaskCaptureScenario`.

The test asserts that one measured trial completed and prints the same Markdown
report used by the CLI. Simulators may report that the system model is unavailable.

For publishable Mac measurements, use the CLI with five warmups and twenty measured
repetitions:

```bash
swift run fmbench --suite quick --warmups 5 --repetitions 20
```

For publishable iPhone or iPad measurements, use `FMBenchDeviceRunner` on the
physical device with the same protocol. Simulator and live-test output are diagnostic,
not publishable benchmark evidence.

Do not add fixed performance thresholds to live tests. Throughput and latency vary
by hardware, OS build, thermal state, and background load; compare recorded
distributions instead.
