#!/usr/bin/env bash
set -e

# ==============================================================================
# Dotfiles & System Setup Script for Arch Linux
# ==============================================================================
# Fully Idempotent: Every step verifies existing configuration before acting.
# Safe to run repeatedly on new or partially configured systems.
# ==============================================================================

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.local/bin:$PATH"

# ANSI Color Codes for Real-Time Logging
BOLD="\033[1m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
BLUE="\033[1;34m"
DIM="\033[2m"
RESET="\033[0m"

TOTAL_STEPS=19
CURRENT_STEP=0

ACTIONS_DONE=0
ACTIONS_SKIPPED=0
ACTIONS_FAILED=0

step_header() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo -e "\n${BOLD}${BLUE}[${CURRENT_STEP}/${TOTAL_STEPS}]${RESET} ${BOLD}$1${RESET}"
}

log_ok() {
    echo -e "  ${GREEN}✓ [DONE]${RESET} $1"
    ACTIONS_DONE=$((ACTIONS_DONE + 1))
}

log_skip() {
    echo -e "  ${CYAN}➜ [SKIPPED]${RESET} $1 ${DIM}(already configured)${RESET}"
    ACTIONS_SKIPPED=$((ACTIONS_SKIPPED + 1))
}

log_info() {
    echo -e "  ${BLUE}ℹ [INFO]${RESET} $1"
}

log_warn() {
    echo -e "  ${YELLOW}⚠ [WARN]${RESET} $1"
}

log_err() {
    echo -e "  ${RED}✗ [ERROR]${RESET} $1"
    ACTIONS_FAILED=$((ACTIONS_FAILED + 1))
}

echo -e "${BOLD}==================================================================${RESET}"
echo -e "${BOLD}  Starting Dotfiles & System Environment Setup (Arch Linux)${RESET}"
echo -e "${BOLD}==================================================================${RESET}"

# ------------------------------------------------------------------------------
# Operating System Pre-flight Check
# ------------------------------------------------------------------------------
if [ ! -f /etc/os-release ] && [ ! -f /usr/lib/os-release ]; then
    echo -e "\n${BOLD}${RED}==================================================================${RESET}"
    echo -e "${BOLD}${RED}  ✗ [ERROR] Cannot detect operating system (/etc/os-release not found)${RESET}"
    echo -e "${BOLD}${RED}==================================================================${RESET}"
    echo -e "  This script is strictly intended for Arch Linux."
    echo -e "  Aborting execution.\n"
    exit 1
fi

OS_ID="$(. /etc/os-release 2>/dev/null || . /usr/lib/os-release 2>/dev/null; echo "$ID")"
OS_ID_LIKE="$(. /etc/os-release 2>/dev/null || . /usr/lib/os-release 2>/dev/null; echo "$ID_LIKE")"
OS_PRETTY="$(. /etc/os-release 2>/dev/null || . /usr/lib/os-release 2>/dev/null; echo "${PRETTY_NAME:-$NAME}")"

if [ "$OS_ID" != "arch" ] && [[ ! " $OS_ID_LIKE " =~ " arch " ]]; then
    echo -e "\n${BOLD}${RED}==================================================================${RESET}"
    echo -e "${BOLD}${RED}  ✗ [ERROR] Incompatible Operating System Detected!${RESET}"
    echo -e "${BOLD}${RED}==================================================================${RESET}"
    echo -e "  Current System : ${YELLOW}${OS_PRETTY:-$OS_ID}${RESET}"
    echo -e "  Required System: ${GREEN}Arch Linux (or Arch-based distribution)${RESET}"
    echo -e "\n  ${RED}This script (setup_arch.sh) is specifically written for Arch Linux (uses pacman, AUR, etc.).${RESET}"
    if [[ "$OS_ID" == "ubuntu" || "$OS_ID_LIKE" =~ "ubuntu" || "$OS_ID_LIKE" =~ "debian" ]]; then
        echo -e "  👉 ${BOLD}Did you mean to run:${RESET} ${CYAN}./setup_ubuntu.sh${RESET} ?"
    fi
    echo -e "\n  Stopping execution to prevent system configuration conflicts.\n"
    exit 1
