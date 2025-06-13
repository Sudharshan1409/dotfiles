#!/bin/bash

_PYTHON_VENV_EXECUTABLE="$HOME/.config/zsh/venv/bin/python3"
_MENV_PY_SCRIPT="$HOME/.config/zsh/python/menv.py"

# On shell startup, execute the python script's 'load' command.
eval "$("$_PYTHON_VENV_EXECUTABLE" "$_MENV_PY_SCRIPT" load)"

# --- INTERNAL MANAGEMENT FUNCTION ---
function _menv_cmd() {
    local command="$1"
    case "$command" in
        add|rm|edit)
            local tmpfile
            tmpfile=$(mktemp) || return 1
            "$_PYTHON_VENV_EXECUTABLE" "$_MENV_PY_SCRIPT" --outfile "$tmpfile" "$@"
            local exit_code=$?
            if [[ $exit_code -eq 0 && -s "$tmpfile" ]]; then
                source "$tmpfile"
            fi
            rm -f "$tmpfile"
            ;;
        *)
            "$_PYTHON_VENV_EXECUTABLE" "$_MENV_PY_SCRIPT" "$@"
            ;;
    esac
}
