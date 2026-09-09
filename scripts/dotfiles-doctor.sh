#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Doctor - Health Check & Environment Verification
# ==============================================================================
# Validates symlinks, CLI tools, Wayland components, GPG signing, and fonts.
# ==============================================================================

BOLD="\033[1m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
BLUE="\033[1;34m"
DIM="\033[2m"
RESET="\033[0m"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

check_pass() {
    echo -e "  ${GREEN}✓ [PASS]${RESET} $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

check_warn() {
    echo -e "  ${YELLOW}⚠ [WARN]${RESET} $1"
    WARN_COUNT=$((WARN_COUNT + 1))
}

check_fail() {
    echo -e "  ${RED}✗ [FAIL]${RESET} $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

check_info() {
    echo -e "  ${BLUE}ℹ [INFO]${RESET} $1"
}

section_header() {
    echo -e "\n${BOLD}${CYAN}=== $1 ===${RESET}"
}

# Resolve real path in case called via symlink in ~/.local/bin
REAL_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
DOTFILES_DIR="$(cd "$(dirname "$REAL_SCRIPT_PATH")/.." && pwd)"

echo -e "${BOLD}==================================================================${RESET}"
echo -e "${BOLD}              🩺 Dotfiles Health Check (Doctor)                    ${RESET}"
echo -e "${BOLD}==================================================================${RESET}"

# ------------------------------------------------------------------------------
# 1. OS & Desktop Environment
# ------------------------------------------------------------------------------
section_header "1. OS & Session Environment"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    check_pass "Operating System: $PRETTY_NAME ($ID)"
else
    check_warn "Unable to detect OS from /etc/os-release"
fi

if [ -n "$WAYLAND_DISPLAY" ]; then
    check_pass "Display Server: Wayland active ($WAYLAND_DISPLAY)"
else
    check_warn "WAYLAND_DISPLAY is not set (not inside Wayland session?)"
fi

if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    HYPR_VER=$(hyprctl version 2>/dev/null | grep -E "^Hyprland" | head -n 1 || echo "Active")
    check_pass "Compositor: $HYPR_VER"
else
    check_warn "Hyprland is not running or signature missing"
fi

SHELL_NAME=$(basename "$SHELL")
if [ "$SHELL_NAME" = "zsh" ]; then
    check_pass "User Default Shell: zsh ($($SHELL --version | head -n 1))"
else
    check_warn "User Default Shell is $SHELL_NAME (expected zsh)"
fi

# ------------------------------------------------------------------------------
# 2. Dotfiles Symlink Integrity
# ------------------------------------------------------------------------------
section_header "2. Symlink Integrity (GNU Stow)"
CHECK_LINKS=(
    "$HOME/.config/hypr:$DOTFILES_DIR/hypr/.config/hypr"
    "$HOME/.config/waybar:$DOTFILES_DIR/waybar/.config/waybar"
    "$HOME/.config/swaync:$DOTFILES_DIR/swaync/.config/swaync"
    "$HOME/.config/nvim:$DOTFILES_DIR/nvim/.config/nvim"
    "$HOME/.config/rofi:$DOTFILES_DIR/rofi/.config/rofi"
    "$HOME/.zshrc:$DOTFILES_DIR/zsh/.zshrc"
    "$HOME/.config/tmux:$DOTFILES_DIR/tmux/.config/tmux"
    "$HOME/.config/yazi:$DOTFILES_DIR/yazi/.config/yazi"
)

for pair in "${CHECK_LINKS[@]}"; do
    LINK="${pair%%:*}"
    TARGET="${pair##*:}"
    NAME=$(basename "$LINK")
    if [ -L "$LINK" ]; then
        RESOLVED=$(readlink -f "$LINK")
        if [ "$RESOLVED" = "$TARGET" ]; then
            check_pass "$LINK -> $TARGET"
        else
            check_warn "$LINK symlink exists but points to $RESOLVED (expected $TARGET)"
        fi
    elif [ -e "$LINK" ]; then
        check_warn "$LINK exists as a regular file/directory, not a stow symlink"
    else
        check_fail "$LINK is missing!"
    fi
done

# ------------------------------------------------------------------------------
# 3. Core System & Wayland Tools
# ------------------------------------------------------------------------------
section_header "3. Wayland Desktop Components"
WAYLAND_TOOLS=(hyprland waybar swaync hyprlock hypridle rofi grim slurp satty cliphist pamixer playerctl brightnessctl)
for tool in "${WAYLAND_TOOLS[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        check_pass "Tool available: $tool"
    else
        check_fail "Missing Wayland tool: $tool"
    fi
done

if command -v swww >/dev/null 2>&1; then
    check_pass "Wallpaper daemon: swww (smooth GPU transitions enabled)"
elif command -v hyprpaper >/dev/null 2>&1; then
    check_pass "Wallpaper daemon: hyprpaper"
else
    check_warn "No wallpaper daemon found (install swww or hyprpaper)"
fi

# ------------------------------------------------------------------------------
# 4. Core CLI & Development Utilities
# ------------------------------------------------------------------------------
section_header "4. CLI & Development Utilities"
CLI_TOOLS=(git nvim tmux zellij fzf zoxide lsd bat delta lazygit fd rg jq tldr shellcheck)
for tool in "${CLI_TOOLS[@]}"; do
    RESOLVED_TOOL="$tool"
    [ "$tool" = "delta" ] && command -v git-delta >/dev/null 2>&1 && RESOLVED_TOOL="git-delta"
    [ "$tool" = "rg" ] && command -v ripgrep >/dev/null 2>&1 && RESOLVED_TOOL="ripgrep"
    
    if command -v "$RESOLVED_TOOL" >/dev/null 2>&1 || command -v "$tool" >/dev/null 2>&1; then
        check_pass "CLI utility: $tool"
    else
        check_fail "Missing CLI utility: $tool"
    fi
done

# ------------------------------------------------------------------------------
# 5. Required User Directories & Assets
# ------------------------------------------------------------------------------
section_header "5. Directory Structure & Assets"
DIRS=(
    "$HOME/Pictures/Pics"
    "$HOME/Pictures/Screenshots"
    "$HOME/wezterm-wallpapers"
    "$HOME/.local/bin"
)
for dir in "${DIRS[@]}"; do
    if [ -d "$dir" ]; then
        check_pass "Directory exists: ~/${dir#$HOME/}"
    else
        check_warn "Directory missing: ~/${dir#$HOME/}"
    fi
done

if [ -f "$HOME/Pictures/Pics/dp_professional.png" ] || [ -f "$HOME/Pictures/Pics/dp_professional.jpeg" ] || [ -f "$HOME/Pictures/Pics/dp_passport_size.jpeg" ]; then
    check_pass "Profile picture present in ~/Pictures/Pics/"
else
    check_warn "Profile picture missing in ~/Pictures/Pics/ (needed by hyprlock)"
fi

if [ -f "$HOME/.cache/hypr/lockscreen_info.json" ]; then
    if jq empty "$HOME/.cache/hypr/lockscreen_info.json" 2>/dev/null; then
        check_pass "Lockscreen info cache valid JSON (~/.cache/hypr/lockscreen_info.json)"
    else
        check_fail "Lockscreen info cache is corrupt JSON"
    fi
else
    check_warn "Lockscreen info cache not yet generated"
fi

# ------------------------------------------------------------------------------
# 6. Nerd Fonts
# ------------------------------------------------------------------------------
section_header "6. Fonts & Typography"
if command -v fc-list >/dev/null 2>&1; then
    if fc-list : family | grep -q -i "JetBrainsMono Nerd Font"; then
        check_pass "Font: JetBrainsMono Nerd Font installed"
    else
        check_warn "JetBrainsMono Nerd Font not detected in font cache"
    fi

    if fc-list : family | grep -q -i "Symbols Nerd Font"; then
        check_pass "Font: Symbols Nerd Font installed"
    else
        check_warn "Symbols Nerd Font not detected in font cache"
    fi
else
    check_warn "fc-list utility not available"
fi

# ------------------------------------------------------------------------------
# 7. Git & GPG Signing Readiness
# ------------------------------------------------------------------------------
section_header "7. Git & GPG Signing"
if command -v gpg >/dev/null 2>&1; then
    KEY_COUNT=$(gpg --list-secret-keys 2>/dev/null | grep -c "^sec" || true)
    if [ "$KEY_COUNT" -gt 0 ]; then
        check_pass "GPG Keyring: Found $KEY_COUNT secret key(s)"
        
        GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long 2>/dev/null | grep "^sec" | awk '{print $2}' | head -n 1)
        check_info "Primary Key ID: $GPG_KEY_ID"
        
        # Check git configuration
        GIT_SIGNING=$(git config --get commit.gpgsign 2>/dev/null || echo "false")
        GIT_KEY=$(git config --get user.signingkey 2>/dev/null || echo "unset")
        
        if [ "$GIT_SIGNING" = "true" ]; then
            check_pass "Git commit signing enabled (commit.gpgsign=true)"
        else
            check_warn "Git commit signing is disabled (commit.gpgsign=$GIT_SIGNING)"
        fi
        
        if [ "$GIT_KEY" != "unset" ]; then
            check_pass "Git signing key configured ($GIT_KEY)"
        else
            check_warn "Git user.signingkey is unset"
        fi
    else
        check_warn "No GPG secret keys found in keyring"
    fi
else
    check_fail "GPG is not installed"
fi

# ------------------------------------------------------------------------------
# Final Summary
# ------------------------------------------------------------------------------
TOTAL_CHECKS=$((PASS_COUNT + WARN_COUNT + FAIL_COUNT))
echo -e "\n${BOLD}==================================================================${RESET}"
echo -e "${BOLD}  Health Check Summary: ${GREEN}$PASS_COUNT passed${RESET}, ${YELLOW}$WARN_COUNT warnings${RESET}, ${RED}$FAIL_COUNT failed${RESET} (out of $TOTAL_CHECKS checks)"
echo -e "${BOLD}==================================================================${RESET}"

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}🎉 System is healthy and dotfiles are fully operational!${RESET}\n"
    exit 0
else
    echo -e "${RED}${BOLD}⚠ Some critical components require attention. See failures above.${RESET}\n"
    exit 1
fi
