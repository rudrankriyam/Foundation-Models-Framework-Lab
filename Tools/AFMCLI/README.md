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

- It gives Foundation Models a direct workflow for prompting, tagging, schemas, tools, transcripts, feedback, and local services.
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
afm available
afm quota-usage --model pcc
afm session respond --prompt "Summarize Foundation Models in one paragraph."
afm session respond --adapter ~/MyAdapter.fmadapter --prompt "Rewrite this in my house style."
afm session stream --prompt "Write a short poem about rain."
afm tag run --prompt "A joyful dog playing in a sunny park."
afm schema run typed-person --input "Alex Rivera is a designer in Berlin."
afm schema run custom --schema person-card --schema-dir .afm/schemas --input @person.txt
afm serve
afm bridge prepare
afm bridge ensure
afm bridge status
afm bridge chat --model pcc --prompt "Explain this change."
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

Use the native-style runtime commands when automation needs both system and PCC
status in one stable JSON shape:

```bash
afm available --output json
afm available --model pcc
afm quota-usage --model pcc --output json
```

PCC requires macOS 27, an Xcode 27-built `afm`, and Apple's managed
`com.apple.developer.private-cloud-compute` entitlement in the running
executable. The commands report those states separately. They do not treat the
framework's device-level availability result as proof that the current process
is authorized, and they do not invent a numeric quota that Apple doesn't expose.

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
Custom schema files use standard `required` semantics: properties omitted from
the `required` array are optional.

```bash
afm schema object --name Person --string name --integer age --optional > person.json
afm schema object --format yaml --name Restaurant --string name --string address.street > restaurant.yaml
afm schema list
afm schema run typed-person --input "Alex Rivera is a designer in Berlin."
afm schema run basic-object --preset product
afm schema run array-schema --preset todo
afm schema run enum-schema --preset sentiment
afm schema run custom --schema person-card --schema-dir .afm/schemas --input @person.txt
afm schema run custom --schema person-card --input @person.txt --no-include-schema-in-prompt
```

`schema object` follows the native `fm` declaration order: `--array`,
`--description`, and `--optional` modify the property immediately before them.
Dot-separated names create referenced nested objects. Use `--object <name>
--schema <json>` for an explicit object, or `--anyOf` followed by repeated
`--schema` values for a union. Prefix a schema path with `@` to compose JSON or
YAML artifacts without shell substitution.

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

### Start the local server

`afm serve` starts a transport for local integrations. It provides `GET /health`,
`GET /v1/models`, and OpenAI-compatible `POST /v1/chat/completions`, including
incremental server-sent event streaming.

```bash
afm serve
curl http://127.0.0.1:1976/health
curl http://127.0.0.1:1976/v1/models
curl http://127.0.0.1:1976/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"system","messages":[{"role":"user","content":"Hello"}]}'
curl -N http://127.0.0.1:1976/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"system","messages":[{"role":"user","content":"Hello"}],"stream":true,"stream_options":{"include_usage":true},"tools":[],"tool_choice":"auto"}'
curl http://127.0.0.1:1976/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"system","messages":[{"role":"user","content":"Extract a name from Ada Lovelace."}],"response_format":{"type":"json_schema","json_schema":{"name":"person","strict":true,"schema":{"type":"object","properties":{"name":{"type":"string"}},"required":["name"],"additionalProperties":false}}}}'
curl http://127.0.0.1:1976/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"system","messages":[{"role":"user","content":"What is the weather in Paris?"}],"tools":[{"type":"function","function":{"name":"get_weather","description":"Report a weather lookup request.","parameters":{"type":"object","properties":{"city":{"type":"string"}},"required":["city"],"additionalProperties":false}}}],"tool_choice":"auto"}'
```

Chat requests are stateless: send the complete system, developer, user,
assistant, and tool history each time. String content and typed text parts are
supported, along with `temperature`, `top_p`, `max_completion_tokens`, and the
legacy `max_tokens` alias. Streaming emits assistant role and content deltas,
a terminal finish reason, and `[DONE]`. Set `stream_options.include_usage` to
receive a final empty-choices usage chunk.

