#!/usr/bin/env bash
# sessions.sh -- Deterministic session listing with numbered output
# Called by /sessions skill. Guarantees consistent formatting.
# Usage: sessions.sh [list|show|stale] [name_or_number]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SESSION_DIR="$CLAUDE_DIR/session-state"
CURRENT_FILE="$SESSION_DIR/.current"
ACTIVE_WORK="$CLAUDE_DIR/bundles/active-work.md"

# Read current session name
current_session=""
if [[ -f "$CURRENT_FILE" ]]; then
    current_session=$(head -1 "$CURRENT_FILE" | tr -d '\r\n')
fi

# Get today's date as epoch
today_epoch=$(date +%s)

# Calculate age string from a date string (YYYY-MM-DD or similar)
calc_age() {
    local datestr="$1"
    # Extract YYYY-MM-DD from various formats
    local ymd=$(echo "$datestr" | grep -oP '\d{4}-\d{2}-\d{2}' | head -1)
    if [[ -z "$ymd" ]]; then
        echo "??d"
        return
    fi
    local file_epoch=$(date -d "$ymd" +%s 2>/dev/null)
    if [[ -z "$file_epoch" ]]; then
        echo "??d"
        return
    fi
    local diff=$(( (today_epoch - file_epoch) / 86400 ))
    if [[ $diff -eq 0 ]]; then
        echo "0d"
    elif [[ $diff -eq 1 ]]; then
        echo "1d"
    else
        echo "${diff}d"
    fi
}

# Get age in days as integer (for stale check)
calc_age_days() {
    local datestr="$1"
    local ymd=$(echo "$datestr" | grep -oP '\d{4}-\d{2}-\d{2}' | head -1)
    if [[ -z "$ymd" ]]; then
        echo "999"
        return
    fi
    local file_epoch=$(date -d "$ymd" +%s 2>/dev/null)
    if [[ -z "$file_epoch" ]]; then
        echo "999"
        return
    fi
    echo $(( (today_epoch - file_epoch) / 86400 ))
}

