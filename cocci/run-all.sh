#!/usr/bin/env bash
# usage: run-all.sh [dir] [--short]

DIR="${1:-.}"
MODE="report"
[[ "$2" == "--short" ]] && MODE="short"

COCCI_DIR="$(dirname "$0")"
ISSUES=0
AFFECTED_FILES=()

ALL_DIFFS=""
SHORT_OUTPUT=""
TMPDIR=$(mktemp -d)

for cocci in "$COCCI_DIR"/*.cocci; do
    name=$(basename "$cocci" .cocci)
    (
        output=$(spatch --sp-file "$cocci" --dir "$DIR" -j 4 2>/dev/null)
        if [[ -n "$output" ]] && echo "$output" | grep -qE "^diff"; then
            echo "# === $name ===" > "$TMPDIR/$name.out"
            echo "$output" >> "$TMPDIR/$name.out"
        fi
    )
done

shopt -s nullglob
for outfile in "$TMPDIR"/*.out; do
    output=$(cat "$outfile")
    name=$(basename "$outfile" .out)
    ALL_DIFFS+="$output

"
    current_file=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^---\ (.+) ]]; then
            current_file="${BASH_REMATCH[1]}"
            current_file="${current_file%% *}"
            AFFECTED_FILES+=("$current_file")
        elif [[ "$line" =~ ^@@\ -([0-9]+) ]]; then
            lineno="${BASH_REMATCH[1]}"
            if [[ -n "$current_file" && -f "$current_file" ]]; then
                src_line=$(sed -n "${lineno}p" "$current_file" | sed 's/^[[:space:]]*//' | head -c 60)
                SHORT_OUTPUT+="[$name] $current_file:$lineno: \`$src_line\`"$'\n'
            fi
        fi
    done <<< "$output"
    ((ISSUES++))
done
rm -rf "$TMPDIR"

if [[ "$MODE" == "short" ]]; then
    if [[ -n "$SHORT_OUTPUT" ]]; then
        echo "$SHORT_OUTPUT"
    fi
else
    if [[ -n "$ALL_DIFFS" ]]; then
        if command -v delta &>/dev/null; then
            echo "$ALL_DIFFS" | delta --paging=never
        else
            echo "$ALL_DIFFS" | git diff --no-index --color=always /dev/null - 2>/dev/null || echo "$ALL_DIFFS"
        fi
    fi
fi

echo ""
echo "=== summary ==="
echo "patches: $(ls "$COCCI_DIR"/*.cocci 2>/dev/null | wc -l)"
echo "issues: $ISSUES"

exit $((ISSUES > 0 ? 1 : 0))
