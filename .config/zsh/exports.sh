#!/bin/bash
# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"
eval "$(starship init zsh)"

# Starship exports
export STARSHIP_CONFIG=~/.config/starship/starship.toml

# Override fzf commands
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git "
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
export FZF_COMPLETION_TRIGGER="**"

export FZF_DEFAULT_OPTS="--height 50% --layout=default --border --color=hl:#2dd4bf --reverse"

# fzf default for tmux
export FZF_TMUX_OPTS=" -p90%,70% "

# Setup fzf previews
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always -n --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# export npm global path

export PATH=~/.npm-global/bin:$PATH

# Load API keys from a JSON configuration file
# OPENAI_CONFIG_FILE="$HOME/.config/creds/openai.json"
# GOOGLE_CONFIG_FILE="$HOME/.config/creds/google.json"

# if [[ -f "$OPENAI_CONFIG_FILE" ]]; then
#   OPENAI_API_KEY=$(jq -r '.openai_api_key' "$OPENAI_CONFIG_FILE")
#   export OPENAI_API_KEY
# fi
#
# if [[ -f "$GOOGLE_CONFIG_FILE" ]]; then
#   GOOGLE_SEARCH_API_KEY=$(jq -r '.google_search_api_key' "$GOOGLE_CONFIG_FILE")
#   GOOGLE_SEARCH_ENGINE_ID=$(jq -r '.google_search_engine_id' "$GOOGLE_CONFIG_FILE")

#   export GOOGLE_SEARCH_API_KEY
#   export GOOGLE_SEARCH_ENGINE_ID
# fi

OPENAI_API_KEY=$(pass show work/ai/openai/apiKey)
GOOGLE_SEARCH_API_KEY=$(pass show work/google/search/apiKey)
GOOGLE_SEARCH_ENGINE_ID=$(pass show work/google/search/engineId)

export OPENAI_API_KEY
export GOOGLE_SEARCH_API_KEY
export GOOGLE_SEARCH_ENGINE_ID

