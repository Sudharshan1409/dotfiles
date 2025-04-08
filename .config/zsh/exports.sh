#!/bin/bash
# eval "$(starship init zsh)"

# Starship exports
export STARSHIP_CONFIG=~/.config/starship/starship.toml

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

# Bat theme

export BAT_THEME=tokyonight_night
