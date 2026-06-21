#!/usr/bin/env bash
# Performance Test Script — Godot 4.5
# Runs performance test suite and records monitors
# Usage: bash tests/performance/perf_test.sh
set -euo pipefail

PERF_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$PERF_DIR/../.." && pwd)"
REPORT_FILE="$PERF_DIR/report_$$.json"

GDUNIT_CMD=(godot --headless -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/performance --ignoreHeadlessMode -c)

main() {
    echo "=== Performance Test ==="
    echo "Project: $PROJECT_DIR"
    echo ""

    # Build script cache so gdUnit4 classes resolve
    godot --headless --import 2>/dev/null || true

    local exit_code=0
    local output
    output=$("${GDUNIT_CMD[@]}" 2>&1) || exit_code=$?

    echo "$output"

    local avg_fps
    avg_fps=$(echo "$output" | grep -oP 'FPS: \K[\d.]+' || echo "N/A")

    local report="{\n"
    report+="  \"exit_code\": $exit_code,\n"
    report+="  \"avg_fps\": $avg_fps,\n"
    report+="  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n"
    report+="}"

    echo -e "$report" > "$REPORT_FILE"
    echo ""
    echo "Report saved: $REPORT_FILE"
    echo -e "$report"
    return $exit_code
}

main "$@"
