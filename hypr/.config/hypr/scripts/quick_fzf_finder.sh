#!/bin/bash
# ==============================================================================
# Quick FZF Finder (Floating Ghostty)
# Interactive file & folder search starting from $HOME with instant preview.
# - Folder Mode: Opens selected directory in Yazi inside a new Ghostty terminal.
# - File Mode: Opens code/text files in Neovim, media/other files in default apps.
# ==============================================================================

export PATH="$HOME/.local/bin:/home/linuxbrew/.linuxbrew/bin:/usr/local/bin:$PATH"
export EDITOR="nvim"
export VISUAL="nvim"

# If invoked without --run, launch the large floating Ghostty window
if [ "$1" != "--run" ]; then
    hyprctl dispatch exec "[float; size 88% 85%; center] ghostty --gtk-single-instance=false -e $HOME/.config/hypr/scripts/quick_fzf_finder.sh --run"
    exit 0
fi

# Set window title for Hyprland windowrule matching
printf "\033]0;Quick-FZF-Finder\007"

# Enforce window size and position directly via hyprctl
ADDR=$(hyprctl activewindow -j 2>/dev/null | jq -r '.address // empty')
if [ -n "$ADDR" ]; then
    MON_INFO=$(hyprctl monitors -j 2>/dev/null | jq '.[] | select(.focused == true) // .[0]')
    MON_W=$(echo "$MON_INFO" | jq -r '.width // 1920')
    MON_H=$(echo "$MON_INFO" | jq -r '.height // 1080')
    SCALE=$(echo "$MON_INFO" | jq -r '.scale // 1')

    LOGICAL_W=$(python3 -c "import sys; print(int(float(sys.argv[1]) / float(sys.argv[2])))" "$MON_W" "$SCALE" 2>/dev/null || echo 1920)
    LOGICAL_H=$(python3 -c "import sys; print(int(float(sys.argv[1]) / float(sys.argv[2])))" "$MON_H" "$SCALE" 2>/dev/null || echo 1080)

    TARGET_W=$(( LOGICAL_W * 88 / 100 ))
    TARGET_H=$(( LOGICAL_H * 85 / 100 ))

    hyprctl dispatch setfloating address:$ADDR >/dev/null 2>&1
    hyprctl dispatch resizewindowpixel exact ${TARGET_W} ${TARGET_H},address:$ADDR >/dev/null 2>&1
    hyprctl dispatch centerwindow address:$ADDR >/dev/null 2>&1
fi

cd "$HOME" || exit 1

# Step 1: Mode Selection
MODE=$(printf "📁 Folders (Search & open in Yazi)\n📄 Files   (Search & open in Neovim / Default App)\n" | fzf \
    --height=100% \
    --layout=reverse \
    --border=rounded \
    --border-label=" 🔍 Quick Finder: Mode Selection " \
    --border-label-pos=3 \
    --prompt="Finder Mode > " \
    --header="⚡ Select mode with [Enter] (or [Esc] to quit)  •  You can also switch anytime with Ctrl-D / Ctrl-F" \
    --color="header:italic:cyan,prompt:bold:cyan,pointer:bold:magenta" \
    --no-info)

[ -z "$MODE" ] && exit 0

FD_COMMON="--hidden --exclude .git --exclude node_modules --exclude .cache --exclude .local/share/Trash --exclude .steam --exclude .cargo --exclude .rustup --strip-cwd-prefix"

PREVIEW_SCRIPT='
TARGET="$HOME/{}"
if [ -d "$TARGET" ]; then
    eza --tree --level=2 --color=always --icons=always "$TARGET" 2>/dev/null || lsd --tree --depth 2 --color=always "$TARGET" 2>/dev/null
else
    bat --style=numbers --color=always --line-range :200 "$TARGET" 2>/dev/null || cat "$TARGET" 2>/dev/null
fi
'

if [[ "$MODE" =~ "Folders" ]]; then
    INITIAL_CMD="fd --type d $FD_COMMON"
    INITIAL_PROMPT="📁 Folders > "
    INITIAL_HEADER="⚡ ACTIVE MODE: 📁 FOLDERS  |  Press [Ctrl-F] for Files  |  [Enter] Open in Yazi  |  [Esc] Quit"
else
    INITIAL_CMD="fd --type f $FD_COMMON"
    INITIAL_PROMPT="📄 Files > "
    INITIAL_HEADER="⚡ ACTIVE MODE: 📄 FILES    |  Press [Ctrl-D] for Folders  |  [Enter] Open in Neovim/App  |  [Esc] Quit"
fi

SELECTED=$(eval "$INITIAL_CMD" | fzf \
    --height=100% \
    --border=rounded \
    --border-label=" ⚡ Quick Finder [Ctrl-D: 📁 Folders] [Ctrl-F: 📄 Files] " \
    --border-label-pos=3 \
    --prompt="$INITIAL_PROMPT" \
    --header="$INITIAL_HEADER" \
    --preview="$PREVIEW_SCRIPT" \
    --preview-window="right:55%:wrap" \
    --bind="ctrl-d:change-prompt(📁 Folders > )+reload(fd --type d $FD_COMMON)+change-header(⚡ ACTIVE MODE: 📁 FOLDERS  |  Press [Ctrl-F] for Files  |  [Enter] Open in Yazi  |  [Esc] Quit)" \
    --bind="ctrl-f:change-prompt(📄 Files > )+reload(fd --type f $FD_COMMON)+change-header(⚡ ACTIVE MODE: 📄 FILES    |  Press [Ctrl-D] for Folders  |  [Enter] Open in Neovim/App  |  [Esc] Quit)" \
    --bind="page-up:preview-page-up,page-down:preview-page-down,ctrl-b:preview-page-up" \
    --layout=reverse \
    --color="header:italic:cyan,prompt:bold:cyan,pointer:bold:magenta,info:dim")

[ -z "$SELECTED" ] && exit 0

TARGET="$HOME/$SELECTED"

# Step 2: Dispatch based on selected target
if [ -d "$TARGET" ]; then
    # User selected a directory -> open in Yazi in new Ghostty terminal
    hyprctl dispatch exec "ghostty --working-directory='$TARGET' -e yazi '$TARGET'"
elif [ -f "$TARGET" ]; then
    # User selected a file
    MIME=$(file --mime-type -b "$TARGET" 2>/dev/null)
    EXT="${TARGET##*.}"
    DIRNAME=$(dirname "$TARGET")
    IS_CODE=""

    case "$EXT" in
        lua|py|rs|go|js|ts|jsx|tsx|c|cpp|h|hpp|sh|zsh|bash|json|toml|yaml|yml|md|txt|conf|rasi|css|scss|xml|sql|env|ini|service|desktop)
            IS_CODE=1
            ;;
    esac

    case "$MIME" in
        text/html)
            IS_CODE=""
            ;;
        text/*|application/json|application/javascript|application/xml|application/x-yaml|application/toml|application/x-sh|application/x-shellscript|inode/x-empty)
            IS_CODE=1
            ;;
    esac

    if [ -n "$IS_CODE" ]; then
        # Open in Neovim in a new Ghostty terminal
        hyprctl dispatch exec "ghostty --working-directory='$DIRNAME' -e nvim '$TARGET'"
    else
        # Open in default associated application
        xdg-open "$TARGET" >/dev/null 2>&1 &
    fi
fi

exit 0
