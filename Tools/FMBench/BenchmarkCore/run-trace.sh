#!/bin/bash

# FMBenchCLI - Automated xctrace workflow for Foundation Models benchmarking
# This script records a benchmark run with xctrace and exports the data

set -e

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$SCRIPT_DIR"

TRACE_FILE="fmbench-performance.trace"
EXPORT_FILE="fmbench-performance.xml"
CLI_PATH="./.build/debug/FMBenchCLI"

if [ "$#" -eq 0 ]; then
    set -- --suite performance --warmups 0 --repetitions 1 --no-randomize
fi

echo "FMBenchCLI - xctrace Foundation Models Workflow"
echo "================================================================================"
echo ""

# Check if CLI is built
if [ ! -f "$CLI_PATH" ]; then
    echo "CLI not built. Building now..."
    swift build
    echo ""
fi

# Remove old trace files if they exist
if [ -e "$TRACE_FILE" ]; then
    echo "Cleaning up old trace file: $TRACE_FILE"
    rm -rf "$TRACE_FILE"
fi

if [ -f "$EXPORT_FILE" ]; then
    echo "Cleaning up old export file: $EXPORT_FILE"
    rm -f "$EXPORT_FILE"
fi

echo "Recording benchmark with Foundation Models instrument..."
echo "   xctrace record --instrument 'Foundation Models' --output $TRACE_FILE --launch -- $CLI_PATH $*"
echo ""

# Record with xctrace
FMBENCH_COMMIT="$(git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null || true)"
export FMBENCH_COMMIT
xctrace record --instrument 'Foundation Models' --output "$TRACE_FILE" --launch -- \
    "$CLI_PATH" "$@"

echo ""
echo "Recording complete!"
echo ""

# Export the data
echo "Exporting trace data..."
echo "   xctrace export --input $TRACE_FILE --xpath '/trace-toc/run[@number=\"1\"]/data/table[@schema=\"FoundationModelsTable\"]' > $EXPORT_FILE"
echo ""

xctrace export \
    --input "$TRACE_FILE" \
    --xpath '/trace-toc/run[@number="1"]/data/table[@schema="FoundationModelsTable"]' \
    > "$EXPORT_FILE"

echo "Export complete!"
echo ""

# Display the export
echo "Exported XML content:"
echo "================================================================================"
cat "$EXPORT_FILE"
echo ""
echo "================================================================================"
echo ""

# Keep the exported XML alongside the FMBench report for analysis.
echo "Parsing XML data..."
echo "Use Instruments to inspect the trace alongside the JSON FMBench report."

echo ""
echo "Done! Files created:"
echo "   - $TRACE_FILE (trace data)"
echo "   - $EXPORT_FILE (exported XML)"
