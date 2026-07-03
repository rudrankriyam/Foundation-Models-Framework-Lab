#!/usr/bin/env bash
set -euo pipefail

swift build
module_path="$(swift build --show-bin-path)"

for dir in BookPlaygrounds/*; do
    [ -d "$dir" ] || continue

    shopt -s nullglob
    files=("$dir"/*.swift)
    shopt -u nullglob

    [ "${#files[@]}" -gt 0 ] || continue

    printf 'Typechecking %s\n' "$dir"
    xcrun swiftc \
        -suppress-warnings \
        -typecheck \
        -I "$module_path" \
        -I "$module_path/Modules" \
        "${files[@]}"
done
