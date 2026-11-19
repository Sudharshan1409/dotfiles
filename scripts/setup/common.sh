#!/usr/bin/env bash
# ==============================================================================
# scripts/setup/common.sh - Shared configuration steps across all distributions
# ==============================================================================

setup_common_stow() {
    step_header "Verifying GNU Stow dotfiles linking"
    STOW_PACKAGES=(
        backgrounds
        bat
        caelestia
        fastfetch
        ghostty
        git
        hypr
        lazygit
        nvim
        rofi
        starship
        systemd
        tmux
        yazi
        zellij
        zsh
    )

    cd "$DOTFILES_DIR"
    # Ensure deprecated desktop packages are unstowed if stale symlinks exist
    for legacy_pkg in swaync waybar kitty; do
        if [ -d "$legacy_pkg" ]; then
            stow -D "$legacy_pkg" 2>/dev/null || true
        fi
    done
    # Ensure ~/.config/caelestia and ~/.config/fastfetch can be tree-folded cleanly if created before stow ran
    for fold_dir in "$HOME/.config/caelestia" "$HOME/.config/fastfetch"; do
        if [ -d "$fold_dir" ] && [ ! -L "$fold_dir" ]; then
            rm -rf "$fold_dir"
        fi
    done
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
    if [ -f "$HOME/.gitconfig" ] && grep -q "\.config/git/\.gitconfig" "$HOME/.gitconfig" 2>/dev/null; then
        log_skip "Git include for ~/.config/git/.gitconfig is already configured"
    else
        log_info "Configuring ~/.gitconfig to include ~/.config/git/.gitconfig..."
        git config --global include.path "~/.config/git/.gitconfig"
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
    step_header "Verifying user media directories"
    mkdir -p "$HOME/Pictures/Pics"
    mkdir -p "$HOME/Pictures/Screenshots"
    mkdir -p "$HOME/Videos/Recordings"
    log_ok "Verified ~/Pictures/Pics, ~/Pictures/Screenshots, and ~/Videos/Recordings"
}

setup_common_desktop_theme() {
    step_header "Verifying Catppuccin cursors & initial Caelestia theme"

    # 1. Install Catppuccin Mocha Dark cursors idempotently
    local CURSOR_DIR="$HOME/.local/share/icons/catppuccin-mocha-dark-cursors"
    if [ -d "$CURSOR_DIR" ] || [ -d "$HOME/.icons/catppuccin-mocha-dark-cursors" ]; then
        log_skip "Catppuccin Mocha Dark cursors are already installed"
    else
        log_info "Downloading Catppuccin Mocha Dark cursor theme..."
        mkdir -p "$HOME/.local/share/icons" "$HOME/.icons"
        local CURSOR_ZIP
        CURSOR_ZIP="$(mktemp --suffix=.zip)"
        if curl -fsSL "https://github.com/catppuccin/cursors/releases/latest/download/catppuccin-mocha-dark-cursors.zip" -o "$CURSOR_ZIP"; then
            python3 -m zipfile -e "$CURSOR_ZIP" "$HOME/.local/share/icons"
            ln -sfn "$CURSOR_DIR" "$HOME/.icons/catppuccin-mocha-dark-cursors"
            log_ok "Installed Catppuccin Mocha Dark cursors"
        else
            log_warn "Could not download Catppuccin Mocha Dark cursors"
        fi
        rm -f "$CURSOR_ZIP"
    fi

    # 2. Seed Rofi/Zellij/btop themes & user avatar (~/.face) before first wallpaper init
    mkdir -p "$HOME/.local/state/caelestia/theme"
    if [ ! -f "$HOME/.local/state/caelestia/theme/rofi-colors.rasi" ] && [ -f "$HOME/.config/rofi/colors-fallback.rasi" ]; then
        cp "$HOME/.config/rofi/colors-fallback.rasi" "$HOME/.local/state/caelestia/theme/rofi-colors.rasi"
    fi
    if [ ! -f "$HOME/.local/state/caelestia/theme/caelestia.kdl" ]; then
        cat > "$HOME/.local/state/caelestia/theme/caelestia.kdl" << 'EOF'
themes {
    caelestia {
        fg 205 214 244
        bg 17 17 27
        red 243 139 168
        green 137 180 250
        yellow 249 226 175
        blue 180 190 254
        magenta 203 166 247
        orange 250 179 135
        cyan 148 226 213
        black 30 30 46
        white 205 214 244
    }
}
EOF
    fi
    if [ -d "$HOME/.config/zellij" ]; then
        ln -sfn "$HOME/.local/state/caelestia/theme" "$HOME/.config/zellij/themes"
    fi
    if [ ! -f "$HOME/.local/state/caelestia/theme/ghostty.conf" ]; then
        cat > "$HOME/.local/state/caelestia/theme/ghostty.conf" << 'EOF'
background = #1e1e2e
foreground = #cdd6f4
cursor-color = #cba6f7
cursor-text = #11111b
selection-background = #313244
selection-foreground = #cdd6f4
EOF
    fi
    if [ -d "$HOME/.config/ghostty" ]; then
        ln -sfn "$HOME/.local/state/caelestia/theme" "$HOME/.config/ghostty/themes"
    fi
    if [ -f "$HOME/.config/caelestia/avatar.png" ] && [ ! -e "$HOME/.face" ]; then
        ln -sfn "$HOME/.config/caelestia/avatar.png" "$HOME/.face"
    fi
    if [ ! -f "$HOME/.config/btop/btop.conf" ]; then
        mkdir -p "$HOME/.config/btop"
        printf 'color_theme = "caelestia"\ntheme_background = False\n' > "$HOME/.config/btop/btop.conf"
    fi

    # 3. Initialize Caelestia wallpaper & dynamic dark palette on first boot
    export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
    if command -v caelestia >/dev/null 2>&1; then
        if [ ! -f "$HOME/.local/state/caelestia/wallpaper/path.txt" ] && [ -d "$HOME/.config/backgrounds" ]; then
            local INIT_WALL="$HOME/.config/backgrounds/Fantasy-Lake3.png"
            if [ ! -f "$INIT_WALL" ]; then
                INIT_WALL="$(find -L "$HOME/.config/backgrounds" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | sort | head -n 1)"
            fi
            if [ -n "$INIT_WALL" ] && [ -f "$INIT_WALL" ]; then
                log_info "Initializing default wallpaper ($(basename "$INIT_WALL")) & dynamic dark palette..."
                CAELESTIA_WALLPAPERS_DIR="$HOME/.config/backgrounds" caelestia wallpaper -f "$INIT_WALL" -n -N >/dev/null 2>&1 || true
                caelestia scheme set -n dynamic -m dark >/dev/null 2>&1 || true
                log_ok "Initialized Caelestia wallpaper and dynamic dark scheme"
            fi
        else
            log_skip "Caelestia wallpaper & color scheme state already initialized"
        fi
    fi
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

    if systemctl --user daemon-reload >/dev/null 2>&1; then
        systemctl --user enable caelestia-shell.service cliphist.service >/dev/null 2>&1 || true
        log_ok "Enabled systemd --user watchdog units (caelestia-shell & cliphist)"
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
