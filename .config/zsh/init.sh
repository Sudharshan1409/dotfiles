#!/bin/bash
export EDITOR="nvim"
export VISUAL="nvim"

# Source all the component loaders
source "$HOME/.config/zsh/exports.sh"
source "$HOME/.config/zsh/aliases.sh"
source "$HOME/.config/zsh/functions.sh"
source "$HOME/.config/zsh/tmux.sh"
source "$HOME/.config/zsh/fzf/fzf.sh"

# Source the master command dispatcher
source "$HOME/.config/zsh/dispatcher.sh"
