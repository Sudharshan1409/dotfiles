#!/usr/bin/env bash
set -e

# ==============================================================================
# Dotfiles & System Setup Script for Arch Linux
# ==============================================================================

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.local/bin:$PATH"

echo "=================================================================="
echo "  Starting Complete Dotfiles & Environment Setup for Arch Linux"
echo "=================================================================="

# 1. Elevate sudo privileges once and keep alive in background
echo "==> Requesting sudo privileges..."
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_PID=$!
trap 'kill $SUDO_PID 2>/dev/null' EXIT

# 2. Update system and install official Arch packages via pacman
echo "==> Updating package database and upgrading system..."
sudo pacman -Syu --noconfirm --needed

echo "==> Installing packages and Wayland environment via pacman..."
PACMAN_PACKAGES=(
    base-devel
    git
    curl
    wget
    stow
    cmake
    pkgconf
    zsh
    python
    python-pip
    hyprland
    waybar
    sway-notification-center
    hyprpaper
    hypridle
    hyprlock
    rofi-wayland
    wofi
    kitty
    wezterm
    nautilus
    pavucontrol
    blueman
    grim
    slurp
    wf-recorder
    wl-clipboard
    cliphist
    tesseract
    tesseract-data-eng
    network-manager-applet
    brightnessctl
    playerctl
    pamixer
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
)

# Install packages with error tolerance for optionally named packages
for pkg in "${PACMAN_PACKAGES[@]}"; do
    if ! pacman -Qi "$pkg" >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm "$pkg" 2>/dev/null || echo "Note: Package '$pkg' not found in official repos, skipping..."
    fi
done

# Try installing ghostty via pacman if in extra
sudo pacman -S --needed --noconfirm ghostty 2>/dev/null || true

# 3. Install Walker launcher if not present
mkdir -p "$HOME/.local/bin"
if ! command -v walker >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/walker" ]; then
    echo "==> Installing Walker Wayland launcher..."
    WALKER_URL=$(curl -s https://api.github.com/repos/abenz1267/walker/releases/latest | grep -o 'https://[^"]*x86_64-unknown-linux-gnu.tar.gz' | head -n 1)
    if [ -n "$WALKER_URL" ]; then
        curl -fsSL "$WALKER_URL" | tar -xz -C "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/walker"
    fi
fi

# 4. Apply Stow configuration for all Linux packages
echo "==> Linking dotfiles via GNU Stow..."
cd "$DOTFILES_DIR"
stow -v -t "$HOME" \
    backgrounds bat ghostty git hypr kitty lazygit nvim rofi starship swaync tmux walker waybar wezterm wofi yazi zellij zsh

# 5. Git configuration include
echo "==> Setting up Git configuration..."
if [ ! -f "$HOME/.gitconfig" ] || ! grep -q "\.config/git/\.gitconfig" "$HOME/.gitconfig"; then
    printf "[include]\n\tpath = ~/.config/git/.gitconfig\n" >> "$HOME/.gitconfig"
fi

# 6. Set up Oh-My-Zsh and plugins
echo "==> Setting up Oh-My-Zsh & plugins..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "$ZSH_CUSTOM/plugins" "$ZSH_CUSTOM/themes"

[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ ! -d "$ZSH_CUSTOM/plugins/fzf-tab" ] && git clone --depth=1 https://github.com/Aloxaf/fzf-tab "$ZSH_CUSTOM/plugins/fzf-tab"
[ ! -d "$ZSH_CUSTOM/plugins/you-should-use" ] && git clone --depth=1 https://github.com/MichaelAquilina/zsh-you-should-use.git "$ZSH_CUSTOM/plugins/you-should-use"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autopair" ] && git clone --depth=1 https://github.com/hlissner/zsh-autopair "$ZSH_CUSTOM/plugins/zsh-autopair"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-256color" ] && git clone --depth=1 https://github.com/chrissicool/zsh-256color "$ZSH_CUSTOM/plugins/zsh-256color"
[ ! -d "$ZSH_CUSTOM/plugins/git-open" ] && git clone --depth=1 https://github.com/paulirish/git-open.git "$ZSH_CUSTOM/plugins/git-open"
[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ] && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"

# 7. Set up Python virtual environment for Enigma CLI
echo "==> Setting up Enigma CLI virtual environment..."
if [ ! -d "$HOME/.config/zsh/venv" ]; then
    python3 -m venv "$HOME/.config/zsh/venv"
    "$HOME/.config/zsh/venv/bin/pip" install --upgrade pip
    "$HOME/.config/zsh/venv/bin/pip" install -r "$HOME/.config/zsh/python/requirements.txt"
fi

# 8. Bootstrap Neovim plugins
echo "==> Bootstrapping Neovim plugins (Lazy.nvim)..."
nvim --headless "+Lazy! sync" +qa 2>/dev/null || true

# 9. Bootstrap Tmux Plugin Manager (TPM)
echo "==> Setting up Tmux Plugin Manager..."
if [ ! -d "$HOME/.config/tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
fi
"$HOME/.config/tmux/plugins/tpm/bin/install_plugins" 2>/dev/null || true

# 10. Build Bat theme cache
echo "==> Building Bat theme cache..."
bat cache --build 2>/dev/null || true

# 11. Deploy Yazi Catppuccin theme
echo "==> Deploying Yazi theme..."
ya pkg install 2>/dev/null || ya pack -a yazi-rs/flavors:catppuccin-frappe 2>/dev/null || true

# 12. Set up WezTerm wallpapers directory
echo "==> Initializing WezTerm wallpapers..."
mkdir -p "$HOME/wezterm-wallpapers"
cp -u "$DOTFILES_DIR"/backgrounds/.config/backgrounds/* "$HOME/wezterm-wallpapers/" 2>/dev/null || true

# 13. Set executable permissions for all dotfiles scripts
echo "==> Ensuring script executable permissions..."
chmod +x "$HOME"/.config/hypr/scripts/*.sh 2>/dev/null || true
chmod +x "$HOME"/.config/waybar/scripts/*.sh 2>/dev/null || true
chmod +x "$HOME"/.config/rofi/*.sh 2>/dev/null || true
chmod +x "$HOME"/.config/zsh/*.sh 2>/dev/null || true

# 14. Enable system services
echo "==> Enabling system services..."
sudo systemctl enable --now power-profiles-daemon 2>/dev/null || true

# 15. Sudoers permissions for rfkill
echo "==> Configuring rfkill permissions for Waybar..."
RFKILL_PATH="$(which rfkill 2>/dev/null || echo '/usr/bin/rfkill')"
echo "$USER ALL=(ALL) NOPASSWD: $RFKILL_PATH" | sudo tee /etc/sudoers.d/enigma-rfkill > /dev/null
sudo chmod 0440 /etc/sudoers.d/enigma-rfkill

# 16. Set default login shell to Zsh
echo "==> Setting default login shell to Zsh..."
ZSH_BIN="$(which zsh 2>/dev/null || echo '/usr/bin/zsh')"
if ! grep -Fxq "$ZSH_BIN" /etc/shells; then
    echo "$ZSH_BIN" | sudo tee -a /etc/shells > /dev/null
fi
sudo chsh -s "$ZSH_BIN" "$USER" 2>/dev/null || true

echo "=================================================================="
echo "✅ Complete setup for Arch Linux finished successfully!"
echo "=================================================================="
