#!/usr/bin/env bash
set -e

# ==============================================================================
# Dotfiles & System Setup Script for Ubuntu Linux
# ==============================================================================

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.local/bin:/home/linuxbrew/.linuxbrew/bin:$PATH"

echo "=================================================================="
echo "  Starting Complete Dotfiles & Environment Setup for Ubuntu"
echo "=================================================================="

# 1. Elevate sudo privileges once and keep alive in background
echo "==> Requesting sudo privileges..."
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_PID=$!
trap 'kill $SUDO_PID 2>/dev/null' EXIT

# 2. Update APT and install system dependencies
echo "==> Updating APT repositories..."
sudo apt-get update -y

echo "==> Installing system packages and Wayland environment via APT..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    cmake \
    pkg-config \
    git \
    curl \
    wget \
    stow \
    zsh \
    python3 \
    python3-venv \
    python3-pip \
    libfuse2t64 \
    hyprland \
    hyprland-qtutils \
    waybar \
    sway-notification-center \
    hyprpaper \
    hypridle \
    hyprlock \
    rofi \
    wofi \
    ghostty \
    htop \
    nautilus \
    grim \
    slurp \
    wf-recorder \
    wl-clipboard \
    cliphist \
    tesseract-ocr \
    tesseract-ocr-eng \
    network-manager-gnome \
    brightnessctl \
    playerctl \
    pamixer \
    pavucontrol \
    blueman \
    power-profiles-daemon \
    libnotify-bin \
    policykit-1-gnome \
    libgtk4-layer-shell0

# 3. Ensure Homebrew is installed for modern CLI tools
if ! command -v brew >/dev/null 2>&1 && [ ! -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    echo "==> Preparing /home/linuxbrew directory..."
    sudo mkdir -p /home/linuxbrew/.linuxbrew
    sudo chown -R "$USER:$USER" /home/linuxbrew
    echo "==> Installing Homebrew (Linuxbrew)..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Ensure brew shellenv is persisted in ~/.profile for login shells
if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ] && ! grep -q "linuxbrew.*shellenv" "$HOME/.profile" 2>/dev/null; then
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.profile"
fi

echo "==> Installing modern CLI tools via Homebrew..."
NONINTERACTIVE=1 brew install \
    zsh \
    neovim \
    tmux \
    bat \
    eza \
    lsd \
    zoxide \
    git-delta \
    jq \
    gh \
    fzf \
    yazi \
    zellij \
    starship \
    lazygit \
    fd \
    ripgrep \
    python \
    node \
    htop \
    nvtop

# 4. Configure fzf shell integration
echo "==> Configuring fzf..."
if [ -d "$(brew --prefix 2>/dev/null)/opt/fzf" ]; then
    "$(brew --prefix)/opt/fzf/install" --all --no-update-rc >/dev/null 2>&1 || true
fi

# Symlink core CLI tools to ~/.local/bin
for bin in node npm npx htop nvtop; do
    if [ -x "/home/linuxbrew/.linuxbrew/bin/$bin" ]; then
        ln -sf "/home/linuxbrew/.linuxbrew/bin/$bin" "$HOME/.local/bin/$bin"
    fi
done

# 5. Install standalone terminal emulators and launchers if missing
mkdir -p "$HOME/.local/bin"

# Kitty
if ! command -v kitty >/dev/null 2>&1 && [ ! -x "$HOME/.local/kitty.app/bin/kitty" ]; then
    echo "==> Installing Kitty terminal emulator..."
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
    ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/bin/kitty"
    ln -sf "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/kitten"
elif [ -x "$HOME/.local/kitty.app/bin/kitty" ]; then
    ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/bin/kitty"
    ln -sf "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/kitten"
fi

# WezTerm
if ! command -v wezterm >/dev/null 2>&1 && [ ! -x "$HOME/.local/wezterm-app/usr/bin/wezterm" ]; then
    echo "==> Installing WezTerm..."
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
fi

