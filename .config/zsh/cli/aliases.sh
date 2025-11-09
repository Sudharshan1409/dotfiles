#!/bin/zsh

# --- Paths ---
_VENV_DIR="$HOME/.config/zsh/venv"
_PYTHON_DIR="$HOME/.config/zsh/python"
_PYTHON_VENV_EXECUTABLE="$_VENV_DIR/bin/python3"
_MALIAS_PY_SCRIPT="$_PYTHON_DIR/malias.py"
_REQUIREMENTS_FILE="$_PYTHON_DIR/requirements.txt"

# --- Helper Function for First-Time Setup ---
_setup_alias_manager_venv() {
    echo "Alias Manager: First-time setup detected. Please wait..." >&2
    if [ ! -f "$_REQUIREMENTS_FILE" ]; then
        echo "Error: requirements.txt not found at $_REQUIREMENTS_FILE" >&2
        return 1
    fi
    echo "  -> Found requirements.txt file." >&2
    echo "  -> Creating Python virtual environment at $_VENV_DIR..." >&2
    python3 -m venv "$_VENV_DIR" > /dev/null 2>&1 || { echo "Error: Failed to create venv." >&2; return 1; }
    echo "  -> Installing dependencies from requirements.txt..." >&2
    "$_VENV_DIR/bin/pip" install -r "$_REQUIREMENTS_FILE" > /dev/null 2>&1 || { echo "Error: Failed to install dependencies." >&2; return 1; }
    echo "✅ Alias Manager setup complete. Your shell will now load." >&2
    return 0
}

# --- Sanity Checks & Auto-Setup ---
if [ ! -f "$_PYTHON_VENV_EXECUTABLE" ]; then
    _setup_alias_manager_venv
    if [ $? -ne 0 ]; then
        echo "Alias Manager setup failed. Aborting." >&2
        return 1
    fi
fi
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
        *)
            "$_PYTHON_VENV_EXECUTABLE" "$_MALIAS_PY_SCRIPT" "$@"
            _generate_cache "aliases.sh" $_PYTHON_VENV_EXECUTABLE $_MALIAS_PY_SCRIPT
            ;;
    esac
}
