# Private Cloud Compute Notes

## Why PCC Requires Apple Intelligence

PCC is not exposed as a conventional server API with a developer API key.
Apple's
[WWDC26 PCC session](https://developer.apple.com/videos/play/wwdc2026/319/)
explains that it is integrated with the OS and iCloud:

- The device establishes the privacy-preserving request path.
- The user's Apple Intelligence and iCloud context handles eligibility and
  authentication without an app-managed account or API key.
- Usage limits are per user, with higher limits available through iCloud+.
- The client checks model availability and handles fallback.

That architecture is why a cloud-hosted model still requires an Apple
Intelligence-capable device with Apple Intelligence enabled. The device is part
of the trust, identity, policy, and privacy boundary rather than a generic thin
client.

Apple describes the on-device model as offline and unlimited. The runtime
`contextSize` API reports the actual limit; Apple's WWDC26 example shows 4K on
OS 26 and 8K on OS 27 on newer devices. PCC requires a network connection, has
a daily per-user limit, offers a 32K context, and supports light, moderate, and
deep reasoning.

Apps also need Apple's managed PCC entitlement and must meet the program's
eligibility requirements. Availability can still fail after those static
requirements are met, so production code needs a graceful on-device or
non-model fallback.

## June 12, 2026 Control Experiment

Environment:

- MacBook Pro `Mac17,2`
- Apple M5, 32 GB
- macOS 27.0 beta build `26A5353q`
- Apple Intelligence enabled
- On-device system model available

FMFBench's Xcode 27-built PCC request failed before first output with:

```text
FoundationModels.LanguageModelSession.GenerationError
ModelManagerServices.ModelManagerError code 1046
```

Apple's own signed `/usr/bin/fm` utility reported:

```text
PCC inference is not available in this context.
```

This control means the observed failure should not be described solely as a
missing entitlement in FMFBench. PCC was unavailable in the current system,
account, region, quota, or service context even to Apple's utility. The report
retains the failed attempt with its environment and timestamp.

## Benchmarking Rules

- Record every availability, quota, network, and generation failure.
- Keep the reasoning level fixed.
- Record network type and approximate region manually until FMFBench captures
  them.
- Do not compare PCC token rate directly with on-device hardware inference.
- Use end-to-end latency for user experience and retain server timestamps.
- Repeat on different days before drawing conclusions about service stability.
- Record quota status before and after; Apple's API does not expose numeric
  consumption.
- Run each reasoning level as a separate configuration.
- Treat fallback-enabled runs separately from direct PCC runs.
- When using `--connectivity offline`, disable connectivity outside FMFBench.
  FMFBench verifies that no active network path is available before the run, but it
  does not change Wi-Fi or cellular settings.
