#!/bin/zsh

# --- Paths ---
_MALIAS_PY_SCRIPT="$_PYTHON_DIR/malias.py"

# --- Sanity Check ---
if [ ! -f "$_MALIAS_PY_SCRIPT" ]; then
    echo "Error: Alias script not found at $_MALIAS_PY_SCRIPT" >&2
    return 1
fi

# --- ALIAS LOADER ---

_load_cache "aliases.sh" $_PYTHON_VENV_EXECUTABLE $_MALIAS_PY_SCRIPT

# --- INTERNAL MANAGEMENT FUNCTION ---
function _malias_cmd() {
    local command="$1"
    case "$command" in
        add|edit|rm)
            local tmpfile
            tmpfile=$(mktemp) || return 1
            "$_PYTHON_VENV_EXECUTABLE" "$_MALIAS_PY_SCRIPT" --outfile "$tmpfile" "$@"
            local exit_code=$?
            if [[ $exit_code -eq 0 && -s "$tmpfile" ]]; then
                source "$tmpfile"
                _generate_cache "aliases.sh" $_PYTHON_VENV_EXECUTABLE $_MALIAS_PY_SCRIPT
            fi
            rm -f "$tmpfile"
            ;;
        ls|help|"")
            "$_PYTHON_VENV_EXECUTABLE" "$_MALIAS_PY_SCRIPT" "$@"
            ;;
        *)
            "$_PYTHON_VENV_EXECUTABLE" "$_MALIAS_PY_SCRIPT" "$@"
            _generate_cache "aliases.sh" $_PYTHON_VENV_EXECUTABLE $_MALIAS_PY_SCRIPT
            ;;
    esac
}
