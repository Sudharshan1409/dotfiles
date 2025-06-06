#!/bin/bash

# --- Paths ---
# Define all necessary paths for clarity and easy modification.
_VENV_DIR="$HOME/.config/zsh/venv"
_PYTHON_DIR="$HOME/.config/zsh/python"
_PYTHON_VENV_EXECUTABLE="$_VENV_DIR/bin/python3"
_MALIAS_PY_SCRIPT="$_PYTHON_DIR/malias.py"
_REQUIREMENTS_FILE="$_PYTHON_DIR/requirements.txt"

# --- Helper Function for First-Time Setup ---
# This function creates the venv and installs packages if they are missing.
_setup_alias_manager_venv() {
    # Print messages to STDERR (> &2) to inform the user without polluting STDOUT.
    echo "Alias Manager: First-time setup detected. Please wait..." >&2
    
    # 1. Check if the user-managed requirements.txt file exists.
    if [ ! -f "$_REQUIREMENTS_FILE" ]; then
        echo "Error: requirements.txt not found at $_REQUIREMENTS_FILE" >&2
        echo "Please create it before proceeding." >&2
        return 1
    fi
    echo "  -> Found requirements.txt file." >&2

    # 2. Create the Python virtual environment.
    echo "  -> Creating Python virtual environment at $_VENV_DIR..." >&2
    # Redirect all output to /dev/null to keep the shell clean.
    python3 -m venv "$_VENV_DIR" > /dev/null 2>&1 || {
        echo "Error: Failed to create virtual environment." >&2
        return 1
    }

    # 3. Install dependencies using pip from the new venv.
    echo "  -> Installing dependencies from requirements.txt..." >&2
    "$_VENV_DIR/bin/pip" install -r "$_REQUIREMENTS_FILE" > /dev/null 2>&1 || {
        echo "Error: Failed to install Python dependencies." >&2
        return 1
    }

    echo "✅ Alias Manager setup complete. Your shell will now load." >&2
    return 0
}


# --- Sanity Checks & Auto-Setup ---
# Check if the venv's Python executable exists.
if [ ! -f "$_PYTHON_VENV_EXECUTABLE" ]; then
    # If not, run the setup function.
    _setup_alias_manager_venv
    # If the setup failed, stop sourcing this script to prevent further errors.
    if [ $? -ne 0 ]; then
        echo "Alias Manager setup failed. Aborting." >&2
        return 1
    fi
fi

# Check if the main Python script exists before trying to use it.
if [ ! -f "$_MALIAS_PY_SCRIPT" ]; then
    echo "Error: Alias script not found at $_MALIAS_PY_SCRIPT" >&2
    return 1
fi


# --- ALIAS LOADER ---
# On shell startup, this loads all aliases from the JSON file.
eval "$("$_PYTHON_VENV_EXECUTABLE" "$_MALIAS_PY_SCRIPT" load)"


# --- MANAGEMENT FUNCTION ---
# This function uses a temporary file to communicate between the
# interactive python script and the parent shell. This avoids all deadlocks.
function malias() {
    local command="$1"

    case "$command" in
        add|edit|rm)
            local tmpfile
            tmpfile=$(mktemp) || return 1

            # Put the global --outfile option BEFORE the subcommand and its arguments ($@).
            "$_PYTHON_VENV_EXECUTABLE" "$_MALIAS_PY_SCRIPT" --outfile "$tmpfile" "$@"
            local exit_code=$?

            # If the script succeeded and wrote a command to the temp file, source it.
            if [[ $exit_code -eq 0 && -s "$tmpfile" ]]; then
                source "$tmpfile"
            fi

            # Clean up the temporary file.
            rm -f "$tmpfile"
            ;;
        *)
            # All other commands (like 'list') can be run normally.
            "$_PYTHON_VENV_EXECUTABLE" "$_MALIAS_PY_SCRIPT" "$@"
            ;;
    esac
}
