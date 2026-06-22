#!/bin/bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <path-to-afm-binary>" >&2
  exit 64
fi

binary="$1"
expected_minos="${AFM_EXPECTED_MACOS_MINIMUM:-26.0}"

if [[ "$binary" != /* ]]; then
  binary="$PWD/$binary"
fi

if [[ ! -f "$binary" || ! -x "$binary" ]]; then
  echo "::error::AFM artifact is not an executable file: $binary"
  exit 1
fi

architectures="$(/usr/bin/lipo -archs "$binary")"
architecture_count="$(wc -w <<< "$architectures" | tr -d ' ')"

if [[ "$architecture_count" != "2" ]]; then
  echo "::error::Expected exactly two architecture slices, found: $architectures"
  exit 1
fi

for architecture in arm64 x86_64; do
  if ! /usr/bin/lipo "$binary" -verify_arch "$architecture"; then
    echo "::error::AFM artifact is missing its $architecture slice"
    exit 1
  fi

  actual_minos="$(
    /usr/bin/xcrun vtool -arch "$architecture" -show-build "$binary" |
      /usr/bin/awk '$1 == "minos" { print $2 }'
  )"

  if [[ "$actual_minos" != "$expected_minos" ]]; then
    echo "::error::$architecture minimum macOS is $actual_minos; expected $expected_minos"
    exit 1
  fi
done

temporary_directory="$(mktemp -d)"
trap 'rm -rf "$temporary_directory"' EXIT

run_offline_smokes() {
  local architecture="$1"
  local output_prefix="$temporary_directory/$architecture"

  /usr/bin/arch "-$architecture" "$binary" --help > "$output_prefix-help.txt"
  /usr/bin/grep -Fq "MODEL COMMANDS" "$output_prefix-help.txt"

  /usr/bin/arch "-$architecture" "$binary" --output json --dry-run \
    > "$output_prefix-dry-run.json"
  /usr/bin/grep -Fq '"status":"dry_run"' "$output_prefix-dry-run.json"

  /usr/bin/arch "-$architecture" "$binary" schema list --output json --dry-run \
    > "$output_prefix-schema.json"
  /usr/bin/grep -Fq '"command":"schema list"' "$output_prefix-schema.json"

  set +e
  /usr/bin/arch "-$architecture" "$binary" \
    session respond --prompt hi --temperature 2 \
    > "$output_prefix-validation.txt" 2>&1
  local validation_status=$?
  set -e

  if [[ "$validation_status" -ne 64 ]]; then
    echo "::error::$architecture validation smoke exited $validation_status; expected 64"
    exit 1
  fi

  /usr/bin/grep -Fq -- "--temperature must be between 0 and 1" \
    "$output_prefix-validation.txt"
  echo "Verified offline $architecture artifact smokes"
}

if ! /usr/bin/arch -arm64 /usr/bin/true >/dev/null 2>&1; then
  echo "::error::The runner cannot execute the required arm64 artifact smoke tests"
  exit 1
fi

run_offline_smokes arm64

if /usr/bin/arch -x86_64 /usr/bin/true >/dev/null 2>&1; then
  run_offline_smokes x86_64
else
  echo "::notice::Rosetta is unavailable; x86_64 execution smokes were skipped. The slice and minimum OS were still verified."
fi

echo "Verified AFM artifact architectures ($architectures) and macOS $expected_minos minimum"
