#!/usr/bin/env bash
# Mutation Testing Script — Godot 4.5 / GDScript
# Usage: bash tests/mutation/mutation_test.sh
# Returns: 0 if all mutations caught, 1 if survivors found
set -euo pipefail

MUTATION_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$MUTATION_DIR/../.." && pwd)"
REPORT_FILE="$MUTATION_DIR/report_$$.json"
SRC_DIR="$PROJECT_DIR/src"

GDUNIT_CMD=(godot --headless -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode -c)

declare -A OPERATORS=(
    ["=="]="!="
    ["!="]="=="
    [">="]=">"
    ["<="]="<"
)

declare -A BOOLS=(
    ["true"]="false"
    ["false"]="true"
)

declare -A ARITH=(
    ["+"]="-"
    ["-"]="+"
    ["*"]="/"
    ["/"]="*"
)

mutate_file() {
    local file="$1"
    local from="$2"
    local to="$3"
    local use_word_boundary="$4"

    local tmp_file
    tmp_file=$(mktemp)

    if [ "$use_word_boundary" = "true" ]; then
        sed "s/\b$from\b/$to/g" "$file" > "$tmp_file"
    else
        sed "s/$from/$to/g" "$file" > "$tmp_file"
    fi

    if ! diff -q "$file" "$tmp_file" > /dev/null 2>&1; then
        cp "$tmp_file" "$file"
        rm -f "$tmp_file"
        return 0
    fi
    rm -f "$tmp_file"
    return 1
}

check_syntax() {
    local file="$1"
    cd "$PROJECT_DIR"
    local rel_path="${file#$PROJECT_DIR/}"
    if godot --headless --check-only --script "res://$rel_path" 2>/dev/null; then
        return 0
    fi
    return 1
}

run_tests() {
    cd "$PROJECT_DIR"
    "${GDUNIT_CMD[@]}" 2>&1
}

main() {
    local total_mutations=0
    local caught_mutations=0
    local survived_mutations=0
    local invalid_mutations=0
    local -a survivors=()

    echo "=== Mutation Testing ==="
    echo "Project: $PROJECT_DIR"
    echo "Source:  $SRC_DIR"
    echo ""

    # Build script cache once before any mutations
    echo "Building Godot script cache..."
    godot --headless --import 2>/dev/null || true
    echo ""

    if [ ! -d "$SRC_DIR" ]; then
        echo "WARNING: src/ directory does not exist yet."
        echo "No mutations to apply. Creating empty report."
        echo "[]" > "$REPORT_FILE"
        return 0
    fi

    local src_files=()
    while IFS= read -r -d '' f; do
        src_files+=("$f")
    done < <(find "$SRC_DIR" -name '*.gd' -print0)

    if [ ${#src_files[@]} -eq 0 ]; then
        echo "No .gd files found in src/. Skipping mutation tests."
        echo "[]" > "$REPORT_FILE"
        return 0
    fi

    echo "Found ${#src_files[@]} source files"
    echo ""

    local -a report_entries=()

    try_mutations() {
        local file="$1"
        local backup_file="$2"
        local rel_path="$3"
        local -n mutation_map="$4"
        local word_boundary="$5"
        local -n _total="$6"
        local -n _caught="$7"
        local -n _survived="$8"
        local -n _invalid="$9"
        local -n _survivors="${10}"
        local -n _report_entries="${11}"

        for from in "${!mutation_map[@]}"; do
            local to="${mutation_map[$from]}"
            if mutate_file "$file" "$from" "$to" "$word_boundary"; then
                _total=$((_total + 1))
                echo "  Mutation: $from -> $to"

                if ! check_syntax "$file"; then
                    _invalid=$((_invalid + 1))
                    echo "    -> INVALID (syntax error)"
                    _report_entries+=("{\"file\":\"$rel_path\",\"mutation\":\"$from -> $to\",\"result\":\"INVALID\"}")
                    cp "$backup_file" "$file"
                    continue
                fi

                local exit_code=0
                local output
                output=$(run_tests) || exit_code=$?

                if [ "$exit_code" -ne 0 ]; then
                    _caught=$((_caught + 1))
                    echo "    -> CAUGHT by tests"
                    _report_entries+=("{\"file\":\"$rel_path\",\"mutation\":\"$from -> $to\",\"result\":\"CAUGHT\"}")
                else
                    _survived=$((_survived + 1))
                    _survivors+=("$rel_path: $from -> $to")
                    echo "    -> SURVIVED"
                    _report_entries+=("{\"file\":\"$rel_path\",\"mutation\":\"$from -> $to\",\"result\":\"SURVIVED\"}")
                fi
                cp "$backup_file" "$file"
            fi
        done
    }

    for file in "${src_files[@]}"; do
        local rel_path="${file#$PROJECT_DIR/}"
        echo "--- Mutating: $rel_path ---"

        local backup_file
        backup_file=$(mktemp)
        cp "$file" "$backup_file"

        try_mutations "$file" "$backup_file" "$rel_path" OPERATORS "false" \
            total_mutations caught_mutations survived_mutations invalid_mutations \
            survivors report_entries

        try_mutations "$file" "$backup_file" "$rel_path" BOOLS "true" \
            total_mutations caught_mutations survived_mutations invalid_mutations \
            survivors report_entries

        try_mutations "$file" "$backup_file" "$rel_path" ARITH "false" \
            total_mutations caught_mutations survived_mutations invalid_mutations \
            survivors report_entries

        rm -f "$backup_file"
        echo ""
    done

    local report_json="["
    local first=true
    for entry in "${report_entries[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            report_json+=","
        fi
        report_json+="$entry"
    done
    report_json+="]"
    echo "$report_json" > "$REPORT_FILE"

    echo "====================================="
    echo "Mutation Test Results:"
    echo "  Total:   $total_mutations"
    echo "  Caught:  $caught_mutations"
    echo "  Survived:$survived_mutations"
    echo "  Invalid: $invalid_mutations"
    echo ""
    if [ "$survived_mutations" -gt 0 ]; then
        echo "SURVIVED MUTATIONS:"
        for s in "${survivors[@]}"; do
            echo "  - $s"
        done
        echo ""
        echo "RESULT: FAIL ($survived_mutations survivors)"
        echo "Report: $REPORT_FILE"
        return 1
    else
        echo "RESULT: PASS (all mutations caught or invalid)"
        echo "Report: $REPORT_FILE"
        return 0
    fi
}

main "$@"
