#!/usr/bin/env zsh
# ==============================================================================
# Productivity Functions & Utilities (ftldr, update-all, etc.)
# ==============================================================================

# Interactive TLDR launcher using fzf and syntax-highlighted preview
ftldr() {
    if ! command -v tldr >/dev/null 2>&1; then
        echo "tldr is not installed. Run your setup script or brew install tldr." >&2
        return 1
    fi

    local selected
    selected=$(tldr --list 2>&1 | sed -r 's/\x1b\[[0-9;]*m//g' | grep -v 'Pages for' | grep -v '^[[:space:]]*$' | sort -u | \
        fzf --prompt="🔍 tldr > " \
            --preview='tldr --color=always {} 2>/dev/null || tldr {}' \
            --preview-window='right:65%:wrap' \
            --header="Enter: View | Esc: Cancel")

    if [ -n "$selected" ]; then
        if command -v bat >/dev/null 2>&1; then
            tldr --color=always "$selected" 2>/dev/null | bat -p -l markdown 2>/dev/null || tldr "$selected"
        else
            tldr "$selected"
        fi
    fi
}

# Universal update script: system packages, brew, flatpaks, nvim plugins, tldr cache
update-all() {
    echo -e "\033[1;34m🔄 Starting universal system update...\033[0m\n"

    # 1. System package manager (Arch pacman/yay or Ubuntu apt)
    if command -v pacman >/dev/null 2>&1; then
        echo -e "\033[1;36m📦 Updating Pacman & AUR packages...\033[0m"
        if command -v yay >/dev/null 2>&1; then
            yay -Syu --noconfirm
        elif command -v paru >/dev/null 2>&1; then
            paru -Syu --noconfirm
        else
            sudo pacman -Syu --noconfirm
        fi
    elif command -v apt-get >/dev/null 2>&1; then
        echo -e "\033[1;36m📦 Updating APT packages...\033[0m"
        sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && sudo apt-get autoremove -y
    fi

    # 2. Homebrew packages (if installed)
    if command -v brew >/dev/null 2>&1; then
        echo -e "\n\033[1;36m🍺 Updating Homebrew packages...\033[0m"
        brew update && brew upgrade && brew cleanup
    fi

    # 3. Flatpaks (if installed)
    if command -v flatpak >/dev/null 2>&1; then
        echo -e "\n\033[1;36m📦 Updating Flatpak applications...\033[0m"
        flatpak update -y
    fi

    # 4. Neovim plugins via Lazy.nvim headless sync (if nvim installed)
    if command -v nvim >/dev/null 2>&1; then
        echo -e "\n\033[1;36m💤 Updating Neovim plugins...\033[0m"
        nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
        echo "✓ Neovim plugins synchronized"
    fi

    # 5. TLDR cache (if tldr installed)
    if command -v tldr >/dev/null 2>&1; then
        echo -e "\n\033[1;36m📖 Updating TLDR cheatsheets database...\033[0m"
        tldr --update >/dev/null 2>&1 || true
        echo "✓ TLDR database updated"
    fi

    # 6. Lockscreen cache refresh
    if [ -x "$HOME/.config/hypr/scripts/cache_lockscreen_info.sh" ]; then
        "$HOME/.config/hypr/scripts/cache_lockscreen_info.sh" 2>/dev/null || true
    fi

    echo -e "\n\033[1;32m✅ Universal update complete!\033[0m\n"
}
