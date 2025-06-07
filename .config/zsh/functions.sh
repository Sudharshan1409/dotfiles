#!/bin/bash

# --- Paths ---
# These variables provide a clear, single source of truth for file locations.
_PYTHON_VENV_EXECUTABLE="$HOME/.config/zsh/venv/bin/python3"
_MFUNC_PY_SCRIPT="$HOME/.config/zsh/python/mfunc.py"

# --- Sanity Check ---
# Ensure the core Python script exists before trying to use it.
if [ ! -f "$_MFUNC_PY_SCRIPT" ]; then
    echo "Error: Function manager script not found at $_MFUNC_PY_SCRIPT" >&2
    return 1
fi

# --- FUNCTION LOADER ---
# On shell startup, this executes the python script's 'load' command.
# The python script prints all functions in a `name() { ... }` format.
# `eval` executes these definitions, loading them into the current shell session.
eval "$("$_PYTHON_VENV_EXECUTABLE" "$_MFUNC_PY_SCRIPT" load)"

# --- MANAGEMENT FUNCTION (mfunc) ---
# This shell function is a wrapper around the Python script, enabling
# interactive management of your functions.
function mfunc() {
    local command="$1"

    # For commands that modify the shell's state (add, edit, rm), we need
    # to source the changes. For others (list), we can just run the script.
    case "$command" in
        add|edit|rm)
            # Create a temporary file to communicate commands from the Python
            # script back to this parent shell.
            local tmpfile
            tmpfile=$(mktemp) || return 1

            # Execute the python script, telling it to write shell commands
            # (e.g., `my_func() {..}` or `unset -f my_func`) to our temp file.
            "$_PYTHON_VENV_EXECUTABLE" "$_MFUNC_PY_SCRIPT" --outfile "$tmpfile" "$@"
            local exit_code=$?

            # If the script ran successfully AND wrote content to the temp file,
            # source it to apply the changes to the current shell session.
            if [[ $exit_code -eq 0 && -s "$tmpfile" ]]; then
                # shellcheck source=/dev/null
                source "$tmpfile"
            fi

            # Clean up the temporary file regardless of the outcome.
            rm -f "$tmpfile"
            ;;
        *)
            # For commands like 'list' or 'help', no state change is needed.
            # Just execute the script directly and show its output.
            "$_PYTHON_VENV_EXECUTABLE" "$_MFUNC_PY_SCRIPT" "$@"
            ;;
    esac
}
