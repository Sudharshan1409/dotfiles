#!/bin/bash

# --- Paths ---
_PYTHON_VENV_EXECUTABLE="$HOME/.config/zsh/venv/bin/python3"
_MFUNC_PY_SCRIPT="$HOME/.config/zsh/python/mfunc.py"

# --- Sanity Check ---
if [ ! -f "$_MFUNC_PY_SCRIPT" ]; then
    echo "Error: Function manager script not found at $_MFUNC_PY_SCRIPT" >&2
    return 1
fi

# --- FUNCTION LOADER ---
# On shell startup, this loads all Zsh functions and Python function wrappers.
eval "$("$_PYTHON_VENV_EXECUTABLE" "$_MFUNC_PY_SCRIPT" load)"

# --- MANAGEMENT FUNCTION (mfunc) ---
function mfunc() {
    local command="$1"

    # For commands that modify the shell's state (add, edit, rm), we need
    # to source the changes from a temporary file.
    # For all other commands (list, run, help), we can just execute the
    # script directly and pass all arguments through.
    case "$command" in
        add|edit|rm)
            local tmpfile
            tmpfile=$(mktemp) || return 1

            "$_PYTHON_VENV_EXECUTABLE" "$_MFUNC_PY_SCRIPT" --outfile "$tmpfile" "$@"
            local exit_code=$?

            if [[ $exit_code -eq 0 && -s "$tmpfile" ]]; then
                # shellcheck source=/dev/null
                source "$tmpfile"
            fi

            rm -f "$tmpfile"
            ;;
        *)
            # For 'list', 'run', or any other command.
            "$_PYTHON_VENV_EXECUTABLE" "$_MFUNC_PY_SCRIPT" "$@"
            ;;
    esac
}
