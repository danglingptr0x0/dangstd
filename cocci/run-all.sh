#!/usr/bin/env bash
# usage: run-all.sh [dir] [--fix]

DIR="${1:-.}"
MODE="report"
[[ "$2" == "--fix" ]] && MODE="patch"

COCCI_DIR="$(dirname "$0")"
ISSUES=0
AFFECTED_FILES=()

ALL_DIFFS=""
for cocci in "$COCCI_DIR"/*.cocci; do
    name=$(basename "$cocci" .cocci)
    output=$(spatch --sp-file "$cocci" --dir "$DIR" --include-headers 2>/dev/null)

    if [[ -n "$output" ]] && echo "$output" | grep -qE "^diff"; then
        ALL_DIFFS+="# === $name ===
$output

"
        while IFS= read -r f; do
            AFFECTED_FILES+=("$f")
        done < <(echo "$output" | grep "^---" | sed 's/^--- //' | cut -f1)
        ((ISSUES++))
    fi
done

if [[ "$MODE" == "patch" && $ISSUES -gt 0 ]]; then
    UNIQUE_FILES=($(printf '%s\n' "${AFFECTED_FILES[@]}" | sort -u))

    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    TARBALL="cocci-bkp-${TIMESTAMP}.tar.gz"
    tar -czf "$TARBALL" "${UNIQUE_FILES[@]}" 2>/dev/null
    echo "backup: $TARBALL (${#UNIQUE_FILES[@]} files)"
    echo ""

    for cocci in "$COCCI_DIR"/*.cocci; do
        spatch --sp-file "$cocci" --dir "$DIR" --include-headers --in-place 2>/dev/null
    done
    echo "fixes applied"
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
[[ "$MODE" != "patch" && $ISSUES -gt 0 ]] && echo "" && echo "run with --fix to auto-apply fixes"

exit $((ISSUES > 0 ? 1 : 0))
