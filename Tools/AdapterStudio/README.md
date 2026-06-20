# Foundation Models Adapter Studio

Adapter Studio now has two focused surfaces inside Foundation Models Framework Lab:

- The **Adapter Comparison** workspace in the Foundation Lab macOS app imports a
  `.fmadapter` package and streams the same prompt through fresh base-model and
  adapter-model sessions.
- The **`fmas` CLI** wraps Apple's Python adapter training toolkit for setup,
  generation, training, draft-model training, and export.

The old standalone macOS app target is intentionally gone. Its Swift implementation
lives in [`Foundation Lab/AdapterStudio`](../../Foundation%20Lab/AdapterStudio), while
this directory owns the Python workflow.

## Requirements

- macOS 26 or later with Apple Intelligence enabled for live adapter comparison
- Python 3.11 or later for `fmas`
- Apple's Foundation Models adapter training toolkit
- A Mac with Apple silicon and enough memory for the selected toolkit workflow

Download the toolkit from
[Apple Developer](https://developer.apple.com/download/foundation-models-adapter/).
Each toolkit and exported adapter is compatible with a specific system-model version,
so retrain and reevaluate adapters when that model changes.

## Install `fmas`

From the repository root:

```bash
python3.11 -m venv .venv-fmas
source .venv-fmas/bin/activate
python -m pip install -e Tools/AdapterStudio
fmas --help
```

The CLI keeps its toolkit path in `~/.adapter-studio/config.json` for compatibility
with existing installations.

## Workflow

```bash
fmas init
fmas setup
fmas generate --prompt "Test the base model."
fmas train-adapter --help
fmas train-draft --help
fmas export --help
```

`fmas` propagates the wrapped toolkit process status. Invalid arguments return `2`;
configuration, environment, timeout, and execution failures return a nonzero status
instead of silently succeeding.

## Test

```bash
python -m unittest discover -s Tools/AdapterStudio/tests -v
```

## Comparison Scope

The Lab workspace is for quick qualitative inspection and interactive timing. It runs
the two streams concurrently, so its latency numbers are diagnostic rather than
publishable benchmark results. Use FMBench for controlled warmups, repetitions,
randomization, deterministic graders, and report artifacts.
