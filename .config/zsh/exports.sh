#!/bin/bash
# Starship configuration
export STARSHIP_CONFIG=~/.config/starship/starship.toml

# npm global path
export PATH=~/.npm-global/bin:$PATH

# API keys
OPENAI_API_KEY=$(pass show work/code/ai/openai 2>/dev/null || echo "")
GOOGLE_SEARCH_API_KEY=$(pass show work/code/ai/google/apiKey 2>/dev/null || echo "")
GOOGLE_SEARCH_ENGINE_ID=$(pass show work/code/ai/google/engineId 2>/dev/null || echo "")

export OPENAI_API_KEY GOOGLE_SEARCH_API_KEY GOOGLE_SEARCH_ENGINE_ID

# Bat theme
export BAT_THEME=tokyonight_night

# ssh commands
eval "$(ssh-agent -s)" > /dev/null 2>&1

# Detect OS
OS_TYPE=$(uname)

if [[ "$OS_TYPE" == "Darwin" ]]; then
    # macOS-specific configuration
    eval "$(/opt/homebrew/bin/brew shellenv)"
    export TMUX_PATH="/opt/homebrew/bin/tmux"
    ssh-add --apple-use-keychain ~/.ssh/id_ed25519 > /dev/null 2>&1

elif [[ "$OS_TYPE" == "Linux" ]]; then
    # Linux-specific configuration
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    ssh-add ~/.ssh/id_ed25519

else
  echo "Unknown OS: $OS_TYPE"
fi
