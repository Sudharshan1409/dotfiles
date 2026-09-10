#!/usr/bin/env bash
set -e

# ==============================================================================
# Dotfiles & System Setup Script for Ubuntu Linux
# ==============================================================================
# Fully Idempotent: Every step verifies existing configuration before acting.
# Safe to run repeatedly on new or partially configured systems.
# ==============================================================================

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.local/bin:/home/linuxbrew/.linuxbrew/bin:/snap/bin:$PATH"

if [ "$1" = "--check" ] || [ "$1" = "-c" ] || [ "$1" = "doctor" ]; then
    exec "$DOTFILES_DIR/scripts/dotfiles-doctor.sh"
fi

# ANSI Color Codes for Real-Time Logging
BOLD="\033[1m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
BLUE="\033[1;34m"
DIM="\033[2m"
RESET="\033[0m"

TOTAL_STEPS=22
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
echo -e "${BOLD}  Starting Dotfiles & System Environment Setup (Ubuntu)${RESET}"
echo -e "${BOLD}==================================================================${RESET}"

# ------------------------------------------------------------------------------
# Operating System Pre-flight Check
# ------------------------------------------------------------------------------
if [ ! -f /etc/os-release ] && [ ! -f /usr/lib/os-release ]; then
    echo -e "\n${BOLD}${RED}==================================================================${RESET}"
    echo -e "${BOLD}${RED}  ✗ [ERROR] Cannot detect operating system (/etc/os-release not found)${RESET}"
    echo -e "${BOLD}${RED}==================================================================${RESET}"
    echo -e "  This script is strictly intended for Ubuntu Linux."
    echo -e "  Aborting execution.\n"
    exit 1
fi

OS_ID="$(. /etc/os-release 2>/dev/null || . /usr/lib/os-release 2>/dev/null; echo "$ID")"
OS_ID_LIKE="$(. /etc/os-release 2>/dev/null || . /usr/lib/os-release 2>/dev/null; echo "$ID_LIKE")"
OS_PRETTY="$(. /etc/os-release 2>/dev/null || . /usr/lib/os-release 2>/dev/null; echo "${PRETTY_NAME:-$NAME}")"

if [ "$OS_ID" != "ubuntu" ]; then
    echo -e "\n${BOLD}${RED}==================================================================${RESET}"
    echo -e "${BOLD}${RED}  ✗ [ERROR] Incompatible Operating System Detected!${RESET}"
    echo -e "${BOLD}${RED}==================================================================${RESET}"
    echo -e "  Current System : ${YELLOW}${OS_PRETTY:-$OS_ID}${RESET}"
    echo -e "  Required System: ${GREEN}Ubuntu Linux${RESET}"
    echo -e "\n  ${RED}This script (setup_ubuntu.sh) is specifically written for Ubuntu systems (uses apt, PPAs, etc.).${RESET}"
    if [[ "$OS_ID" == "arch" || "$OS_ID_LIKE" =~ "arch" ]]; then
        echo -e "  👉 ${BOLD}Did you mean to run:${RESET} ${CYAN}./setup_arch.sh${RESET} ?"
    fi
    echo -e "\n  Stopping execution to prevent system configuration conflicts.\n"
    exit 1
fi

log_info "Detected OS: ${GREEN}${OS_PRETTY:-Ubuntu}${RESET} (Compatible)"

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

# 2. Update APT and install system dependencies
step_header "Verifying APT system packages & Wayland environment"
APT_PACKAGES=(
    build-essential
    cmake
    pkg-config
    git
    curl
    wget
    stow
    zsh
    python3
    python3-venv
    python3-pip
    libfuse2t64
    hyprland
    hyprland-qtutils
    waybar
    sway-notification-center
    hyprpaper
    hypridle
    hyprlock
    rofi
    wofi
    htop
    nautilus
    grim
    slurp
    wf-recorder
    wl-clipboard
    cliphist
    tesseract-ocr
    tesseract-ocr-eng
    network-manager-gnome
    brightnessctl
    playerctl
    pamixer
    pavucontrol
    pulseaudio-utils
    blueman
    power-profiles-daemon
    libnotify-bin
    policykit-1-gnome
)

MISSING_APT=()
for pkg in "${APT_PACKAGES[@]}"; do
    if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
        if apt-cache show "$pkg" >/dev/null 2>&1; then
            MISSING_APT+=("$pkg")
        else
            log_warn "APT package '$pkg' not found in repositories for this release, skipping APT install"
        fi
    fi
done