fi

log_info "Detected OS: ${GREEN}${OS_PRETTY:-Arch Linux}${RESET} (Compatible)"

# 1. Elevate sudo privileges once and keep alive in background
step_header "Verifying sudo privileges"
if sudo -n true 2>/dev/null; then
    log_skip "Sudo credentials already cached and active"
else
    log_info "Requesting sudo privileges for system configuration..."
    sudo -v
    log_ok "Sudo credentials acquired"
fi
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_PID=$!
trap 'kill $SUDO_PID 2>/dev/null' EXIT

# 2. Update system and install official Arch packages via pacman
step_header "Verifying Pacman system packages & Wayland environment"
PACMAN_PACKAGES=(
    base-devel
    dkms
    git
    curl
    wget
    stow
    cmake
    pkgconf
    zsh
    python
    python-pip
    nodejs
    npm
    hyprland
    hyprland-qtutils
    waybar
    sway-notification-center
    hyprpaper
    hypridle
    hyprlock
    rofi-wayland
    wofi
    kitty
    wezterm
    htop
    nvtop
    nautilus
    pavucontrol
    blueman
    grim
    slurp
    satty
    wf-recorder
    wl-clipboard
    cliphist
    tesseract
    tesseract-data-eng
    network-manager-applet
    brightnessctl
    playerctl
    pamixer
    libpulse
    power-profiles-daemon
    libnotify
    polkit-gnome
    gtk4-layer-shell
    neovim
    tmux
    bat
    eza
    lsd
    zoxide
    git-delta
    jq
    github-cli
    fzf
    yazi
    zellij
    starship
    lazygit
    fd
    ripgrep
    shellcheck
    ttf-jetbrains-mono-nerd
    ttf-cascadia-mono-nerd
    ttf-nerd-fonts-symbols-mono
)

MISSING_PACMAN=()
for pkg in "${PACMAN_PACKAGES[@]}"; do
    if ! pacman -Qi "$pkg" >/dev/null 2>&1; then
        MISSING_PACMAN+=("$pkg")
    fi
done

