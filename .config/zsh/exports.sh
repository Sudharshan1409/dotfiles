#!/bin/bash
# Starship configuration
export STARSHIP_CONFIG=~/.config/starship/starship.toml

# npm global path
export PATH=~/.npm-global/bin:$PATH

# API keys
OPENAI_API_KEY=$(pass show work/code/ai/openai)
GOOGLE_SEARCH_API_KEY=$(pass show work/code/ai/google/apiKey)
GOOGLE_SEARCH_ENGINE_ID=$(pass show work/code/ai/google/engineId)

export OPENAI_API_KEY GOOGLE_SEARCH_API_KEY GOOGLE_SEARCH_ENGINE_ID

# Bat theme
export BAT_THEME=tokyonight_night

# ssh commands
eval "$(ssh-agent -s)" > /dev/null 2>&1
ssh-add --apple-use-keychain ~/.ssh/id_ed25519 > /dev/null 2>&1
