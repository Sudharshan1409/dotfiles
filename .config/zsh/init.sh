#!/bin/bash
export EDITOR="nvim"
export VISUAL="nvim"

# Source all the component loaders from their new location in the 'cli' directory
source "$HOME/.config/zsh/cli/exports.sh"
source "$HOME/.config/zsh/cli/aliases.sh"
source "$HOME/.config/zsh/cli/functions.sh"
source "$HOME/.config/zsh/cli/snippets.sh"
source "$HOME/.config/zsh/cli/projects.sh"

# Source non-CLI configuration files
source "$HOME/.config/zsh/tmux.sh"
source "$HOME/.config/zsh/fzf/fzf.sh"

# Source the master command dispatcher from its new location
source "$HOME/.config/zsh/cli/dispatcher.sh"