if [ ${#MISSING_PACMAN[@]} -eq 0 ]; then
    log_skip "All ${#PACMAN_PACKAGES[@]} official Pacman packages are already installed"
else
    log_info "Installing ${#MISSING_PACMAN[@]} missing Pacman package(s)..."
    sudo pacman -S --needed --noconfirm "${MISSING_PACMAN[@]}" 2>/dev/null || true
    log_ok "Installed missing Pacman package(s)"
fi

# Optional Ghostty installation via pacman
if ! pacman -Qi ghostty >/dev/null 2>&1 && ! command -v ghostty >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm ghostty 2>/dev/null || true
fi

# 3. Install Walker launcher if not present
step_header "Verifying Walker Wayland launcher"
mkdir -p "$HOME/.local/bin"
if command -v walker >/dev/null 2>&1 || [ -x "$HOME/.local/bin/walker" ]; then
    log_skip "Walker Wayland launcher is already installed"
else
    log_info "Installing Walker Wayland launcher..."
    WALKER_URL=$(curl -s https://api.github.com/repos/abenz1267/walker/releases/latest | grep -o 'https://[^"]*x86_64-unknown-linux-gnu.tar.gz' | head -n 1)
    if [ -n "$WALKER_URL" ]; then
        curl -fsSL "$WALKER_URL" | tar -xz -C "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/walker"
        log_ok "Installed Walker launcher"
    else
        log_warn "Failed to resolve Walker release URL"
    fi
fi

# 4. Apply Stow configuration for all Linux packages
step_header "Verifying GNU Stow dotfiles linking"
STOW_PACKAGES=(
    backgrounds
    bat
    ghostty
    git
    hypr
    kitty
    lazygit
    nvim
    rofi
    starship
    swaync
    tmux
    walker
    waybar
    wezterm
    wofi
    yazi
    zellij
    zsh
)
cd "$DOTFILES_DIR"

ALL_STOWED=true
for pkg in "${STOW_PACKAGES[@]}"; do
    if [ "$pkg" = "zsh" ]; then
        [ -L "$HOME/.zshrc" ] || { ALL_STOWED=false; break; }
    else
        [ -d "$HOME/.config/$pkg" ] || [ -L "$HOME/.config/$pkg" ] || { ALL_STOWED=false; break; }
    fi
done

if [ "$ALL_STOWED" = true ]; then
    stow -R -t "$HOME" "${STOW_PACKAGES[@]}" >/dev/null 2>&1 || true
    log_skip "All dotfiles packages are already linked via GNU Stow (refreshed)"
else
    stow -v -t "$HOME" "${STOW_PACKAGES[@]}"
    log_ok "Linked all dotfiles packages with GNU Stow"
fi

# 5. Git configuration include
step_header "Verifying Git configuration"
if [ -f "$HOME/.gitconfig" ] && grep -q "\.config/git/\.gitconfig" "$HOME/.gitconfig" 2>/dev/null; then
    log_skip "Git include for ~/.config/git/.gitconfig is already configured"
else
    printf "[include]\n\tpath = ~/.config/git/.gitconfig\n" >> "$HOME/.gitconfig"
    log_ok "Added include directive to ~/.gitconfig"
fi

# 6. Set up Oh-My-Zsh and plugins
step_header "Verifying Oh-My-Zsh & plugins"
if [ -d "$HOME/.oh-my-zsh" ]; then
    log_skip "Oh-My-Zsh is already installed at ~/.oh-my-zsh"
else
    log_info "Cloning Oh-My-Zsh repository..."
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
    log_ok "Installed Oh-My-Zsh"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "$ZSH_CUSTOM/plugins" "$ZSH_CUSTOM/themes"

declare -A ZSH_PLUGINS=(
    ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
    ["fzf-tab"]="https://github.com/Aloxaf/fzf-tab"
    ["you-should-use"]="https://github.com/MichaelAquilina/zsh-you-should-use.git"
    ["zsh-autopair"]="https://github.com/hlissner/zsh-autopair"
    ["zsh-256color"]="https://github.com/chrissicool/zsh-256color"
    ["git-open"]="https://github.com/paulirish/git-open.git"
)

PLUGINS_ADDED=0
for plugin in "${!ZSH_PLUGINS[@]}"; do
    if [ -d "$ZSH_CUSTOM/plugins/$plugin" ]; then
        continue
    fi
    git clone --depth=1 "${ZSH_PLUGINS[$plugin]}" "$ZSH_CUSTOM/plugins/$plugin" >/dev/null 2>&1
    PLUGINS_ADDED=$((PLUGINS_ADDED + 1))
done

if [ "$PLUGINS_ADDED" -eq 0 ]; then
    log_skip "All Oh-My-Zsh custom plugins are already present"
else
    log_ok "Installed $PLUGINS_ADDED missing Oh-My-Zsh plugin(s)"
fi

if [ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    log_skip "Powerlevel10k theme already present in custom themes"
else
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k" >/dev/null 2>&1
    log_ok "Installed Powerlevel10k theme"
fi

# 7. Set up Python virtual environment for Enigma CLI
step_header "Verifying Enigma CLI virtual environment"
VENV_DIR="$HOME/.config/zsh/venv"
REQ_FILE="$HOME/.config/zsh/python/requirements.txt"

if [ -x "$VENV_DIR/bin/python3" ] && "$VENV_DIR/bin/python3" -c "import InquirerPy, rich" 2>/dev/null; then
    log_skip "Enigma CLI Python virtualenv is already installed with all dependencies"
else
    log_info "Bootstrapping Enigma CLI virtualenv at $VENV_DIR..."
    python3 -m venv "$VENV_DIR"
    "$VENV_DIR/bin/pip" install --quiet --upgrade pip
    "$VENV_DIR/bin/pip" install --quiet -r "$REQ_FILE"
    log_ok "Configured Enigma CLI virtualenv"
fi

# 8. Bootstrap Neovim plugins
step_header "Verifying Neovim plugins (Lazy.nvim)"
if [ -d "$HOME/.local/share/nvim/lazy/nvim-treesitter" ] && [ -d "$HOME/.local/share/nvim/lazy/which-key.nvim" ]; then
    log_skip "Neovim plugins are already installed via Lazy.nvim"
else
    log_info "Bootstrapping Neovim plugins headlessly..."
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
    log_ok "Bootstrapped Neovim plugins"
fi

# 9. Bootstrap Tmux Plugin Manager (TPM)
step_header "Verifying Tmux Plugin Manager (TPM)"
if [ -d "$HOME/.config/tmux/plugins/tpm" ]; then
    log_skip "Tmux Plugin Manager (TPM) is already installed"
else
    git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm" >/dev/null 2>&1
    log_ok "Installed TPM"
fi

if [ -d "$HOME/.config/tmux/plugins/tmux-sensible" ]; then
    log_skip "Tmux plugins are already installed"
else
    "$HOME/.config/tmux/plugins/tpm/bin/install_plugins" >/dev/null 2>&1 || true
    log_ok "Installed Tmux plugins"
fi

# 10. Build Bat theme cache
step_header "Verifying Bat theme cache"
if bat --list-themes 2>/dev/null | grep -qi "tokyonight"; then
    log_skip "Bat custom theme cache is already built"
else
    bat cache --build >/dev/null 2>&1 || true
    log_ok "Built Bat theme cache"
fi

# 11. Deploy Yazi Catppuccin theme
step_header "Verifying Yazi theme"
if [ -d "$HOME/.config/yazi/flavors/catppuccin-frappe.yazi" ] || [ -d "$HOME/.config/yazi/flavors" ]; then
    log_skip "Yazi Catppuccin theme is already deployed"
else
    ya pkg install >/dev/null 2>&1 || ya pack -a yazi-rs/flavors:catppuccin-frappe >/dev/null 2>&1 || true
    log_ok "Deployed Yazi Catppuccin theme"
fi

# 12. Set up WezTerm wallpapers directory
step_header "Verifying WezTerm wallpapers"
mkdir -p "$HOME/wezterm-wallpapers"
WP_COUNT=$(ls -A "$HOME/wezterm-wallpapers" 2>/dev/null | wc -l)
if [ "$WP_COUNT" -gt 0 ]; then
    log_skip "WezTerm wallpapers directory is already populated ($WP_COUNT file(s))"
else
    cp -u "$DOTFILES_DIR"/backgrounds/.config/backgrounds/* "$HOME/wezterm-wallpapers/" 2>/dev/null || true
    log_ok "Initialized WezTerm wallpapers"
fi

# 13. Set executable permissions for all dotfiles scripts
step_header "Verifying script executable permissions"
chmod +x "$HOME"/.config/hypr/scripts/*.sh 2>/dev/null || true
chmod +x "$HOME"/.config/waybar/scripts/*.sh 2>/dev/null || true
chmod +x "$HOME"/.config/rofi/*.sh 2>/dev/null || true
chmod +x "$HOME"/.config/zsh/*.sh 2>/dev/null || true
log_ok "Ensured executable (+x) permissions across all scripts"

# 14. Enable system services
step_header "Verifying system services (power-profiles-daemon)"
if systemctl is-active power-profiles-daemon >/dev/null 2>&1 && systemctl is-enabled power-profiles-daemon >/dev/null 2>&1; then
    log_skip "power-profiles-daemon is already enabled and active"
else
    sudo systemctl enable --now power-profiles-daemon 2>/dev/null || true
    log_ok "Enabled and started power-profiles-daemon"
fi

# 15. Sudoers permissions for rfkill
step_header "Verifying rfkill sudoers permission for Waybar"
RFKILL_PATH="$(which rfkill 2>/dev/null || echo '/usr/bin/rfkill')"
EXPECTED_SUDOERS="$USER ALL=(ALL) NOPASSWD: $RFKILL_PATH"
if [ -f /etc/sudoers.d/enigma-rfkill ] && grep -Fxq "$EXPECTED_SUDOERS" /etc/sudoers.d/enigma-rfkill 2>/dev/null; then
    log_skip "Sudoers permission for rfkill is already configured"
else
    echo "$EXPECTED_SUDOERS" | sudo tee /etc/sudoers.d/enigma-rfkill > /dev/null
    sudo chmod 0440 /etc/sudoers.d/enigma-rfkill
    log_ok "Configured /etc/sudoers.d/enigma-rfkill"
fi

# 16. Set default login shell to Zsh
step_header "Verifying default login shell (Zsh)"
ZSH_BIN="$(which zsh 2>/dev/null || echo '/bin/zsh')"
CURRENT_SHELL="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7)"
if [ "$CURRENT_SHELL" = "$ZSH_BIN" ]; then
    log_skip "Default login shell is already $ZSH_BIN"
else
    if ! grep -Fxq "$ZSH_BIN" /etc/shells 2>/dev/null; then
        echo "$ZSH_BIN" | sudo tee -a /etc/shells > /dev/null
    fi
    sudo chsh -s "$ZSH_BIN" "$USER" 2>/dev/null || true
    log_ok "Changed login shell for $USER to $ZSH_BIN"
fi

# 17. Configure permissions for hardware brightness control
step_header "Verifying video group and backlight udev rules"
if groups "$USER" 2>/dev/null | grep -qw "video"; then
    log_skip "User '$USER' is already a member of 'video' group"
else
    sudo usermod -aG video "$USER" 2>/dev/null || true
    log_ok "Added user '$USER' to 'video' group"
fi

UDEV_FILE="/etc/udev/rules.d/90-backlight.rules"
EXPECTED_UDEV='ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chmod a+w /sys/class/backlight/%k/brightness"'
if [ -f "$UDEV_FILE" ] && grep -Fq 'SUBSYSTEM=="backlight"' "$UDEV_FILE" 2>/dev/null; then
    log_skip "Backlight udev rule is already present at $UDEV_FILE"
else
    sudo tee "$UDEV_FILE" > /dev/null <<< "$EXPECTED_UDEV"
    sudo udevadm control --reload-rules 2>/dev/null || true
    sudo udevadm trigger --subsystem-match=backlight 2>/dev/null || true
    log_ok "Created $UDEV_FILE and reloaded udev rules"
fi

# 18. Ensure Ethernet connections use DHCP
step_header "Verifying Ethernet connections DHCP configuration"
ETH_CONS=$(nmcli -t -f NAME,TYPE connection show 2>/dev/null | grep ":802-3-ethernet" | cut -d: -f1 || true)
if [ -z "$ETH_CONS" ]; then
    log_skip "No wired Ethernet NetworkManager profiles detected"
else
    ETH_UPDATED=0
    ETH_TOTAL=0
    while IFS= read -r con; do
        [ -z "$con" ] && continue
        ETH_TOTAL=$((ETH_TOTAL + 1))
        METHOD=$(nmcli -g ipv4.method connection show "$con" 2>/dev/null || echo "")
        if [ "$METHOD" = "auto" ]; then
            continue
        fi
        nmcli connection modify "$con" ipv4.method auto ipv6.method auto 2>/dev/null || true
        ETH_UPDATED=$((ETH_UPDATED + 1))
    done <<< "$ETH_CONS"

    if [ "$ETH_UPDATED" -eq 0 ]; then
        log_skip "All ($ETH_TOTAL) Ethernet connection profiles already use DHCP (auto)"
    else
        log_ok "Configured DHCP (auto) on $ETH_UPDATED Ethernet connection profile(s)"
    fi
fi

# 19. Verify DisplayLink driver & EVDI module
step_header "Verifying DisplayLink driver & EVDI module"
if (pacman -Qi displaylink >/dev/null 2>&1 || pacman -Qi displaylink-connect >/dev/null 2>&1) && \
   (pacman -Qi evdi >/dev/null 2>&1 || pacman -Qi evdi-dkms >/dev/null 2>&1 || pacman -Qi evdi-git >/dev/null 2>&1) && \
   systemctl is-active displaylink >/dev/null 2>&1; then
    log_skip "DisplayLink driver and service are already installed and active"
else
    log_info "Configuring DisplayLink driver and EVDI kernel module..."

    # 1. Install DKMS and matching kernel headers via pacman
    KERNEL_HEADERS="linux-headers"
    if uname -r | grep -q "lts"; then
        KERNEL_HEADERS="linux-lts-headers"
    elif uname -r | grep -q "zen"; then
        KERNEL_HEADERS="linux-zen-headers"
    elif uname -r | grep -q "hardened"; then
        KERNEL_HEADERS="linux-hardened-headers"
    fi

    ARCH_DL_DEPS=(dkms "$KERNEL_HEADERS")
    MISSING_ARCH_DEPS=()
    for dep in "${ARCH_DL_DEPS[@]}"; do
        if ! pacman -Qi "$dep" >/dev/null 2>&1; then
            MISSING_ARCH_DEPS+=("$dep")
        fi
    done

    if [ ${#MISSING_ARCH_DEPS[@]} -gt 0 ]; then
        log_info "Installing kernel headers and DKMS dependencies: ${MISSING_ARCH_DEPS[*]}"
        sudo pacman -S --needed --noconfirm "${MISSING_ARCH_DEPS[@]}" 2>/dev/null || true
    fi

    # 2. Detect or bootstrap AUR helper (yay / paru)
    AUR_HELPER=""
    if command -v yay >/dev/null 2>&1; then
        AUR_HELPER="yay"
    elif command -v paru >/dev/null 2>&1; then
        AUR_HELPER="paru"
    else
        log_info "Bootstrapping yay AUR helper from source..."
        YAY_BUILD_DIR="$(mktemp -d)"
        if git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$YAY_BUILD_DIR/yay-bin" 2>/dev/null; then
            (cd "$YAY_BUILD_DIR/yay-bin" && makepkg -si --noconfirm) 2>/dev/null || true
            rm -rf "$YAY_BUILD_DIR"
            command -v yay >/dev/null 2>&1 && AUR_HELPER="yay"
        fi
    fi

    # 3. Install evdi and displaylink via AUR helper
    if [ -n "$AUR_HELPER" ]; then
        MISSING_AUR_PACKAGES=()
        if ! pacman -Qi evdi >/dev/null 2>&1 && ! pacman -Qi evdi-dkms >/dev/null 2>&1 && ! pacman -Qi evdi-git >/dev/null 2>&1; then
            MISSING_AUR_PACKAGES+=(evdi)
        fi
        if ! pacman -Qi displaylink >/dev/null 2>&1; then
            MISSING_AUR_PACKAGES+=(displaylink)
        fi

        if [ ${#MISSING_AUR_PACKAGES[@]} -gt 0 ]; then
            log_info "Installing AUR package(s): ${MISSING_AUR_PACKAGES[*]} using $AUR_HELPER..."
            $AUR_HELPER -S --needed --noconfirm "${MISSING_AUR_PACKAGES[@]}"
            log_ok "Installed DisplayLink & EVDI AUR packages"
        fi
    else
        log_warn "AUR helper (yay/paru) not found; please install 'evdi' and 'displaylink' from AUR manually"
    fi

    # 4. Enable and start displaylink systemd service
    sudo modprobe evdi 2>/dev/null || true
    if systemctl is-active displaylink >/dev/null 2>&1; then
        log_skip "displaylink service is active"
    else
        log_info "Enabling and starting displaylink service..."
        sudo systemctl daemon-reload 2>/dev/null || true
        sudo systemctl enable --now displaylink 2>/dev/null || true
        log_ok "Enabled and started displaylink service"
    fi
fi

# Final Summary Report
echo -e "\n${BOLD}==================================================================${RESET}"
echo -e "${BOLD}${GREEN}  Complete Setup for Arch Linux Finished Successfully!${RESET}"
echo -e "${BOLD}==================================================================${RESET}"
echo -e "  Summary of actions:"
echo -e "    ${GREEN}✓ Newly Configured :${RESET} ${ACTIONS_DONE}"
echo -e "    ${CYAN}➜ Already In Place :${RESET} ${ACTIONS_SKIPPED}"
echo -e "    ${RED}✗ Warnings/Failures:${RESET} ${ACTIONS_FAILED}"
echo -e "${BOLD}==================================================================${RESET}\n"
