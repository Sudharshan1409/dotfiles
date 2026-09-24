#!/usr/bin/env bash
# ==============================================================================
# scripts/setup/ubuntu.sh - Ubuntu / Debian specific setup procedures
# ==============================================================================

setup_ubuntu_packages() {
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
        flatpak
        hyprland
        hyprland-qtutils
        waybar
        sway-notification-center
        hyprpaper
        hypridle
        hyprlock
        rofi
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
        pavucontrol
        blueman
        brightnessctl
        playerctl
        polkit-kde-agent-1
        libnotify-bin
        xwayland
        kitty
        ghostty
        tmux
        neovim
        fastfetch
        btop
        fonts-jetbrains-mono
        fonts-font-awesome
    )

    MISSING_APT=()
    for pkg in "${APT_PACKAGES[@]}"; do
        if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
            MISSING_APT+=("$pkg")
        fi
    done

    if [ ${#MISSING_APT[@]} -eq 0 ]; then
        log_skip "All ${#APT_PACKAGES[@]} base APT packages are already installed"
    else
        log_info "Installing ${#MISSING_APT[@]} missing APT package(s)..."
        sudo apt-get update -qq
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${MISSING_APT[@]}"
        log_ok "Installed missing APT package(s)"
    fi

    # Ensure Flathub repository is configured
    if command -v flatpak >/dev/null 2>&1; then
        if flatpak remotes 2>/dev/null | grep -q "flathub"; then
            log_skip "Flathub repository is already configured"
        else
            log_info "Configuring Flathub remote repository..."
            flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
            log_ok "Configured Flathub remote repository"
        fi
    fi

    # Ensure LocalSend (LAN file sharing)
    if command -v localsend >/dev/null 2>&1 || (command -v flatpak >/dev/null 2>&1 && flatpak list 2>/dev/null | grep -q "org.localsend.localsend_app"); then
        log_skip "LocalSend is already installed"
    elif command -v flatpak >/dev/null 2>&1; then
        log_info "Installing LocalSend via Flatpak..."
        flatpak install -y flathub org.localsend.localsend_app 2>/dev/null || \
        sudo flatpak install -y flathub org.localsend.localsend_app 2>/dev/null || true
        log_ok "Installed LocalSend via Flatpak"
    elif command -v snap >/dev/null 2>&1; then
        log_info "Installing LocalSend via Snap..."
        sudo snap install localsend 2>/dev/null && log_ok "Installed LocalSend via Snap"
    else
        log_warn "Neither Flatpak nor Snap found to install LocalSend"
    fi
}

setup_ubuntu_homebrew() {
    # 3. Ensure Homebrew is installed for modern CLI tools
    step_header "Verifying Homebrew (Linuxbrew) & CLI tools"
    if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ] || command -v brew >/dev/null 2>&1; then
        log_skip "Homebrew is already installed"
    else
        log_info "Installing Homebrew for modern CLI tools..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        log_ok "Homebrew installed successfully"
    fi

    # Initialize brew in the current subshell
    if [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi

    BREW_PACKAGES=(
        eza
        fzf
        zoxide
        bat
        yazi
        fd
        ripgrep
        starship
        fastfetch
        btop
        lazygit
        git-delta
        tlrc
    )

    MISSING_BREW=()
    for pkg in "${BREW_PACKAGES[@]}"; do
        if [ "$pkg" = "tlrc" ] && command -v tldr >/dev/null 2>&1; then
            continue
        fi
        if ! brew list --formula "$pkg" >/dev/null 2>&1; then
            MISSING_BREW+=("$pkg")
        fi
    done

    if [ ${#MISSING_BREW[@]} -eq 0 ]; then
        log_skip "All ${#BREW_PACKAGES[@]} Homebrew CLI utilities are already installed"
    else
        log_info "Installing missing Homebrew formula(e): ${MISSING_BREW[*]}..."
        brew install "${MISSING_BREW[@]}"
        log_ok "Installed missing Homebrew formula(e)"
    fi

    # 4. Configure fzf shell integration
    step_header "Verifying fzf shell integration"
    FZF_BREW_PREFIX="$(brew --prefix fzf 2>/dev/null || true)"
    if [ -n "$FZF_BREW_PREFIX" ] && [ -x "$FZF_BREW_PREFIX/install" ]; then
        if [ -f "$HOME/.fzf.zsh" ] && [ -f "$HOME/.fzf.bash" ]; then
            log_skip "fzf shell bindings already installed at ~/.fzf.zsh and ~/.fzf.bash"
        else
            log_info "Configuring fzf shell integration via brew install script..."
            "$FZF_BREW_PREFIX/install" --bin --no-key-bindings --no-completion --no-update-rc >/dev/null 2>&1 || true
            log_ok "Configured fzf shell integration"
        fi
    else
        log_skip "fzf binary is available via Homebrew PATH"
    fi

    # 5. Symlink core CLI tools to ~/.local/bin
    step_header "Verifying CLI tool symlinks in ~/.local/bin"
    mkdir -p "$HOME/.local/bin"
    SYMLINK_COUNT=0
    for tool in eza fzf zoxide bat yazi fd rg starship fastfetch btop lazygit delta tldr ghostty; do
        TOOL_PATH="$(command -v "$tool" 2>/dev/null || true)"
        if [ -n "$TOOL_PATH" ] && [ ! -e "$HOME/.local/bin/$tool" ]; then
            ln -sf "$TOOL_PATH" "$HOME/.local/bin/$tool"
            SYMLINK_COUNT=$((SYMLINK_COUNT + 1))
        fi
    done
    if [ $SYMLINK_COUNT -gt 0 ]; then
        log_ok "Created $SYMLINK_COUNT CLI tool symlink(s) in ~/.local/bin"
    else
        log_skip "All CLI tool symlinks in ~/.local/bin are already present"
    fi

    # 6. Install standalone tools and fonts if missing
    step_header "Verifying standalone tools (Satty, Fonts)"
    if command -v satty >/dev/null 2>&1 || [ -x "$HOME/.local/bin/satty" ]; then
        log_skip "Satty screenshot annotation tool is already installed"
    else
        log_info "Downloading Satty AppImage..."
        SATTY_URL="https://github.com/gabm/Satty/releases/latest/download/satty-x86_64.AppImage"
        if curl -fsSL "$SATTY_URL" -o "$HOME/.local/bin/satty" 2>/dev/null; then
            chmod +x "$HOME/.local/bin/satty"
            log_ok "Installed Satty to ~/.local/bin/satty"
        else
            log_warn "Failed to download Satty from GitHub; skipping"
        fi
    fi

    FONT_DIR="$HOME/.local/share/fonts"
    if [ -f "$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf" ] && [ -f "$FONT_DIR/CaskaydiaCoveNerdFont-Regular.ttf" ]; then
        log_skip "Nerd Fonts (JetBrainsMono, CascadiaCode) are already installed"
    else
        log_info "Installing Nerd Fonts..."
        mkdir -p "$FONT_DIR"
        JB_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
        CC_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.tar.xz"
        curl -fsSL "$JB_URL" | tar -xJ -C "$FONT_DIR" 2>/dev/null || true
        curl -fsSL "$CC_URL" | tar -xJ -C "$FONT_DIR" 2>/dev/null || true
        fc-cache -f "$FONT_DIR" 2>/dev/null || true
        log_ok "Installed Nerd Fonts to $FONT_DIR"
    fi
}

setup_ubuntu_displaylink() {
    step_header "Verifying DisplayLink driver & EVDI module"
    if dpkg-query -W -f='${Status}' displaylink-driver 2>/dev/null | grep -q "ok installed" && \
       systemctl is-active displaylink-driver >/dev/null 2>&1; then
        log_skip "DisplayLink driver and service are already installed and active"
    else
        log_info "Configuring DisplayLink driver and EVDI kernel module..."

        # 1. Ensure kernel build headers and DKMS dependencies
        KERNEL_HEADERS="linux-headers-$(uname -r)"
        UBUNTU_DISPLAYLINK_DEPS=(
            "$KERNEL_HEADERS"
            dkms
            libdrm-dev
            build-essential
        )
        MISSING_DL_DEPS=()
        for pkg in "${UBUNTU_DISPLAYLINK_DEPS[@]}"; do
            if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
                MISSING_DL_DEPS+=("$pkg")
            fi
        done
        if [ ${#MISSING_DL_DEPS[@]} -gt 0 ]; then
            log_info "Installing missing build dependencies: ${MISSING_DL_DEPS[*]}..."
            sudo apt-get update -qq
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${MISSING_DL_DEPS[@]}"
            log_ok "Installed DisplayLink build dependencies"
        fi

        # 2. Configure Synaptics official APT repository keyring & source list
        SYNAPTICS_KEYRING="/usr/share/keyrings/synaptics-repository-keyring.gpg"
        SYNAPTICS_LIST="/etc/apt/sources.list.d/synaptics.list"
        if [ ! -f "$SYNAPTICS_KEYRING" ]; then
            log_info "Fetching Synaptics repository signing key..."
            curl -fsSL "https://www.synaptics.com/sites/default/files/Ubuntu/synaptics-repository-keyring.gpg" | \
                sudo tee "$SYNAPTICS_KEYRING" >/dev/null 2>&1 || true
        fi
        if [ ! -f "$SYNAPTICS_LIST" ]; then
            log_info "Adding Synaptics APT repository..."
            echo "deb [signed-by=$SYNAPTICS_KEYRING] https://www.synaptics.com/sites/default/files/Ubuntu/apt stable main" | \
                sudo tee "$SYNAPTICS_LIST" >/dev/null
            sudo apt-get update -qq || true
            log_ok "Configured Synaptics APT repository"
        fi

        # 3. Install displaylink-driver
        if apt-cache show displaylink-driver >/dev/null 2>&1; then
            log_info "Installing displaylink-driver package..."
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y displaylink-driver
            log_ok "Installed displaylink-driver package"
        else
            log_warn "displaylink-driver package not found in APT cache; skipping driver installation"
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
}