# Walker launcher
if ! command -v walker >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/walker" ]; then
    echo "==> Installing Walker Wayland launcher..."
    WALKER_URL=$(curl -s https://api.github.com/repos/abenz1267/walker/releases/latest | grep -o 'https://[^"]*x86_64-unknown-linux-gnu.tar.gz' | head -n 1)
    if [ -n "$WALKER_URL" ]; then
        curl -fsSL "$WALKER_URL" | tar -xz -C "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/walker"
    fi
fi

# Satty screenshot annotation tool
if ! command -v satty >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/satty" ]; then
    echo "==> Installing Satty screenshot editor..."
    curl -sL https://github.com/Satty-org/Satty/releases/download/v0.22.0/satty-x86_64-unknown-linux-gnu.tar.gz | tar -xz -C "$HOME/.local/bin/" 2>/dev/null || true
    chmod +x "$HOME/.local/bin/satty" 2>/dev/null || true
fi

# Install Nerd Fonts (JetBrainsMono, CascadiaMono, Symbols)
if ! fc-list : family 2>/dev/null | grep -qi "JetBrainsMono.*Nerd"; then
    echo "==> Installing JetBrainsMono and CascadiaMono Nerd Fonts..."
    mkdir -p "$HOME/.local/share/fonts/JetBrainsMono" "$HOME/.local/share/fonts/CascadiaMono" "$HOME/.local/share/fonts/NerdFontsSymbolsOnly"
    curl -sL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/JetBrainsMono.tar.xz | tar -xJ -C "$HOME/.local/share/fonts/JetBrainsMono/" 2>/dev/null || true
    curl -sL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/CascadiaMono.tar.xz | tar -xJ -C "$HOME/.local/share/fonts/CascadiaMono/" 2>/dev/null || true
    curl -sL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/NerdFontsSymbolsOnly.tar.xz | tar -xJ -C "$HOME/.local/share/fonts/NerdFontsSymbolsOnly/" 2>/dev/null || true
    fc-cache -f 2>/dev/null || true
fi

# 6. Apply Stow configuration for all Linux packages
echo "==> Linking dotfiles via GNU Stow..."
cd "$DOTFILES_DIR"
stow -v -t "$HOME" \
    backgrounds bat ghostty git hypr kitty lazygit nvim rofi starship swaync tmux walker waybar wezterm wofi yazi zellij zsh

# 7. Git configuration include
echo "==> Setting up Git configuration..."
if [ ! -f "$HOME/.gitconfig" ] || ! grep -q "\.config/git/\.gitconfig" "$HOME/.gitconfig"; then
    printf "[include]\n\tpath = ~/.config/git/.gitconfig\n" >> "$HOME/.gitconfig"
fi

# 8. Set up Oh-My-Zsh and plugins
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

# 9. Set up Python virtual environment for Enigma CLI
echo "==> Setting up Enigma CLI virtual environment..."
PYTHON_EXEC="/home/linuxbrew/.linuxbrew/bin/python3"
[ ! -x "$PYTHON_EXEC" ] && PYTHON_EXEC="$(which python3)"

if [ ! -d "$HOME/.config/zsh/venv" ]; then
    "$PYTHON_EXEC" -m venv "$HOME/.config/zsh/venv"
    "$HOME/.config/zsh/venv/bin/pip" install --upgrade pip
    "$HOME/.config/zsh/venv/bin/pip" install -r "$HOME/.config/zsh/python/requirements.txt"
fi

# 10. Bootstrap Neovim plugins
echo "==> Bootstrapping Neovim plugins (Lazy.nvim)..."
nvim --headless "+Lazy! sync" +qa 2>/dev/null || true

# 11. Bootstrap Tmux Plugin Manager (TPM)
echo "==> Setting up Tmux Plugin Manager..."
if [ ! -d "$HOME/.config/tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
fi
"$HOME/.config/tmux/plugins/tpm/bin/install_plugins" 2>/dev/null || true

# 12. Build Bat theme cache
echo "==> Building Bat theme cache..."
bat cache --build 2>/dev/null || true

# 13. Deploy Yazi Catppuccin theme
echo "==> Deploying Yazi theme..."
ya pkg install 2>/dev/null || ya pack -a yazi-rs/flavors:catppuccin-frappe 2>/dev/null || true

# 14. Set up WezTerm wallpapers directory
echo "==> Initializing WezTerm wallpapers..."
mkdir -p "$HOME/wezterm-wallpapers"
cp -u "$DOTFILES_DIR"/backgrounds/.config/backgrounds/* "$HOME/wezterm-wallpapers/" 2>/dev/null || true

# 15. Set executable permissions for all dotfiles scripts
echo "==> Ensuring script executable permissions..."
chmod +x "$HOME"/.config/hypr/scripts/*.sh 2>/dev/null || true
chmod +x "$HOME"/.config/waybar/scripts/*.sh 2>/dev/null || true
chmod +x "$HOME"/.config/rofi/*.sh 2>/dev/null || true
chmod +x "$HOME"/.config/zsh/*.sh 2>/dev/null || true

# 16. Enable system services
echo "==> Enabling system services..."
sudo systemctl enable --now power-profiles-daemon 2>/dev/null || true

# 17. Sudoers permissions for rfkill
echo "==> Configuring rfkill permissions for Waybar..."
RFKILL_PATH="$(which rfkill 2>/dev/null || echo '/usr/sbin/rfkill')"
echo "$USER ALL=(ALL) NOPASSWD: $RFKILL_PATH" | sudo tee /etc/sudoers.d/enigma-rfkill > /dev/null
sudo chmod 0440 /etc/sudoers.d/enigma-rfkill

# 18. Set default login shell to Zsh
echo "==> Setting default login shell to Zsh..."
ZSH_BIN="$(which zsh 2>/dev/null || echo '/bin/zsh')"
if ! grep -Fxq "$ZSH_BIN" /etc/shells; then
    echo "$ZSH_BIN" | sudo tee -a /etc/shells > /dev/null
fi
sudo chsh -s "$ZSH_BIN" "$USER" 2>/dev/null || true

echo "=================================================================="
echo "✅ Complete setup for Ubuntu finished successfully!"
echo "=================================================================="
