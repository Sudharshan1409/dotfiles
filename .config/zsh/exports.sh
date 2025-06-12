#!/bin/bash

_PYTHON_VENV_EXECUTABLE="$HOME/.config/zsh/venv/bin/python3"
_MENV_PY_SCRIPT="$HOME/.config/zsh/python/menv.py"

# On shell startup, execute the python script's 'load' command.
eval "$("$_PYTHON_VENV_EXECUTABLE" "$_MENV_PY_SCRIPT" load)"

# --- vvv THIS IS THE UPDATED FUNCTION vvv ---
function menv() {
    local command="$1"

    case "$command" in
        add|rm)
            # For commands that modify the shell, use a temp file
            local tmpfile
            tmpfile=$(mktemp) || return 1

            # Execute the python script, telling it to write shell commands
            # (e.g., `export FOO=bar` or `unset FOO`) to our temp file.
            "$_PYTHON_VENV_EXECUTABLE" "$_MENV_PY_SCRIPT" --outfile "$tmpfile" "$@"
            local exit_code=$?

            # If the script ran successfully AND wrote content, source it.
            if [[ $exit_code -eq 0 && -s "$tmpfile" ]]; then
                # shellcheck source=/dev/null
                source "$tmpfile"
            fi

            rm -f "$tmpfile"
            ;;
        *)
            # For 'ls' or help, just run the script directly.
            "$_PYTHON_VENV_EXECUTABLE" "$_MENV_PY_SCRIPT" "$@"
            ;;
    esac
}
