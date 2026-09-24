#!/usr/bin/env bash
# ==============================================================================
# scripts/setup/common.sh - Shared configuration steps across all distributions
# ==============================================================================

setup_common_stow() {
    step_header "Verifying GNU Stow dotfiles linking"
    STOW_PACKAGES=(
        bash
        zsh
        git
        tmux
        nvim
        wezterm
        kitty
        ghostty
        alacritty
        hypr
        waybar
        swaync
        rofi
        wlogout
        btop
        fastfetch
        yazi
    )

    cd "$DOTFILES_DIR"
    STOW_UPDATED=0
    for pkg in "${STOW_PACKAGES[@]}"; do
        if [ -d "$pkg" ]; then
            stow -R "$pkg" 2>/dev/null || true
            STOW_UPDATED=$((STOW_UPDATED + 1))
        fi
    done
    log_ok "Applied Stow symlinks for $STOW_UPDATED dotfile package(s)"
}

setup_common_git() {
    step_header "Verifying Git configuration"
    if [ -f "$HOME/.gitconfig" ] && grep -q "path = ~/.config/git/config" "$HOME/.gitconfig" 2>/dev/null; then
        log_skip "Git include.path is already configured"
    else
        log_info "Configuring ~/.gitconfig to include ~/.config/git/config..."
        git config --global include.path "~/.config/git/config"
        log_ok "Configured Git include.path"
    fi
}

