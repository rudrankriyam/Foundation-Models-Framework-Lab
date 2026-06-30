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

## Signed Runner Requirement

PCC authorization belongs to the executable that makes the request. Apple
embeds an app's entitlements in that executable's code signature; team-level
approval and an enabled App ID are necessary, but they do not grant PCC access
to every process launched by that developer.

For that reason, `swift run fmfbench --model pcc` is not a valid PCC benchmark
path. The SwiftPM executable does not inherit the app target's provisioning
profile or entitlements. Run PCC measurements from `FMFBenchDeviceRunner` on a
physical Mac, iPhone, or iPad. Its explicit App ID and signed provisioning profile include
`com.apple.developer.private-cloud-compute`.

Before recording a PCC result, verify both the built app and its embedded
profile:

```bash
codesign -d --entitlements :- /path/to/FMFBenchDeviceRunner.app

# macOS
security cms -D -i \
  /path/to/FMFBenchDeviceRunner.app/Contents/embedded.provisionprofile

# iOS or iPadOS
security cms -D -i \
  /path/to/FMFBenchDeviceRunner.app/embedded.mobileprovision
```

Both outputs must contain `com.apple.developer.private-cloud-compute = true`.
See Apple's [Entitlements documentation](https://developer.apple.com/documentation/bundleresources/entitlements).

For local terminal PCC contestant runs, use the signed Foundation Lab Agent
Bridge and the bridge runner:

```bash
swift run --package-path Tools/FMFBench/BenchmarkCore fmfbench-bridge-run \
  --output /tmp/fmfbench-apps-pcc
```

This keeps the unsigned SwiftPM process out of `PrivateCloudComputeLanguageModel`
construction. The signed app owns the PCC session; the bridge runner sends the
same Real App Experiences prompts, uses matching JSON schemas for guided tasks,
and grades the returned content with deterministic FMFBench graders.

## June 12, 2026 Unsigned Control

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

This attempt is retained as evidence from an unsigned SwiftPM runner, not as a
PCC service-availability control. Apple's `/usr/bin/fm` executable also does not
inherit a third-party app's managed entitlement, so its result cannot prove that
the entitled app context is unavailable. Only a request from the signed,
provisioned FMFBench app is publishable PCC evidence.

## June 20, 2026 Signed-Runner Validation

The signed macOS runner on the same Mac successfully executed the agentic
`personal-organizer-001` PCC smoke test with fallback disabled. A separate local
one-repetition run covered all 25 personal-organizer samples: all 235 deterministic
tool, argument, response, and final-state checks passed, with zero execution failures
and zero fallback trials. PCC quota was below-limit before and after.

This proves the signed Mac execution path and explains the earlier authorization
failure. It is not a publishable performance baseline: it used zero warmups, one
measured repetition per sample, and an uncommitted development build.

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
