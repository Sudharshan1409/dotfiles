#!/usr/bin/env bash
# ==============================================================================
# Sesh Interactive Picker for Tmux & Shell
# ==============================================================================

# Ensure required tools are available in PATH
export PATH="/home/linuxbrew/.linuxbrew/bin:$HOME/.local/bin:$PATH"

if ! command -v sesh >/dev/null 2>&1; then
    echo "sesh is not installed. Install with 'brew install sesh' or your package manager." >&2
    exit 1
fi

# Run fzf selector with icons and multi-source switching
selected=$(sesh list --icons 2>/dev/null | fzf \
    --height 100% \
    --reverse \
    --no-sort \
    --ansi \
    --border-label ' sesh ' \
    --prompt '⚡  ' \
    --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
    --bind 'tab:down,btab:up' \
    --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons)' \
    --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
    --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' \
    --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
    --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~ 2>/dev/null || find ~ -maxdepth 2 -type d)' \
    --bind 'ctrl-d:execute(tmux kill-session -t {2..} 2>/dev/null)+change-prompt(⚡  )+reload(sesh list --icons)')

[ -z "$selected" ] && exit 0

# Strip any leading emojis, nerd font symbols, icons, and whitespace
session=$(echo "$selected" | sed -E 's/^[^~/a-zA-Z0-9._-]+//; s/^[[:space:]]*//')

[ -z "$session" ] && exit 0

# Expand leading tilde to $HOME if present
session="${session/#\~/$HOME}"

# If inside an existing tmux session, switch client smoothly; otherwise attach/create
if [ -n "$TMUX" ]; then
    sesh connect --switch "$session"
else
    sesh connect "$session"
fi
