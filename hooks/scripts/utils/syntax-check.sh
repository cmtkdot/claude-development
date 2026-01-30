#!/bin/bash
# Shared syntax checking helpers for hook scripts
# Source this file: source "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/utils/syntax-check.sh"

# Check syntax of a script file based on extension
# Returns 0 if valid, 1 if invalid
# Usage: check_syntax "/path/to/script.sh"
check_syntax() {
    local file="$1"
    local ext="${file##*.}"

    case "$ext" in
        sh|bash)
            bash -n "$file" 2>/dev/null
            ;;
        py)
            python -m py_compile "$file" 2>/dev/null
            ;;
        cjs|js)
            node --check "$file" 2>/dev/null
            ;;
        *)
            # Unknown extension, assume valid
            return 0
            ;;
    esac
}

# Get syntax error message for a script file
# Usage: get_syntax_error "/path/to/script.sh"
get_syntax_error() {
    local file="$1"
    local ext="${file##*.}"

    case "$ext" in
        sh|bash)
            bash -n "$file" 2>&1
            ;;
        py)
            python -m py_compile "$file" 2>&1
            ;;
        cjs|js)
            node --check "$file" 2>&1
            ;;
        *)
            echo "Unknown file type: $ext"
            ;;
    esac
}
