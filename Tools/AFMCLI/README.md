# AFM CLI

`afm` is a native command-line interface for Foundation Models on Apple platforms.

It is built for day-to-day work with Foundation Models: checking model readiness, trying prompts, streaming responses, extracting structured data, validating tool manifests, and exporting artifacts you can keep or automate around.

The CLI is maintained inside
[`Foundation-Models-Framework-Lab`](https://github.com/rudrankriyam/Foundation-Models-Framework-Lab)
and consumes the same `FoundationLabCore` and `FoundationModelsKit` modules as the app.

## Install

Homebrew is the primary install path:

```bash
brew tap rudrankriyam/tap
brew install afm
```

Tagged releases update the tap automatically.

If you want to build it yourself:

```bash
git clone https://github.com/rudrankriyam/Foundation-Models-Framework-Lab.git
cd Foundation-Models-Framework-Lab
swift build -c release --product afm
.build/release/afm --help
```

To run live model commands, you still need a supported Apple Intelligence Mac. File-based workflows, dry-runs, schema inspection, and tool validation are still useful when the on-device model is unavailable.

## Why `afm`

- It gives Foundation Models a direct command-line workflow for prompting, tagging, schemas, tools, transcripts, and feedback.
- It is built for real terminal use: explicit flags, readable help, file-based inputs, and clean JSON output.
- It works well in automation and agent flows with dry-runs, stdin support, schema and tool directories, and NDJSON-style streaming events.
- It keeps important runtime controls close at hand, including adapters, use cases, guardrails, schema prompting, and feedback issues.
- It reports token provenance instead of presenting tokenized, estimated, and observed usage as if they were interchangeable.

## First Commands

These are good starting points after install:

```bash
afm model status
afm token-count "What is Swift?"
afm token-count -i @instructions.md --prompt @prompt.md --breakdown
afm session respond --prompt "Summarize Foundation Models in one paragraph."
afm session respond --adapter ~/MyAdapter.fmadapter --prompt "Rewrite this in my house style."
afm session stream --prompt "Write a short poem about rain."
afm tag run --prompt "A joyful dog playing in a sunny park."
afm schema run typed-person --input "Alex Rivera is a designer in Berlin."
afm schema run custom --schema person-card --schema-dir .afm/schemas --input @person.txt
```

## Sample Workflows

### Check the model

Use `afm model` when you want to know what the system can do right now.

```bash
afm model status
afm model status --use-case content-tagging
afm model languages
afm model use-cases
afm model guardrails
```

### Count and budget tokens

`afm token-count` accepts the same core text inputs as Apple's `fm token-count`
and adds files, JSON provenance, context-window budgeting, estimator comparison,
schemas, and file-backed tool definitions:

```bash
afm token-count "What is Swift?"
afm token-count -i "You are a helpful assistant" "What is Swift?"
afm token-count --text "First segment" --text "Second segment"
cat prompt.md | afm token-count --output json --pretty
afm token-count --schema person-card --tool demo-weather --breakdown
afm token-count --quiet "Print only the integer"
```

Measurement is explicit:

- `tokenized` means `SystemLanguageModel.tokenCount(for:)` succeeded on macOS 26.4 or later.
- `estimated` means the calibrated FoundationModelsKit fallback was used, including when the tokenizer was unavailable.
- `observed` is reserved for usage reported by an actual model response on macOS 27 or later.

JSON output includes input/output structure, scope, per-component counts, cached
and reasoning counts when the runtime supplies them, the model context limit,
remaining capacity, and calibrated and conservative estimates. Missing cached or
reasoning counts are omitted rather than reported as zero.

The standalone total is the sum of the individually tokenized supplied
components: instructions, prompt segments, schema, and tool definitions. It does
not invent an unattributed runtime overhead value. Runtime framing is available
only from `observed` generation usage.

Standalone counting measures only the context supplied to the command. A real
generation can consume more input tokens because Foundation Models adds runtime
and session framing. The legacy `tokenCount` field in generation commands remains
available; richer `tokenUsage` is additive.

### Try prompts and chat

Use `afm session` for one-shot prompting, streaming, and shared-context conversations.

```bash
afm session respond --prompt "Summarize Foundation Models in one paragraph."
afm session respond --prompt @prompt.txt
afm session respond --adapter ~/MyAdapter.fmadapter --prompt "Rewrite this in my house style."
afm session respond --use-case content-tagging --prompt "Organize this photo library item."
afm session stream --prompt "Write a short poem about rain."
afm session chat --message "Hello" --message "Now answer in French."
```

### Load adapters

Use `--adapter` when you want to run a Foundation Models adapter package instead of the default system model:

```bash
afm session respond --adapter ~/MyAdapter.fmadapter --prompt "Summarize this contract."
afm schema run typed-person --adapter ~/MyAdapter.fmadapter --input "Alex Rivera is a designer in Berlin."
afm feedback export --adapter ~/MyAdapter.fmadapter --prompt "Review this answer." --file feedback.bin
```

The path must point to an existing `.fmadapter` package. The same flag is available on `tag run`, `session ...`, `schema run ...`, `transcript export`, and `feedback export`.

### Try content tagging

Use `afm tag` when you specifically want the content-tagging system model instead of general prompting.

```bash
afm tag run --prompt "A joyful dog playing in a sunny park."
```

### Extract structured data

Use `afm schema` when you want the model to return data in a predictable shape.

```bash
afm schema list
afm schema run typed-person --input "Alex Rivera is a designer in Berlin."
afm schema run basic-object --preset product
afm schema run array-schema --preset todo
afm schema run enum-schema --preset sentiment
afm schema run custom --schema person-card --schema-dir .afm/schemas --input @person.txt
afm schema run custom --schema person-card --input @person.txt --no-include-schema-in-prompt
```

### Inspect and call tool manifests

Use `afm tool` to validate file-backed tools before wiring them into larger flows.

```bash
afm tool inspect --tool echo-json --tool-dir .afm/tools
afm tool validate --tool echo-json --tool-dir .afm/tools
afm tool call --tool echo-json --tool-dir .afm/tools --args @args.json
```

### Export transcripts and feedback

Use export commands when you want artifacts you can keep, diff, or send elsewhere.

```bash
afm transcript export --message "Hello" --message "Summarize our conversation." --file transcript.json
afm feedback export --prompt "What is the capital of France?" --sentiment positive --issue incorrect --file feedback.json
```

## Files, Pipes, And Automation

`afm` is designed to work well with files, pipes, and agent-style automation:

```bash
afm session respond --prompt @prompt.md
cat prompt.md | afm session respond --output json
cat prompt.md | afm token-count --output json
afm schema run custom --schema person-card --schema-dir .afm/schemas --input @person.txt
afm tool call --tool echo-json --tool-dir .afm/tools --args @args.json
```

Bare schema and tool identifiers are resolved through `--schema-dir` and `--tool-dir`, which default to `.afm/schemas` and `.afm/tools`.

## Output And Streaming

`afm` defaults to text in an interactive terminal and JSON when piped or used in automation:

```bash
afm model status --output text
afm model status --output json --pretty
```

Streaming JSON output is emitted as newline-delimited event objects so scripts and agents can react incrementally instead of waiting for one final blob:

```bash
afm session stream --output json --prompt "Reply with three short lines."
afm session chat --stream --output json --message "Hello" --message "Keep going."
```

## Foundation Models Controls

`afm` surfaces the important Foundation Models knobs directly:

```bash
afm model use-cases
afm model guardrails

afm session respond --use-case general --guardrails default --prompt "Summarize this."
afm tag run --guardrails permissive-content-transformations --prompt "A stormy beach at sunset."

afm schema run custom \
  --schema person-card \
  --input @person.txt \
  --no-include-schema-in-prompt

afm feedback export \
  --prompt "What is the capital of France?" \
  --issue incorrect \
  --issue-explanation "The answer should be Paris." \
  --file feedback.json
```

Supported use cases:

- `general`
- `content-tagging`

Supported guardrails:

- `default`
- `permissive-content-transformations`

Foundation Models adapters currently use the on-device runtime without PCC
reasoning and use the framework's default guardrails. `afm` rejects
`--guardrails permissive-content-transformations` when `--adapter` is present
instead of silently ignoring the requested mode.

## Design Goals

- Long-form flags in docs and examples so commands stay readable
- Human-readable output in a terminal, JSON when piped
- NDJSON-style event streaming for agents and scripts
- File-based schemas and tools instead of “edit Swift and rebuild”
- Foundation Models concepts like use cases, guardrails, schema prompting, and feedback issues mapped directly into the CLI
- Validation errors that fail early instead of silently doing the wrong thing

## Local Development

```bash
swift build --product afm
swift test
swift run afm --help
```

Release tags use the `afm-vx.y.z` format.
