#!/bin/zsh
export EDITOR="nvim"
export VISUAL="nvim"

# Source the cache manager
source "$HOME/.config/zsh/cache_manager.sh"
_load_cache # Call the function to load/generate cache

# Source the projects script (not managed by cache)
source "$HOME/.config/zsh/cli/projects.sh"

# Source non-CLI configuration files
source "$HOME/.config/zsh/tmux.sh"

# Source the master command dispatcher from its new location
source "$HOME/.config/zsh/cli/dispatcher.sh"

# Source fzf configuration last
source "$HOME/.config/zsh/fzf/fzf.sh"
