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
    local BOLD="\033[1m"
    local CYAN="\033[1;36m"
    local GREEN="\033[1;32m"
    local BLUE="\033[1;34m"
    local MAGENTA="\033[1;35m"
    local RED="\033[1;31m"
    local DIM="\033[2m"
    local RESET="\033[0m"

    echo -e "\n${BOLD}${MAGENTA}⚡ Enigma CLI${RESET} ${DIM}:: Initializing Runtime Environment${RESET}" >&2
    echo -e "${DIM}───────────────────────────────────────────────────────${RESET}" >&2

    if [ ! -f "$_REQUIREMENTS_FILE" ]; then
        echo -e "  ${RED}✗ [ERROR]${RESET} requirements.txt not found at: ${DIM}$_REQUIREMENTS_FILE${RESET}" >&2
        echo -e "${DIM}───────────────────────────────────────────────────────${RESET}\n" >&2
        return 1
    fi
    echo -e "  ${GREEN}✓${RESET} Located dependencies manifest (${DIM}${_REQUIREMENTS_FILE/#$HOME/~}${RESET})" >&2

    # Ensure uv is installed before configuring the virtual environment
    if ! command -v uv >/dev/null 2>&1; then
        echo -e "  ${BLUE}ℹ${RESET} Installing ${BOLD}uv${RESET} ${DIM}(ultra-fast Python package manager)...${RESET}" >&2
        if command -v brew >/dev/null 2>&1; then
            brew install uv >/dev/null 2>&1
        elif command -v curl >/dev/null 2>&1; then
            curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1
            export PATH="$HOME/.local/bin:$PATH"
        fi
    fi

    if command -v uv >/dev/null 2>&1; then
        echo -e "  ${CYAN}➜${RESET} Creating Python virtual environment via ${BOLD}uv${RESET}..." >&2
        uv venv --allow-existing "$_VENV_DIR" > /dev/null 2>&1 || { echo -e "  ${RED}✗ [ERROR]${RESET} Failed to create venv with uv." >&2; return 1; }
        echo -e "  ${CYAN}➜${RESET} Installing dependencies via ${BOLD}uv${RESET}..." >&2
        uv pip install --python "$_PYTHON_VENV_EXECUTABLE" -r "$_REQUIREMENTS_FILE" > /dev/null 2>&1 || { echo -e "  ${RED}✗ [ERROR]${RESET} Failed to install dependencies." >&2; return 1; }
    else
        echo -e "  ${CYAN}➜${RESET} Creating Python virtual environment at ${DIM}${_VENV_DIR/#$HOME/~}${RESET}..." >&2
        python3 -m venv "$_VENV_DIR" > /dev/null 2>&1 || { echo -e "  ${RED}✗ [ERROR]${RESET} Failed to create venv." >&2; return 1; }
        echo -e "  ${CYAN}➜${RESET} Installing dependencies via pip..." >&2
        "$_VENV_DIR/bin/pip" install -r "$_REQUIREMENTS_FILE" > /dev/null 2>&1 || { echo -e "  ${RED}✗ [ERROR]${RESET} Failed to install dependencies." >&2; return 1; }
    fi

    echo -e "${DIM}───────────────────────────────────────────────────────${RESET}" >&2
    echo -e "  ${GREEN}✨ Enigma runtime setup complete!${RESET} Shell ready.\n" >&2
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
source "$HOME/.config/zsh/cli/productivity.zsh"

# Source non-CLI configuration files
source "$HOME/.config/zsh/tmux.sh"

# Source the master command dispatcher from its new location
source "$HOME/.config/zsh/cli/dispatcher.sh"

# Tab completion for `enigma` / `en` (depends on compinit, which fzf.sh
# triggers via `eval "$(fzf --zsh)"` earlier in this file)
source "$HOME/.config/zsh/cli/completion.zsh"
