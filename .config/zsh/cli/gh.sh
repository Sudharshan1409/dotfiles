#!/usr/bin/env zsh

# --- Paths ---
_VENV_DIR="$HOME/.config/zsh/venv"
_PYTHON_DIR="$HOME/.config/zsh/python"
_PYTHON_VENV_EXECUTABLE="$_VENV_DIR/bin/python3"
_MGITHUB_PY_SCRIPT="$_PYTHON_DIR/mgithub.py"

# --- Sanity Checks ---
# The venv check is likely already done by aliases.sh, but it's good practice
if [ ! -f "$_PYTHON_VENV_EXECUTABLE" ]; then
    echo "Error: Python virtual environment not found. Please run 'enigma alias' once to trigger setup." >&2
    return 1
fi
if [ ! -f "$_MGITHUB_PY_SCRIPT" ]; then
    echo "Error: GitHub script not found at $_MGITHUB_PY_SCRIPT" >&2
    return 1
fi


# _mgithub_cmd: Main entry point for the 'enigma gh' command.
# Dispatches to Python backend for core logic.
_mgithub_cmd() {
    # If no subcommand is provided, show help.
    if [[ $# -eq 0 ]]; then
        print -P "%BUsage:%b enigma gh %F{cyan}<subcommand>%f [options]"
        print ""
        print -P "Interact with GitHub from the command line."
        print ""
        print -P "%BAvailable Subcommands:%b"
        print -P "  %F{yellow}repos%f     Browse and manage your GitHub repositories"
        print ""
        return 1
    fi

    local subcommand="$1"
    shift

    case "$subcommand" in
        repos)
            # Call the Python backend for repository browsing
            # Pass the rest of the arguments to the python script
            local tmpfile
            tmpfile=$(mktemp) || return 1
            
            # Run python script directly, passing the outfile path
            "$_PYTHON_VENV_EXECUTABLE" "$_MGITHUB_PY_SCRIPT" repos --outfile "$tmpfile" "$@"
            local exit_code=$?

            if [[ $exit_code -eq 0 && -s "$tmpfile" ]]; then
                # Read the command from the temp file and execute it
                local cmd_to_run
                cmd_to_run=$(cat "$tmpfile")
                if [[ -n "$cmd_to_run" ]]; then
                    eval "$cmd_to_run"
                    local eval_exit_code=$?

                    # If the command was a successful clone, register it in the DB
                    if [[ $eval_exit_code -eq 0 && "$cmd_to_run" == "gh repo clone"* ]]; then
                        local repo_name=$(echo "$cmd_to_run" | awk '{print $4}')
                        # Path can contain spaces, so grab everything from the 5th token onwards
                        local final_path=$(echo "$cmd_to_run" | cut -d' ' -f5-)
                        
                        # Register the successful clone
                        "$_PYTHON_VENV_EXECUTABLE" "$_MGITHUB_PY_SCRIPT" register-clone --repo-name "$repo_name" --path "$final_path"
                    fi
                fi
            fi
            rm -f "$tmpfile"
            ;;
        *)
            echo "Error: Unknown gh subcommand '$subcommand'" >&2
            # Call self with no args to show help
            _mgithub_cmd
            return 1
            ;;
    esac
}