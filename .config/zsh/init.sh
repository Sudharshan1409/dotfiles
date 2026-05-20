#!/bin/zsh
export EDITOR="nvim"
export VISUAL="nvim"

# Shared paths used by every cli/*.sh
_VENV_DIR="$HOME/.config/zsh/venv"
_PYTHON_DIR="$HOME/.config/zsh/python"
_PYTHON_VENV_EXECUTABLE="$_VENV_DIR/bin/python3"
_REQUIREMENTS_FILE="$_PYTHON_DIR/requirements.txt"

# First-time setup: bootstrap the Python venv used by every enigma manager.
# Must run before any cli/*.sh is sourced, since they all call into the venv.
_setup_enigma_venv() {
    echo "Enigma: First-time setup detected. Please wait..." >&2
    if [ ! -f "$_REQUIREMENTS_FILE" ]; then
        echo "Error: requirements.txt not found at $_REQUIREMENTS_FILE" >&2
        return 1
    fi
    echo "  -> Found requirements.txt file." >&2
    echo "  -> Creating Python virtual environment at $_VENV_DIR..." >&2
    python3 -m venv "$_VENV_DIR" > /dev/null 2>&1 || { echo "Error: Failed to create venv." >&2; return 1; }
    echo "  -> Installing dependencies from requirements.txt..." >&2
    "$_VENV_DIR/bin/pip" install -r "$_REQUIREMENTS_FILE" > /dev/null 2>&1 || { echo "Error: Failed to install dependencies." >&2; return 1; }
    echo "✅ Enigma setup complete. Your shell will now load." >&2
    return 0
}

if [ ! -f "$_PYTHON_VENV_EXECUTABLE" ]; then
    _setup_enigma_venv
    if [ $? -ne 0 ]; then
        echo "Enigma setup failed. Aborting." >&2
        return 1
    fi
fi

# Source all the component loaders from their new location in the 'cli' directory
source "$HOME/.config/zsh/cache_manager.sh"
source "$HOME/.config/zsh/cli/exports.sh"
source "$HOME/.config/zsh/cli/aliases.sh"
source "$HOME/.config/zsh/cli/functions.sh"
source "$HOME/.config/zsh/cli/projects.sh"
source "$HOME/.config/zsh/cli/gh.sh"
source "$HOME/.config/zsh/cli/ai.sh"

# Source non-CLI configuration files
source "$HOME/.config/zsh/tmux.sh"

# Source the master command dispatcher from its new location
source "$HOME/.config/zsh/cli/dispatcher.sh"

# Tab completion for `enigma` / `en` (depends on compinit, which fzf.sh
# triggers via `eval "$(fzf --zsh)"` earlier in this file)
source "$HOME/.config/zsh/cli/completion.zsh"