# Build session list (exclude archive/, _autosave.md)
build_list() {
    local files=()
    local names=()
    local dates=()
    local tasks=()
    local repos=()

    for f in "$SESSION_DIR"/*.md; do
        [[ ! -f "$f" ]] && continue
        local basename=$(basename "$f" .md)
        [[ "$basename" == "_autosave" ]] && continue

        local checkpoint_date=""
        local task=""
        local repo_list=""

        # Read first 15 lines for metadata
        local line_num=0
        while IFS= read -r line && [[ $line_num -lt 15 ]]; do
            line_num=$((line_num + 1))
            # Checkpointed date
            if [[ "$line" =~ ^\*\*Checkpointed:\*\* ]]; then
                checkpoint_date=$(echo "$line" | sed 's/\*\*Checkpointed:\*\* //')
            fi
            # Current Task
            if [[ "$line" =~ ^[A-Za-z] ]] && [[ $line_num -gt 3 ]] && [[ -z "$task" ]]; then
                if [[ "$line" != "##"* ]] && [[ "$line" != "**"* ]] && [[ "$line" != "- "* ]] && [[ "$line" != "#"* ]]; then
                    task="$line"
                fi
            fi
            # Repos -- extract repo names from lines containing path patterns
            # Detects workspace-relative paths like /path/to/RepoName or D:\Path\RepoName
            local rname=""
            # Try common path separators (forward slash, backslash, double backslash)
            for sep_pattern in '/' '\\' '\\\\'; do
                if [[ -n "$rname" ]]; then break; fi
                # Extract last path component before common suffixes
                rname=$(echo "$line" | grep -oP "(?<=${sep_pattern})[A-Za-z][\w-]*(?=${sep_pattern}|\s|$)" | head -1)
            done
            # Also try "- RepoName\" or "- RepoName/" patterns from Repos Involved section
            if [[ -z "$rname" ]] && [[ "$line" =~ ^-\ +([A-Za-z][\w-]+) ]]; then
                rname="${BASH_REMATCH[1]}"
            fi
            if [[ -n "$rname" ]] && [[ "$rname" != "." ]] && [[ "$rname" != "Code" ]] && [[ ${#rname} -gt 2 ]]; then
                if [[ -n "$repo_list" ]]; then
                    if [[ "$repo_list" != *"$rname"* ]]; then
                        repo_list="$repo_list, $rname"
                    fi
                else
                    repo_list="$rname"
                fi
            fi
        done < "$f"

        # Fallback: extract task from "Current Task" section
        if [[ -z "$task" ]]; then
            task=$(awk '/^## Current Task/{getline; while(/^$/)getline; print; exit}' "$f" | head -c 60)
        fi

        files+=("$f")
        names+=("$basename")
        dates+=("$checkpoint_date")
        tasks+=("${task:0:55}")
        repos+=("${repo_list:0:40}")
    done

    # Sort by date (newest first) -- simple bubble sort for small lists
    local n=${#names[@]}
    for ((i=0; i<n; i++)); do
        for ((j=i+1; j<n; j++)); do
            local di=$(echo "${dates[$i]}" | grep -oP '\d{4}-\d{2}-\d{2}' | head -1)
            local dj=$(echo "${dates[$j]}" | grep -oP '\d{4}-\d{2}-\d{2}' | head -1)
            if [[ "$dj" > "$di" ]]; then
                # Swap all arrays
                local tmp="${names[$i]}"; names[$i]="${names[$j]}"; names[$j]="$tmp"
                tmp="${dates[$i]}"; dates[$i]="${dates[$j]}"; dates[$j]="$tmp"
                tmp="${tasks[$i]}"; tasks[$i]="${tasks[$j]}"; tasks[$j]="$tmp"
                tmp="${repos[$i]}"; repos[$i]="${repos[$j]}"; repos[$j]="$tmp"
                tmp="${files[$i]}"; files[$i]="${files[$j]}"; files[$j]="$tmp"
            fi
        done
    done

    # Output numbered list
    echo "SESSION_COUNT=$n"
    for ((i=0; i<n; i++)); do
        local num=$((i + 1))
        local age=$(calc_age "${dates[$i]}")
        local marker=" "
        if [[ "${names[$i]}" == "$current_session" ]]; then
            marker="*"
        fi
        echo "SESSION:${num}:${marker}:${names[$i]}:${age}:${tasks[$i]}:${repos[$i]}"
    done
}

# Format list as table
format_table() {
    local data
    data=$(build_list)
    local count=$(echo "$data" | head -1 | sed 's/SESSION_COUNT=//')

    echo "Sessions ($count active):                              [* = current]"
    printf "  %-3s %-40s %-6s %-55s %s\n" "#" "Name" "Age" "Task" "Repos"
    printf "  %-3s %-40s %-6s %-55s %s\n" "---" "----" "---" "----" "-----"

    local stale_count=0
    echo "$data" | grep "^SESSION:" | while IFS=: read -r _ num marker name age task repos; do
        local age_days=$(echo "$age" | grep -oP '\d+')
        if [[ "$age_days" -gt 7 ]] 2>/dev/null; then
            stale_count=$((stale_count + 1))
        fi
        printf "  %s%-2s %-40s %-6s %-55s %s\n" "$marker" "$num" "$name" "$age" "$task" "$repos"
    done

    # Count stale separately for footer
    local stale=$(echo "$data" | grep "^SESSION:" | while IFS=: read -r _ num marker name age task repos; do
        local ad=$(echo "$age" | grep -oP '\d+')
        if [[ "$ad" -gt 7 ]] 2>/dev/null; then echo "stale"; fi
    done | wc -l)

    echo ""
    if [[ "$stale" -gt 0 ]]; then
        echo "$stale session(s) are stale (>7 days). Run \`sessions stale\` to review."
    fi
}

# Show a session by number or name
show_session() {
    local target="$1"
    local file=""

    # If numeric, resolve from list
    if [[ "$target" =~ ^[0-9]+$ ]]; then
        local data
        data=$(build_list)
        local line=$(echo "$data" | grep "^SESSION:${target}:")
        if [[ -z "$line" ]]; then
            echo "ERROR: No session at #$target"
            return 1
        fi
        local name=$(echo "$line" | cut -d: -f4)
        file="$SESSION_DIR/${name}.md"
    else
        file="$SESSION_DIR/${target}.md"
    fi

    if [[ ! -f "$file" ]]; then
        echo "ERROR: Session file not found: $file"
        return 1
    fi

    cat "$file"
}

# List stale sessions only
list_stale() {
    local data
    data=$(build_list)

    echo "Stale sessions (>7 days):"
    printf "  %-3s %-40s %-6s %s\n" "#" "Name" "Age" "Task"
    printf "  %-3s %-40s %-6s %s\n" "---" "----" "---" "----"

    local found=0
    echo "$data" | grep "^SESSION:" | while IFS=: read -r _ num marker name age task repos; do
        local ad=$(echo "$age" | grep -oP '\d+')
        if [[ "$ad" -gt 7 ]] 2>/dev/null; then
            printf "  %-3s %-40s %-6s %s\n" "$num" "$name" "$age" "$task"
            found=1
        fi
    done

    if [[ $found -eq 0 ]]; then
        echo "  (none)"
    fi
}

# Resolve session name from number
resolve_name() {
    local target="$1"
    if [[ "$target" =~ ^[0-9]+$ ]]; then
        local data
        data=$(build_list)
        local line=$(echo "$data" | grep "^SESSION:${target}:")
        if [[ -n "$line" ]]; then
            echo "$line" | cut -d: -f4
        fi
    else
        echo "$target"
    fi
}

# NEEDS OWNER extraction from active-work.md
show_needs_owner() {
    if [[ -f "$ACTIVE_WORK" ]]; then
        local in_section=0
        while IFS= read -r line; do
            if [[ "$line" =~ ^\#\#.*NEEDS\ OWNER ]]; then
                in_section=1
                echo "NEEDS OWNER:"
                continue
            fi
            if [[ $in_section -eq 1 ]]; then
                if [[ "$line" =~ ^## ]]; then
                    break
                fi
                if [[ -n "$line" ]]; then
                    # Skip struck-through (completed) items
                    if echo "$line" | grep -qP '^\d+[a-z]?\.\s+~~'; then
                        continue
                    fi
                    echo "  $line"
                fi
            fi
        done < "$ACTIVE_WORK"
    fi
}

# Main dispatch
cmd="${1:-list}"
arg="${2:-}"

case "$cmd" in
    list)
        format_table
        echo ""
        show_needs_owner
        echo ""
        echo "Enter a session # to open, or: show|archive|delete <#>, stale, clean"
        ;;
    show)
        if [[ -z "$arg" ]]; then
            echo "Usage: sessions.sh show <name|number>"
            exit 1
        fi
        show_session "$arg"
        ;;
    stale)
        list_stale
        echo ""
        echo "Run \`sessions clean\` to delete all stale, or \`sessions delete <#>\` for one."
        ;;
    resolve)
        resolve_name "$arg"
        ;;
    raw)
        build_list
        ;;
    *)
        echo "Usage: sessions.sh [list|show|stale|resolve|raw] [name|number]"
        ;;
esac
