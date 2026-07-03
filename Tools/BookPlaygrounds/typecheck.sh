#!/usr/bin/env bash
set -euo pipefail

swift build

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
        -I .build/out/Products/Debug \
        "${files[@]}"
done
