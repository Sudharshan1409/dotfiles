#!/bin/zsh

# Source the cache manager
source "$HOME/.config/zsh/cache_manager.sh"

# --- Paths ---
_PYTHON_VENV_EXECUTABLE="$HOME/.config/zsh/venv/bin/python3"
_MFUNC_PY_SCRIPT="$HOME/.config/zsh/python/mfunc.py"

# --- Sanity Check ---
if [ ! -f "$_MFUNC_PY_SCRIPT" ]; then
    echo "Error: Function manager script not found at $_MFUNC_PY_SCRIPT" >&2
    return 1
fi

# --- FUNCTION LOADER (now handled by cache_manager.sh) ---
_load_cache

# --- INTERNAL MANAGEMENT FUNCTION ---
function _mfunc_cmd() {
    local command="$1"
    case "$command" in
        add|edit|rm)
            local tmpfile
            tmpfile=$(mktemp) || return 1
            "$_PYTHON_VENV_EXECUTABLE" "$_MFUNC_PY_SCRIPT" --outfile "$tmpfile" "$@"
            local exit_code=$?
            if [[ $exit_code -eq 0 && -s "$tmpfile" ]]; then
                source "$tmpfile"
                _generate_cache # Regenerate cache after modification
            fi
            rm -f "$tmpfile"
            ;;
        *)
            "$_PYTHON_VENV_EXECUTABLE" "$_MFUNC_PY_SCRIPT" "$@"
            ;;
    esac
}
