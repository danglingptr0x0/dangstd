#!/usr/bin/env bash
set -e

check_file() {
    local file="$1"
    local errors=0
    local in_block=0
    local brace_depth=0
    local block_start_line=0
    local block_keyword=""
    local semicolon_count=0
    local prev_line=""
    local prev_line_trimmed=""
    local line_num=0
    local block_content=""
    local ctrl_line=""
    local ctrl_indent=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))
        local trimmed="${line#"${line%%[![:space:]]*}"}"
        trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"

        if [[ "$prev_line_trimmed" =~ ^(if|while|for)[[:space:]]*\(.*\)[[:space:]]*$ ]]; then
            if [[ "$trimmed" == "{" ]]; then
                in_block=1
                brace_depth=1
                block_start_line=$((line_num - 1))
                block_keyword="${BASH_REMATCH[1]}"
                semicolon_count=0
                block_content=""
                ctrl_line="$prev_line_trimmed"
                ctrl_indent="${prev_line%%[![:space:]]*}"
                prev_line="$line"
                prev_line_trimmed="$trimmed"
                continue
            fi
        fi

        if [[ $in_block -eq 1 ]]; then
            local opens="${trimmed//[^\{]/}"
            local closes="${trimmed//[^\}]/}"
            brace_depth=$((brace_depth + ${#opens} - ${#closes}))

            local semis="${trimmed//[^;]/}"
            semicolon_count=$((semicolon_count + ${#semis}))

            if [[ "$trimmed" != "{" && "$trimmed" != "}" && -n "$trimmed" ]]; then
                if [[ -n "$block_content" ]]; then
                    block_content="$block_content $trimmed"
                else
                    block_content="$trimmed"
                fi
            fi

            if [[ $brace_depth -eq 0 ]]; then
                if [[ $semicolon_count -eq 1 ]]; then
                    echo "$file:$block_start_line: single-statement '$block_keyword' body spans multiple lines"
                    echo "  suggestion: ${ctrl_indent}${ctrl_line} { ${block_content} }"
                    echo ""
                    ((errors++))
                fi
                in_block=0
            fi
        fi

        prev_line="$line"
        prev_line_trimmed="$trimmed"
    done < "$file"

    return $errors
}

total_errors=0

for file in "$@"; do
    if [[ -f "$file" ]]; then
        if ! check_file "$file"; then
            ((total_errors++))
        fi
    fi
done

exit $((total_errors > 0 ? 1 : 0))
