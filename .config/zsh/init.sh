#!/bin/zsh
export EDITOR="nvim"
export VISUAL="nvim"

# Source all the component loaders from their new location in the 'cli' directory
source "$HOME/.config/zsh/cache_manager.sh"
source "$HOME/.config/zsh/cli/exports.sh"
source "$HOME/.config/zsh/cli/aliases.sh"
source "$HOME/.config/zsh/cli/functions.sh"
source "$HOME/.config/zsh/cli/projects.sh"
source "$HOME/.config/zsh/cli/gh.sh"

# Source non-CLI configuration files
source "$HOME/.config/zsh/tmux.sh"

# Source the master command dispatcher from its new location
source "$HOME/.config/zsh/cli/dispatcher.sh"
