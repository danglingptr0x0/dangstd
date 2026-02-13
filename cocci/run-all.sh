#!/usr/bin/env bash

DIR="${1:-.}"
MODE="report"
[[ "$2" == "--short" ]] && MODE="short"

COCCI_DIR="$(dirname "$0")"
ISSUES=0
AFFECTED_FILES=()

if [[ -t 1 ]]; then
    RST=$'\033[0m'
    BOLD=$'\033[1m'
    DIM=$'\033[2m'
    RED=$'\033[31m'
    CYAN=$'\033[36m'
    BYEL=$'\033[1;33m'
    BRED=$'\033[1;31m'
    BCYN=$'\033[1;36m'
else
    RST="" BOLD="" DIM="" RED="" CYAN="" BYEL="" BRED="" BCYN=""
fi

ALL_DIFFS=""
SHORT_OUTPUT=""
TMPDIR=$(mktemp -d)

for cocci in "$COCCI_DIR"/*.cocci; do
    name=$(basename "$cocci" .cocci)
    (
        output=$(spatch --sp-file "$cocci" --dir "$DIR" -j 4 2>/dev/null)
        if [[ -n "$output" ]] && echo "$output" | grep -qE "^diff"; then
            echo "# $name" > "$TMPDIR/$name.out"
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
    rule_descs=""
    while IFS= read -r cline; do
        cline="${cline#// }"
        rule_descs+="    ${DIM}$cline${RST}"$'\n'
    done < <(grep -E '^//' "$COCCI_DIR/$name.cocci")

    SHORT_OUTPUT+="${BYEL}[$name]${RST}"$'\n'
    if [[ -n "$rule_descs" ]]; then
        SHORT_OUTPUT+="$rule_descs"
    fi

    current_file=""
    hunk_line=0
    in_hunk=0
    while IFS= read -r line; do
        if [[ "$line" =~ ^---\ (.+) ]]; then
            current_file="${BASH_REMATCH[1]}"
            current_file="${current_file%% *}"
            AFFECTED_FILES+=("$current_file")
            in_hunk=0
        elif [[ "$line" =~ ^\+\+\+ ]]; then
            in_hunk=0
        elif [[ "$line" =~ ^@@\ -([0-9]+) ]]; then
            hunk_line="${BASH_REMATCH[1]}"
            in_hunk=1
        elif [[ "$in_hunk" -eq 1 ]]; then
            case "${line:0:1}" in
                -)
                    if [[ -n "$current_file" && -f "$current_file" ]]; then
                        total=$(wc -l < "$current_file")
                        start=$((hunk_line > 1 ? hunk_line - 1 : 1))
                        end=$((hunk_line + 1 < total ? hunk_line + 1 : total))
                        SHORT_OUTPUT+="  ${BCYN}$current_file${RST}:${CYAN}$hunk_line${RST}"$'\n'
                        while IFS= read -r fmtline; do
                            SHORT_OUTPUT+="$fmtline"$'\n'
                        done < <(awk -v s="$start" -v e="$end" -v flag="$hunk_line" \
                            -v bred="$BRED" -v dim="$DIM" -v rst="$RST" \
                            'NR>=s && NR<=e {
                                if (NR == flag)
                                    printf "%s  >> %4d | %s%s\n", bred, NR, $0, rst
                                else
                                    printf "%s     %4d | %s%s\n", dim, NR, $0, rst
                            }' "$current_file")
                        SHORT_OUTPUT+=$'\n'
                    fi
                    ((hunk_line++))
                    ;;
                +) ;;
                *) ((hunk_line++)) ;;
            esac
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
            echo "$ALL_DIFFS" | git diff --no-index --color /dev/null - 2>/dev/null || echo "$ALL_DIFFS"
        fi
    fi
fi

echo ""
echo "${BOLD}summary${RST}"
echo "patches: $(ls "$COCCI_DIR"/*.cocci 2>/dev/null | wc -l)"
if [[ "$ISSUES" -gt 0 ]]; then
    echo "issues: ${BRED}$ISSUES${RST}"
else
    echo "issues: $ISSUES"
fi

exit $((ISSUES > 0 ? 1 : 0))
