#!/usr/bin/env bash
# Smoke Test Script — Godot 4.5
# Runs all e2e test suites via gdUnit4
# Usage: bash tests/e2e/smoke_test.sh
set -euo pipefail

E2E_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$E2E_DIR/../.." && pwd)"
REPORT_FILE="$E2E_DIR/report_$$.json"

GDUNIT_CMD=(godot --headless -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/e2e --ignoreHeadlessMode -c)

main() {
    echo "=== Smoke Tests (E2E) ==="
    echo "Project: $PROJECT_DIR"
    echo ""

    # Build script cache so gdUnit4 classes resolve
    godot --headless --import 2>/dev/null || true

    local exit_code=0
    local output
    output=$("${GDUNIT_CMD[@]}" 2>&1) || exit_code=$?

    echo "$output"

    local report="{\n"
    report+="  \"exit_code\": $exit_code,\n"
    report+="  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n"
    report+="}"

    echo -e "$report" > "$REPORT_FILE"

    echo ""
    if [ "$exit_code" -eq 0 ]; then
        echo "Smoke Tests: ALL PASSED"
    else
        echo "Smoke Tests: FAILED (exit code $exit_code)"
    fi
    echo "Report: $REPORT_FILE"
    return $exit_code
}

main "$@"
