# Device Matrix

## Primary Devices

### MacBook Pro M5

- OS 26 on-device baseline.
- OS 27 on-device comparison.
- OS 27 PCC service comparison.
- Run every published Mac measurement with `FMBenchCLI`.

### iPhone 16 Pro Max

- OS 26 on-device baseline.
- OS 27 on-device comparison.
- OS 27 PCC service comparison.
- Run every published iPhone measurement with `FMBenchDeviceRunner` on the
  physical phone.

Capture OS 26 results before upgrading. Apple may stop signing an older OS, making a
downgrade unavailable.

Simulator runs are excluded from the device matrix. They may verify that the runner
builds and launches, but they do not measure an iPhone model or its performance.

## Result Naming

Use:

```text
Results/<device>-<os-build>-<model>-<suite>-<timestamp>.json
Results/<device>-<os-build>-<model>-<suite>-<timestamp>.md
```

Examples:

```text
Results/macbook-pro-m5-26A5353q-on-device-quick-2026-06-12.json
Results/iphone-16-pro-max-ios26-on-device-full-2026-06-12.json
```

## Minimum Published Run

- Five warmups.
- Twenty measured repetitions per sample.
- All 25 fixed samples for each reported practical workload.
- Seeded randomized workload order.
- Cold and warm sessions reported separately.
- Nominal or fair thermal state.
- Low Power Mode recorded.
- No omitted failures.
- FMBench commit SHA recorded alongside the result.

For the cleanest OS comparison, use two identical devices, one held on OS 26 and one
on OS 27. If one physical device is upgraded in place, capture the complete OS 26
result before upgrading and keep power, ambient temperature, network, and peripherals
as consistent as possible.

## Comparability Labels

- **OS comparison:** same device, different OS build.
- **Device comparison:** same model class and OS generation, different hardware.
- **Execution comparison:** same fixture, on-device versus PCC.
- **Longitudinal PCC comparison:** same client setup, different date.

These labels prevent PCC network latency from being mistaken for device inference
performance and prevent hardware changes from being attributed only to the OS.