Function tools use the public Foundation Models `Tool` protocol, but the server's
adapter only records the model's proposed name and JSON arguments. It never
looks up or executes a caller-supplied function. The response finishes with
`tool_calls`; execute any action in your own process, then send the matching
assistant and tool messages in the next stateless request. `tool_choice: "auto"`
and `"none"` work on OS 26. Forced `"required"` and named-function choices use
the public OS 27 required mode and return `unsupported_tool_choice` on older
runtimes instead of silently behaving like `auto`. `parallel_tool_calls: false`
is accepted with `tool_choice: "none"`; it is rejected for enabled tools because
Foundation Models has no public serial-call mode.

Tool parameter schemas accept the shared dynamic-schema subset: closed objects,
optional or required properties, nested objects, arrays, strings, string enums,
integers, numbers, and booleans. Unsupported JSON Schema keywords receive a
field-specific `400`. `strict: true` additionally requires every object to set
`additionalProperties: false` and list every property as required, recursively.
Requests are capped at 16 definitions, 64 KiB per schema, and 128 KiB combined;
one response may report at most 32 calls. Tool-enabled streams are buffered until
the runtime either finishes normally or reports tool calls, preventing Foundation
Models' internal tool representation from appearing as content deltas.

`response_format` accepts `text` and `json_schema`; structured responses return
JSON text in `message.content`, and structured streams emit the complete JSON
document as one content delta. The older `json_object` mode is not supported.
Properties omitted from `required` are optional. Image parts and unsupported
response formats return a precise `400`. Responses include input/output usage
plus an `afm_measurement` value of `observed`, `tokenized`, or `estimated` so
fallback counts are never presented as runtime observation. Sentinel-stopped
tool calls are counted from the input transcript (including active definitions)
and a synthetic tool-call output entry, so they are reported as `tokenized` or
`estimated`, never `observed`.

Generation concurrency defaults to one and excess requests receive `429`
without being queued. Configure it with `--max-concurrent-generations`; use
`--model-timeout` to change the default 120-second timeout.

The default listener is loopback-only. Cross-site requests are rejected unless
their exact origin is passed with `--allow-origin`. Add bearer authentication
with `--token` or the `AFM_SERVER_TOKEN` environment variable:

```bash
AFM_SERVER_TOKEN="$(openssl rand -hex 32)" afm serve
afm serve --socket /tmp/afm.sock
```

A non-loopback binding requires both `--allow-network` and a bearer token. Unix
sockets are created with mode `0600`, and `afm` refuses to replace regular files,
symlinks, or active sockets at the requested path.

### Use the signed Agent Bridge

`afm bridge` lets terminals, scripts, and coding agents use Foundation Lab as a
signed local host. The client itself needs no TTY and does not need to inherit
the app's entitlements. Foundation Lab performs the model request and exposes
only an authenticated local endpoint.

Prepare the shared directory once, choose `~/.afm` in Foundation Lab's Agent
Bridge settings, and start the bridge:

```bash
afm bridge prepare
afm bridge ensure
afm bridge models
afm bridge chat --prompt "Summarize this repository."
afm bridge chat --model pcc --max-tokens 512 --temperature 0.2 --prompt @prompt.md
```

The default descriptor is `~/.afm/bridge/connection.json`. Use `--base` to
prepare or inspect another shared base directory, or `--descriptor` to read a
specific descriptor file:

```bash
afm bridge status --descriptor /absolute/path/to/connection.json
```

`afm bridge ensure` (also available as `afm bridge launch`) first checks the
authenticated health endpoint. If the host is not reachable, it launches
Foundation Lab in the background with `/usr/bin/open -gj` and waits up to 20
seconds for the bridge. Use `--app /path/to/Foundation Lab.app` for a specific
build and `--timeout` to adjust the bounded wait.

The descriptor is validated as a current-user-only regular file. Its bearer
credential is used internally and is never included in text, JSON, verbose, or
dry-run output. Missing, stale, and unreachable hosts fail with instructions to
restart Agent Bridge instead of waiting for terminal interaction.

Preparation never changes permissions on an existing base directory. Existing
directories must already be owned by the current user with mode `0700`; unsafe
or overly broad modes are rejected without modification.

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
