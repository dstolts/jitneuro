#!/usr/bin/env bash
# dashboard.sh -- Deterministic dashboard display
# Usage: dashboard.sh [session|sessions]
#   session  -- current session dashboard (blockers for active session)
#   sessions -- all sessions aggregate dashboard (default)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SESSION_DIR="$CLAUDE_DIR/session-state"
CURRENT_FILE="$SESSION_DIR/.current"
ACTIVE_WORK="$CLAUDE_DIR/bundles/active-work.md"
PREFS_FILE="$SESSION_DIR/.preferences"

# Determine scope from .preferences if no arg given
scope="${1:-}"
if [[ -z "$scope" ]]; then
    if [[ -f "$PREFS_FILE" ]]; then
        pref=$(grep -oP '(?<=shortcut_scope:\s)\w+' "$PREFS_FILE" 2>/dev/null)
        scope="${pref:-session}"
    else
        scope="session"
    fi
fi

# Read current session
current_session=""
if [[ -f "$CURRENT_FILE" ]]; then
    current_session=$(head -1 "$CURRENT_FILE" | tr -d '\r\n')
fi

# Extract NEEDS OWNER items from active-work.md
extract_needs_owner() {
    if [[ ! -f "$ACTIVE_WORK" ]]; then
        return
    fi
    local in_section=0
    local items=()
    while IFS= read -r line; do
        if [[ "$line" =~ ^\#\#.*NEEDS\ OWNER ]]; then
            in_section=1
            continue
        fi
        if [[ $in_section -eq 1 ]]; then
            if [[ "$line" =~ ^## ]]; then
                break
            fi
            if [[ -n "$line" ]] && [[ "$line" =~ ^[0-9] ]]; then
                items+=("$line")
            fi
        fi
    done < "$ACTIVE_WORK"

    if [[ ${#items[@]} -gt 0 ]]; then
        echo "NEEDS OWNER (${#items[@]} items):"
        for item in "${items[@]}"; do
            # Skip struck-through items (~~...~~)
            if [[ "$item" =~ ~~.*~~ ]]; then
                continue
            fi
            echo "  $item"
        done
    else
        echo "NEEDS OWNER: (none)"
    fi
}

# Extract blocked/pending items from a session file
extract_session_blockers() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        return
    fi
    local in_pending=0
    while IFS= read -r line; do
        if [[ "$line" =~ ^##.*Pending ]] || [[ "$line" =~ ^##.*Blocked ]] || [[ "$line" =~ ^##.*Unresolved ]]; then
            in_pending=1
            continue
        fi
        if [[ $in_pending -eq 1 ]]; then
            if [[ "$line" =~ ^## ]]; then
                break
            fi
            if [[ -n "$line" ]] && [[ "$line" =~ ^- ]]; then
                echo "  $line"
            fi
        fi
    done < "$file"
}

# Extract next steps from a session file
extract_next_steps() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        return
    fi
    local in_next=0
    while IFS= read -r line; do
        if [[ "$line" =~ ^##.*Next\ Step ]]; then
            in_next=1
            continue
        fi
        if [[ $in_next -eq 1 ]]; then
            if [[ "$line" =~ ^## ]]; then
                break
            fi
            if [[ -n "$line" ]] && [[ "$line" =~ ^[0-9-] ]]; then
                echo "  $line"
            fi
        fi
    done < "$file"
}

# Session dashboard (current session only)
session_dashboard() {
    if [[ -z "$current_session" ]]; then
        echo "No active session. Run \`/session new <name>\` to start one."
        return
    fi

    local session_file="$SESSION_DIR/${current_session}.md"
    if [[ ! -f "$session_file" ]]; then
        echo "Session file not found: $current_session"
        return
    fi

    # Get task
    local task=$(awk '/^## Current Task/{getline; while(/^$/)getline; print; exit}' "$session_file")

    echo "== Session Dashboard: $current_session =="
    echo ""
    echo "Task: $task"
    echo ""

    # Blockers from session file
    local blockers=$(extract_session_blockers "$session_file")
    if [[ -n "$blockers" ]]; then
        echo "BLOCKED / PENDING:"
        echo "$blockers"
        echo ""
    fi

    # Next steps from session file
    local steps=$(extract_next_steps "$session_file")
    if [[ -n "$steps" ]]; then
        echo "Next steps:"
        echo "$steps"
        echo ""
    fi

    # NEEDS OWNER (filtered would be ideal, but show all for visibility)
    extract_needs_owner
    echo ""
    echo "[session: $current_session]"
}

# Sessions dashboard (all sessions aggregate)
sessions_dashboard() {
    echo "== All Sessions Dashboard =="
    echo ""

    # Run sessions list
    bash "$(dirname "$0")/sessions.sh" list 2>/dev/null
    if [[ $? -ne 0 ]]; then
        # Fallback: just show NEEDS OWNER
        extract_needs_owner
    fi

    echo ""
    echo "[session: ${current_session:-none}]"
}

case "$scope" in
    session)
        session_dashboard
        ;;
    sessions)
        sessions_dashboard
        ;;
    *)
        echo "Usage: dashboard.sh [session|sessions]"
        ;;
esac