if [ ${#MISSING_APT[@]} -eq 0 ]; then
    log_skip "All required APT packages are already installed"
else
    log_info "Updating APT index and installing ${#MISSING_APT[@]} missing package(s): ${MISSING_APT[*]}"
    sudo apt-get update -y || log_warn "APT update finished with warnings/errors (often due to 3rd-party repos); proceeding with installation..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${MISSING_APT[@]}"
    log_ok "Installed missing APT package(s): ${MISSING_APT[*]}"
fi

# Ensure Ghostty terminal emulator is installed (APT on Ubuntu 25+, Snap on Ubuntu 24.04)
if command -v ghostty >/dev/null 2>&1; then
    log_skip "Ghostty terminal is already installed"
elif apt-cache show ghostty >/dev/null 2>&1; then
    log_info "Installing Ghostty via APT..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ghostty
    log_ok "Installed Ghostty via APT"
elif command -v snap >/dev/null 2>&1; then
    log_info "Installing Ghostty via Snap..."
    sudo snap install ghostty --classic
    log_ok "Installed Ghostty via Snap"
else
    log_warn "Ghostty terminal could not be installed automatically"
fi

# 3. Ensure Homebrew is installed for modern CLI tools
step_header "Verifying Homebrew (Linuxbrew) & CLI tools"
if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ] || command -v brew >/dev/null 2>&1; then
    log_skip "Homebrew is already installed"
else
    log_info "Installing Homebrew (Linuxbrew)..."
    sudo mkdir -p /home/linuxbrew/.linuxbrew
    sudo chown -R "$USER:$USER" /home/linuxbrew
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    log_ok "Homebrew installed successfully"
fi

if [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if grep -q "linuxbrew.*shellenv" "$HOME/.profile" 2>/dev/null; then
    log_skip "Homebrew shellenv is already configured in ~/.profile"
else
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.profile"
    log_ok "Added Homebrew shellenv to ~/.profile"
fi

BREW_PACKAGES=(
    zsh
    neovim
    tmux
    bat
    eza
    lsd
    zoxide
    git-delta
    jq
    gh
    fzf
    yazi
    zellij
    starship
    lazygit
    fd
    ripgrep
    python
    node
    htop
    nvtop
    shellcheck
    tldr
)

MISSING_BREW=()
for pkg in "${BREW_PACKAGES[@]}"; do
    if ! brew list --formula "$pkg" >/dev/null 2>&1; then
        MISSING_BREW+=("$pkg")
    fi
done

if [ ${#MISSING_BREW[@]} -eq 0 ]; then
    log_skip "All ${#BREW_PACKAGES[@]} Homebrew CLI tools are already installed"
else
    log_info "Installing ${#MISSING_BREW[@]} missing Homebrew tool(s): ${MISSING_BREW[*]}"
    NONINTERACTIVE=1 brew install "${MISSING_BREW[@]}"
    log_ok "Installed missing Homebrew tool(s): ${MISSING_BREW[*]}"
fi

# 4. Configure fzf shell integration
step_header "Verifying fzf shell integration"
if [ -f "$HOME/.fzf.zsh" ] || [ -f "$HOME/.fzf.bash" ]; then
    log_skip "fzf shell integration files already present"
elif [ -d "$(brew --prefix 2>/dev/null)/opt/fzf" ]; then
    "$(brew --prefix)/opt/fzf/install" --all --no-update-rc >/dev/null 2>&1 || true
    log_ok "Configured fzf shell integration"
else
    log_skip "fzf binary is available"
fi

# 5. Symlink core CLI tools to ~/.local/bin
step_header "Verifying CLI tool symlinks in ~/.local/bin"
mkdir -p "$HOME/.local/bin"
SYMLINK_TOOLS=(node npm npx htop nvtop shellcheck tldr)
SYMLINKS_MADE=0
for bin in "${SYMLINK_TOOLS[@]}"; do
    TARGET="/home/linuxbrew/.linuxbrew/bin/$bin"
    LINK="$HOME/.local/bin/$bin"
    if [ -x "$TARGET" ]; then
        if [ -L "$LINK" ] && [ "$(readlink -f "$LINK")" = "$(readlink -f "$TARGET")" ]; then
            continue
        fi
        ln -sf "$TARGET" "$LINK"
        SYMLINKS_MADE=$((SYMLINKS_MADE + 1))
    fi
done
if [ "$SYMLINKS_MADE" -eq 0 ]; then
    log_skip "Core CLI tool symlinks in ~/.local/bin are already up-to-date"
else
    log_ok "Created/updated $SYMLINKS_MADE CLI tool symlink(s) in ~/.local/bin"
fi

# 6. Install standalone terminal emulators and launchers if missing
step_header "Verifying standalone apps (Kitty, WezTerm, Walker, Satty, Fonts)"

# Kitty
if command -v kitty >/dev/null 2>&1 || [ -x "$HOME/.local/kitty.app/bin/kitty" ]; then
    log_skip "Kitty terminal emulator is already installed"
else
    log_info "Installing Kitty terminal emulator..."
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
    ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/bin/kitty"
    ln -sf "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/kitten"
    log_ok "Installed Kitty terminal"
fi

# WezTerm
if command -v wezterm >/dev/null 2>&1 || [ -x "$HOME/.local/wezterm-app/usr/bin/wezterm" ]; then
    log_skip "WezTerm terminal emulator is already installed"
else
    log_info "Installing WezTerm AppImage..."
    WEZ_TMP="$(mktemp -d)"
    curl -fsSL -o "$WEZ_TMP/wezterm.AppImage" "https://github.com/wez/wezterm/releases/download/20240203-110809-5046fc22/WezTerm-20240203-110809-5046fc22-Ubuntu20.04.AppImage"
    chmod +x "$WEZ_TMP/wezterm.AppImage"
    (cd "$WEZ_TMP" && "$WEZ_TMP/wezterm.AppImage" --appimage-extract >/dev/null 2>&1)
    rm -rf "$HOME/.local/wezterm-app"
    mv "$WEZ_TMP/squashfs-root" "$HOME/.local/wezterm-app"
    ln -sf "$HOME/.local/wezterm-app/usr/bin/wezterm" "$HOME/.local/bin/wezterm"
    ln -sf "$HOME/.local/wezterm-app/usr/bin/wezterm-gui" "$HOME/.local/bin/wezterm-gui"
    ln -sf "$HOME/.local/wezterm-app/usr/bin/wezterm-mux-server" "$HOME/.local/bin/wezterm-mux-server"
    rm -rf "$WEZ_TMP"
    log_ok "Installed WezTerm"
fi

# Walker
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

# Satty
if command -v satty >/dev/null 2>&1 || [ -x "$HOME/.local/bin/satty" ]; then
    log_skip "Satty screenshot editor is already installed"
else
    log_info "Installing Satty screenshot editor..."
    curl -sL https://github.com/Satty-org/Satty/releases/download/v0.22.0/satty-x86_64-unknown-linux-gnu.tar.gz | tar -xz -C "$HOME/.local/bin/" 2>/dev/null || true
    chmod +x "$HOME/.local/bin/satty" 2>/dev/null || true
    log_ok "Installed Satty screenshot editor"
fi

# Nerd Fonts (JetBrainsMono, CascadiaMono, Symbols)
if fc-list : family 2>/dev/null | grep -qi "JetBrainsMono.*Nerd" && fc-list : family 2>/dev/null | grep -qi "CascadiaMono.*Nerd"; then
    log_skip "Nerd Fonts (JetBrainsMono, CascadiaMono) already installed"
else
    log_info "Installing JetBrainsMono and CascadiaMono Nerd Fonts..."
    mkdir -p "$HOME/.local/share/fonts/JetBrainsMono" "$HOME/.local/share/fonts/CascadiaMono" "$HOME/.local/share/fonts/NerdFontsSymbolsOnly"
    curl -sL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/JetBrainsMono.tar.xz | tar -xJ -C "$HOME/.local/share/fonts/JetBrainsMono/" 2>/dev/null || true
    curl -sL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/CascadiaMono.tar.xz | tar -xJ -C "$HOME/.local/share/fonts/CascadiaMono/" 2>/dev/null || true
    curl -sL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/NerdFontsSymbolsOnly.tar.xz | tar -xJ -C "$HOME/.local/share/fonts/NerdFontsSymbolsOnly/" 2>/dev/null || true
    fc-cache -f 2>/dev/null || true
    log_ok "Installed Nerd Fonts and refreshed font cache"
fi

# 7. Apply Stow configuration for all Linux packages
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

# 8. Git configuration include
step_header "Verifying Git configuration"
if [ -f "$HOME/.gitconfig" ] && grep -q "\.config/git/\.gitconfig" "$HOME/.gitconfig" 2>/dev/null; then
    log_skip "Git include for ~/.config/git/.gitconfig is already configured"
else
    printf "[include]\n\tpath = ~/.config/git/.gitconfig\n" >> "$HOME/.gitconfig"
    log_ok "Added include directive to ~/.gitconfig"
fi

# 9. Set up Oh-My-Zsh and plugins
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

# 10. Set up Python virtual environment for Enigma CLI
step_header "Verifying Enigma CLI virtual environment"
VENV_DIR="$HOME/.config/zsh/venv"
REQ_FILE="$HOME/.config/zsh/python/requirements.txt"

if [ -x "$VENV_DIR/bin/python3" ] && "$VENV_DIR/bin/python3" -c "import InquirerPy, rich" 2>/dev/null; then
    log_skip "Enigma CLI Python virtualenv is already installed with all dependencies"
else
    PYTHON_EXEC="/home/linuxbrew/.linuxbrew/bin/python3"
    [ ! -x "$PYTHON_EXEC" ] && PYTHON_EXEC="$(which python3)"
    log_info "Bootstrapping Enigma CLI virtualenv at $VENV_DIR..."
    "$PYTHON_EXEC" -m venv "$VENV_DIR"
    "$VENV_DIR/bin/pip" install --quiet --upgrade pip
    "$VENV_DIR/bin/pip" install --quiet -r "$REQ_FILE"
    log_ok "Configured Enigma CLI virtualenv"
fi

# 11. Bootstrap Neovim plugins
step_header "Verifying Neovim plugins (Lazy.nvim)"
if [ -d "$HOME/.local/share/nvim/lazy/nvim-treesitter" ] && [ -d "$HOME/.local/share/nvim/lazy/which-key.nvim" ]; then
    log_skip "Neovim plugins are already installed via Lazy.nvim"
else
    log_info "Bootstrapping Neovim plugins headlessly..."
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
    log_ok "Bootstrapped Neovim plugins"
fi

# 12. Bootstrap Tmux Plugin Manager (TPM)
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

# 13. Build Bat theme cache
step_header "Verifying Bat theme cache"
if bat --list-themes 2>/dev/null | grep -qi "tokyonight"; then
    log_skip "Bat custom theme cache is already built"
else
    bat cache --build >/dev/null 2>&1 || true
    log_ok "Built Bat theme cache"
fi

# 14. Deploy Yazi Catppuccin theme
step_header "Verifying Yazi theme"
if [ -d "$HOME/.config/yazi/flavors/catppuccin-frappe.yazi" ] || [ -d "$HOME/.config/yazi/flavors" ]; then
    log_skip "Yazi Catppuccin theme is already deployed"
else
    ya pkg install >/dev/null 2>&1 || ya pack -a yazi-rs/flavors:catppuccin-frappe >/dev/null 2>&1 || true
    log_ok "Deployed Yazi Catppuccin theme"
fi

# 15. Set up WezTerm wallpapers directory and user picture directories
step_header "Verifying WezTerm wallpapers and user picture directories"
mkdir -p "$HOME/wezterm-wallpapers" "$HOME/Pictures/Pics" "$HOME/Pictures/Screenshots"
WP_COUNT=$(ls -A "$HOME/wezterm-wallpapers" 2>/dev/null | wc -l)
if [ "$WP_COUNT" -gt 0 ]; then
    log_skip "WezTerm wallpapers directory is already populated ($WP_COUNT file(s))"
else
    cp -u "$DOTFILES_DIR"/backgrounds/.config/backgrounds/* "$HOME/wezterm-wallpapers/" 2>/dev/null || true
    log_ok "Initialized WezTerm wallpapers"
fi

# 16. Set executable permissions for all dotfiles scripts
step_header "Verifying script executable permissions"
chmod +x "$HOME"/.config/hypr/scripts/*.sh 2>/dev/null || true
chmod +x "$HOME"/.config/waybar/scripts/*.sh 2>/dev/null || true
chmod +x "$HOME"/.config/rofi/*.sh 2>/dev/null || true
chmod +x "$HOME"/.config/zsh/*.sh 2>/dev/null || true
log_ok "Ensured executable (+x) permissions across all scripts"

# 17. Enable system services
step_header "Verifying system services (power-profiles-daemon)"
if systemctl is-active power-profiles-daemon >/dev/null 2>&1 && systemctl is-enabled power-profiles-daemon >/dev/null 2>&1; then
    log_skip "power-profiles-daemon is already enabled and active"
else
    sudo systemctl enable --now power-profiles-daemon 2>/dev/null || true
    log_ok "Enabled and started power-profiles-daemon"
fi

# 18. Sudoers permissions for rfkill
step_header "Verifying rfkill sudoers permission for Waybar"
RFKILL_PATH="$(which rfkill 2>/dev/null || echo '/usr/sbin/rfkill')"
EXPECTED_SUDOERS="$USER ALL=(ALL) NOPASSWD: $RFKILL_PATH"
if [ -f /etc/sudoers.d/enigma-rfkill ] && grep -Fxq "$EXPECTED_SUDOERS" /etc/sudoers.d/enigma-rfkill 2>/dev/null; then
    log_skip "Sudoers permission for rfkill is already configured"
else
    echo "$EXPECTED_SUDOERS" | sudo tee /etc/sudoers.d/enigma-rfkill > /dev/null
    sudo chmod 0440 /etc/sudoers.d/enigma-rfkill
    log_ok "Configured /etc/sudoers.d/enigma-rfkill"
fi

# 19. Set default login shell to Zsh
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

# 20. Configure permissions for hardware brightness control
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

# 21. Ensure Ethernet connections use DHCP
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

# 22. Verify DisplayLink driver & EVDI module
step_header "Verifying DisplayLink driver & EVDI module"
if dpkg-query -W -f='${Status}' displaylink-driver 2>/dev/null | grep -q "ok installed" && systemctl is-active displaylink-driver >/dev/null 2>&1; then
    log_skip "DisplayLink driver and service are already installed and active"
else
    log_info "Configuring DisplayLink driver and EVDI kernel module..."

    # 1. Ensure kernel build headers and DKMS dependencies
    DL_DEPS=(dkms libdrm-dev)
    if [ ! -d "/lib/modules/$(uname -r)/build" ]; then
        DL_DEPS+=(linux-headers-generic)
    fi

    MISSING_DL_DEPS=()
    for dep in "${DL_DEPS[@]}"; do
        if ! dpkg-query -W -f='${Status}' "$dep" 2>/dev/null | grep -q "ok installed"; then
            MISSING_DL_DEPS+=("$dep")
        fi
    done
    if [ ${#MISSING_DL_DEPS[@]} -gt 0 ]; then
        log_info "Installing DisplayLink dependencies: ${MISSING_DL_DEPS[*]}"
        sudo apt-get update -qq || true
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${MISSING_DL_DEPS[@]}"
    fi

    # 2. Configure Synaptics official APT repository keyring
    if ! dpkg-query -W -f='${Status}' synaptics-repository-keyring 2>/dev/null | grep -q "ok installed"; then
        log_info "Installing Synaptics official repository keyring..."
        KEYRING_DEB="$(mktemp --suffix=.deb)"
        if curl -fsSL -o "$KEYRING_DEB" "https://www.synaptics.com/sites/default/files/Ubuntu/pool/stable/main/all/synaptics-repository-keyring.deb"; then
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$KEYRING_DEB"
            rm -f "$KEYRING_DEB"
            sudo apt-get update -qq || true
            log_ok "Configured Synaptics repository"
        else
            log_err "Failed to download Synaptics repository keyring"
            rm -f "$KEYRING_DEB"
        fi
    fi

    # 3. Install displaylink-driver
    if ! dpkg-query -W -f='${Status}' displaylink-driver 2>/dev/null | grep -q "ok installed"; then
        log_info "Installing displaylink-driver package..."
        sudo apt-get update -qq || true
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y displaylink-driver
        log_ok "Installed displaylink-driver package"
    fi

    # 4. Load EVDI kernel module & enable/start displaylink-driver service
    sudo modprobe evdi 2>/dev/null || true
    if systemctl is-active displaylink-driver >/dev/null 2>&1; then
        log_skip "displaylink-driver service is active"
    else
        log_info "Enabling and starting displaylink-driver service..."
        sudo systemctl daemon-reload 2>/dev/null || true
        sudo systemctl enable --now displaylink-driver 2>/dev/null || true
        log_ok "Enabled and started displaylink-driver service"
    fi
fi

# Final Summary Report
echo -e "\n${BOLD}==================================================================${RESET}"
echo -e "${BOLD}${GREEN}  Complete Setup for Ubuntu Finished Successfully!${RESET}"
echo -e "${BOLD}==================================================================${RESET}"
echo -e "  Summary of actions:"
echo -e "    ${GREEN}✓ Newly Configured :${RESET} ${ACTIONS_DONE}"
echo -e "    ${CYAN}➜ Already In Place :${RESET} ${ACTIONS_SKIPPED}"
echo -e "    ${RED}✗ Warnings/Failures:${RESET} ${ACTIONS_FAILED}"
echo -e "${BOLD}==================================================================${RESET}\n"
