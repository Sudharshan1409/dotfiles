#!/bin/zsh

# --- Paths ---
_MFUNC_PY_SCRIPT="$_PYTHON_DIR/mfunc.py"

# --- Sanity Check ---
if [ ! -f "$_MFUNC_PY_SCRIPT" ]; then
    echo "Error: Function manager script not found at $_MFUNC_PY_SCRIPT" >&2
    return 1
fi

_load_cache "functions.sh" $_PYTHON_VENV_EXECUTABLE $_MFUNC_PY_SCRIPT

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
                _generate_cache "functions.sh" $_PYTHON_VENV_EXECUTABLE $_MFUNC_PY_SCRIPT
            fi
            rm -f "$tmpfile"
            ;;
        ls|help|run|"")
            "$_PYTHON_VENV_EXECUTABLE" "$_MFUNC_PY_SCRIPT" "$@"
            ;;
        *)
            "$_PYTHON_VENV_EXECUTABLE" "$_MFUNC_PY_SCRIPT" "$@"
            _generate_cache "functions.sh" $_PYTHON_VENV_EXECUTABLE $_MFUNC_PY_SCRIPT
            ;;
    esac
}