setup_common_zsh_plugins() {
    step_header "Verifying Oh-My-Zsh & plugins"
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_info "Installing Oh-My-Zsh..."
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        log_ok "Installed Oh-My-Zsh"
    else
        log_skip "Oh-My-Zsh is already installed"
    fi

    # Declare Oh-My-Zsh custom plugins
    declare -A OMZ_PLUGINS=(
        ["plugins/zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
        ["plugins/zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
        ["plugins/fast-syntax-highlighting"]="https://github.com/zdharma-continuum/fast-syntax-highlighting.git"
        ["plugins/fzf-tab"]="https://github.com/Aloxaf/fzf-tab"
        ["plugins/zsh-completions"]="https://github.com/zsh-users/zsh-completions"
    )

    PLUGINS_ADDED=0
    for plugin_path in "${!OMZ_PLUGINS[@]}"; do
        TARGET_DIR="$ZSH_CUSTOM/$plugin_path"
        REPO_URL="${OMZ_PLUGINS[$plugin_path]}"
        if [ ! -d "$TARGET_DIR" ]; then
            log_info "Cloning $(basename "$plugin_path")..."
            git clone --depth 1 "$REPO_URL" "$TARGET_DIR" >/dev/null 2>&1
            PLUGINS_ADDED=$((PLUGINS_ADDED + 1))
        fi
    done

    if [ $PLUGINS_ADDED -eq 0 ]; then
        log_skip "All Oh-My-Zsh custom plugins are already present"
    else
        log_ok "Installed $PLUGINS_ADDED missing Oh-My-Zsh plugin(s)"
    fi
}

setup_common_python_venv() {
    step_header "Verifying Enigma CLI virtual environment"
    VENV_DIR="$HOME/.config/zsh/venv"
    REQ_FILE="$HOME/.config/zsh/python/requirements.txt"

    if [ -x "$VENV_DIR/bin/python3" ] && "$VENV_DIR/bin/python3" -c "import InquirerPy, rich" 2>/dev/null; then
        log_skip "Enigma CLI Python virtualenv is already installed with all dependencies"
    else
        log_info "Bootstrapping Enigma CLI virtualenv at $VENV_DIR..."
        if command -v uv >/dev/null 2>&1; then
            uv venv --allow-existing "$VENV_DIR" >/dev/null 2>&1
            uv pip install --python "$VENV_DIR/bin/python3" -r "$REQ_FILE" >/dev/null 2>&1
        else
            PYTHON_EXEC="/home/linuxbrew/.linuxbrew/bin/python3"
            [ ! -x "$PYTHON_EXEC" ] && PYTHON_EXEC="$(which python3)"
            "$PYTHON_EXEC" -m venv "$VENV_DIR"
            "$VENV_DIR/bin/pip" install --quiet --upgrade pip
            "$VENV_DIR/bin/pip" install --quiet -r "$REQ_FILE"
        fi
        log_ok "Configured Enigma CLI virtualenv"
    fi
}

setup_common_neovim() {
    step_header "Verifying Neovim plugins (Lazy.nvim)"
    if [ -d "$HOME/.local/share/nvim/lazy/nvim-treesitter" ] && [ -d "$HOME/.local/share/nvim/lazy/which-key.nvim" ]; then
        log_skip "Neovim plugins already installed via Lazy.nvim"
    else
        log_info "Syncing Neovim plugins via Lazy.nvim..."
        nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 || true
        log_ok "Synced Neovim plugins"
    fi
}

setup_common_tmux() {
    step_header "Verifying Tmux Plugin Manager (TPM)"
    TPM_DIR="$HOME/.tmux/plugins/tpm"
    if [ -d "$TPM_DIR" ]; then
        log_skip "Tmux Plugin Manager is already installed"
    else
        log_info "Installing Tmux Plugin Manager..."
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR" >/dev/null 2>&1
        "$TPM_DIR/bin/install_plugins" >/dev/null 2>&1 || true
        log_ok "Installed TPM and initial plugins"
    fi
}

setup_common_bat() {
    step_header "Verifying Bat theme cache"
    if command -v bat >/dev/null 2>&1; then
        bat cache --build >/dev/null 2>&1 || true
        log_ok "Built Bat theme cache"
    elif command -v batcat >/dev/null 2>&1; then
        batcat cache --build >/dev/null 2>&1 || true
        log_ok "Built Batcat theme cache"
    else
        log_skip "Bat executable not found in PATH; skipping cache build"
    fi
}

setup_common_yazi() {
    step_header "Verifying Yazi theme"
    YAZI_THEME_TARGET="$HOME/.config/yazi/theme.toml"
    YAZI_CATPPUCCIN="$HOME/.config/yazi/flavors/catppuccin-mocha.yazi/flavor.toml"
    if [ -e "$YAZI_THEME_TARGET" ] || [ -L "$YAZI_THEME_TARGET" ]; then
        log_skip "Yazi theme configuration already exists at ~/.config/yazi/theme.toml"
    elif [ -f "$YAZI_CATPPUCCIN" ]; then
        ln -sf "$YAZI_CATPPUCCIN" "$YAZI_THEME_TARGET"
        log_ok "Symlinked Catppuccin Mocha flavor to ~/.config/yazi/theme.toml"
    else
        log_skip "Yazi flavors directory not found; skipping theme symlink"
    fi
}

setup_common_picture_dirs() {
    step_header "Verifying user picture directories"
    mkdir -p "$HOME/Pictures/Screenshots"
    mkdir -p "$HOME/Pictures/Wallpapers"
    log_ok "Created ~/Pictures/Screenshots and ~/Pictures/Wallpapers"
}

setup_common_permissions() {
    step_header "Verifying script executable permissions"
    find "$DOTFILES_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
    find "$HOME/.local/bin" -type f -exec chmod +x {} + 2>/dev/null || true
    find "$DOTFILES_DIR/hypr/.config/hypr/scripts" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
    log_ok "Ensured executable permissions on all shell scripts"
}

setup_common_services() {
    step_header "Verifying system services (power-profiles-daemon)"
    if systemctl is-enabled power-profiles-daemon >/dev/null 2>&1; then
        log_skip "power-profiles-daemon service is already enabled"
    elif systemctl list-unit-files power-profiles-daemon.service >/dev/null 2>&1; then
        sudo systemctl enable --now power-profiles-daemon 2>/dev/null || true
        log_ok "Enabled and started power-profiles-daemon service"
    else
        log_skip "power-profiles-daemon service unit not found; skipping"
    fi
}

setup_common_rfkill() {
    step_header "Verifying rfkill sudoers permission for Waybar"
    RFKILL_SUDOERS="/etc/sudoers.d/waybar-rfkill"
    if [ -f "$RFKILL_SUDOERS" ] && grep -q "rfkill" "$RFKILL_SUDOERS" 2>/dev/null; then
        log_skip "rfkill passwordless sudoers entry already exists at $RFKILL_SUDOERS"
    else
        log_info "Configuring passwordless sudo for rfkill (Waybar airplane mode toggle)..."
        echo "$USER ALL=(ALL) NOPASSWD: /usr/sbin/rfkill, /usr/bin/rfkill" | sudo tee "$RFKILL_SUDOERS" >/dev/null
        sudo chmod 0440 "$RFKILL_SUDOERS"
        log_ok "Created $RFKILL_SUDOERS"
    fi
}

setup_common_shell() {
    step_header "Verifying default login shell (Zsh)"
    CURRENT_SHELL="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7)"
    ZSH_BIN="$(command -v zsh 2>/dev/null || which zsh 2>/dev/null || true)"

    if [ "$CURRENT_SHELL" = "$ZSH_BIN" ]; then
        log_skip "Default shell is already $ZSH_BIN"
    elif [ -n "$ZSH_BIN" ]; then
        log_info "Setting default shell to $ZSH_BIN for user $USER..."
        if ! grep -q "^$ZSH_BIN$" /etc/shells 2>/dev/null; then
            echo "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null
        fi
        sudo chsh -s "$ZSH_BIN" "$USER"
        log_ok "Default shell changed to $ZSH_BIN"
    else
        log_warn "Zsh executable not found; skipping shell change"
    fi
}

setup_common_brightness() {
    step_header "Verifying video group and backlight udev rules"
    if id -nG "$USER" 2>/dev/null | grep -qw "video"; then
        log_skip "User $USER is already in the video group"
    else
        log_info "Adding user $USER to the video group..."
        sudo usermod -aG video "$USER"
        log_ok "Added user $USER to the video group (takes effect on next login)"
    fi

    UDEV_BACKLIGHT="/etc/udev/rules.d/90-backlight.rules"
    if [ -f "$UDEV_BACKLIGHT" ]; then
        log_skip "Backlight udev rule already exists at $UDEV_BACKLIGHT"
    else
        log_info "Creating backlight udev rule for unprivileged brightness control..."
        echo 'ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"' | sudo tee "$UDEV_BACKLIGHT" >/dev/null
        sudo udevadm control --reload-rules 2>/dev/null || true
        sudo udevadm trigger --subsystem-match=backlight 2>/dev/null || true
        log_ok "Configured backlight udev rule at $UDEV_BACKLIGHT"
    fi
}

setup_common_ethernet() {
    step_header "Verifying Ethernet connections DHCP configuration"
    if ! command -v nmcli >/dev/null 2>&1; then
        log_skip "NetworkManager CLI (nmcli) not available; skipping Ethernet DHCP configuration"
    else
        ETH_UPDATED=0
        while IFS=: read -r conn_name conn_uuid conn_type; do
            if [ -n "$conn_name" ] && [ -n "$conn_uuid" ]; then
                CURRENT_METHOD="$(nmcli -g ipv4.method connection show uuid "$conn_uuid" 2>/dev/null || true)"
                if [ "$CURRENT_METHOD" != "auto" ]; then
                    nmcli connection modify uuid "$conn_uuid" ipv4.method auto 2>/dev/null || true
                    ETH_UPDATED=$((ETH_UPDATED + 1))
                fi
            fi
        done < <(nmcli -t -f NAME,UUID,TYPE connection show 2>/dev/null | grep -E ':802-3-ethernet$|:ethernet$' || true)

        if [ "$ETH_UPDATED" -eq 0 ]; then
            log_skip "All Ethernet connections already configured for DHCP (auto)"
        else
            log_ok "Configured DHCP (auto) on $ETH_UPDATED Ethernet connection profile(s)"
        fi
    fi
}

setup_common_grub_theme() {
    step_header "Verifying WhiteSur GRUB theme"
    GRUB_THEME_REPO="https://github.com/vinceliuice/grub2-themes.git"
    GRUB_THEME_SCREEN="${GRUB_THEME_SCREEN:-1080p}"
    GRUB_THEME_INSTALLED=false

    for theme_path in \
        "/usr/share/grub/themes/whitesur/theme.txt" \
        "/boot/grub/themes/whitesur/theme.txt" \
        "/boot/grub2/themes/whitesur/theme.txt"; do
        if [ -f "$theme_path" ]; then
            GRUB_THEME_INSTALLED=true
            break
        fi
    done

    if [ "$GRUB_THEME_INSTALLED" = true ] && grep -q 'whitesur' /etc/default/grub 2>/dev/null; then
        log_skip "WhiteSur GRUB theme is already installed"
    else
        # Install OS-specific dependencies for WhiteSur installer if missing
        if [ "$OS_TYPE" = "ubuntu" ] || [ "$OS_TYPE" = "debian" ]; then
            GRUB_THEME_DEPS=(git grub2-common grub-efi-amd64-bin imagemagick)
            MISSING_GRUB_DEPS=()
            for pkg in "${GRUB_THEME_DEPS[@]}"; do
                if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
                    MISSING_GRUB_DEPS+=("$pkg")
                fi
            done
            if [ ${#MISSING_GRUB_DEPS[@]} -gt 0 ]; then
                log_info "Installing WhiteSur GRUB dependencies: ${MISSING_GRUB_DEPS[*]}"
                sudo apt-get update -qq || true
                sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${MISSING_GRUB_DEPS[@]}"
            fi
        elif [ "$OS_TYPE" = "arch" ]; then
            GRUB_THEME_DEPS=(grub imagemagick)
            MISSING_GRUB_DEPS=()
            for pkg in "${GRUB_THEME_DEPS[@]}"; do
                if ! pacman -Qi "$pkg" >/dev/null 2>&1; then
                    MISSING_GRUB_DEPS+=("$pkg")
                fi
            done
            if [ ${#MISSING_GRUB_DEPS[@]} -gt 0 ]; then
                log_info "Installing WhiteSur GRUB dependencies: ${MISSING_GRUB_DEPS[*]}"
                sudo pacman -S --needed --noconfirm "${MISSING_GRUB_DEPS[@]}"
            fi
        fi

        GRUB_THEME_TMP="$(mktemp -d)"
        CLEANUP_TMP_DIRS="${CLEANUP_TMP_DIRS:-} $GRUB_THEME_TMP"

        log_info "Downloading WhiteSur GRUB theme installer..."
        git clone --depth=1 "$GRUB_THEME_REPO" "$GRUB_THEME_TMP/grub2-themes" >/dev/null 2>&1
        chmod +x "$GRUB_THEME_TMP/grub2-themes/install.sh" 2>/dev/null || true

        log_info "Installing WhiteSur GRUB theme (${GRUB_THEME_SCREEN})..."
        sudo "$GRUB_THEME_TMP/grub2-themes/install.sh" \
            -t whitesur \
            -i whitesur \
            -s "$GRUB_THEME_SCREEN"

        rm -rf "$GRUB_THEME_TMP"
        log_ok "Installed WhiteSur GRUB theme"
    fi
}
