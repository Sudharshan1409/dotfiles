#!/usr/bin/env bash
# ==============================================================================
# scripts/setup/arch.sh - Arch Linux specific setup procedures
# ==============================================================================

setup_arch_packages() {
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
        uv
        nodejs
        npm
        hyprland
        hyprland-qtutils
        flatpak
        waybar
        sway-notification-center
        hyprpaper
        swww
        hypridle
        hyprlock
        rofi-wayland
        htop
        nvtop
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
        polkit-kde-agent
        libnotify
        xorg-xwayland
        kitty
        ghostty
        tmux
        neovim
        fastfetch
        btop
        eza
        fzf
        zoxide
        bat
        yazi
        lazygit
        git-delta
        starship
        fd
        ripgrep
        shellcheck
        tealdeer
        ttf-jetbrains-mono-nerd
        ttf-cascadia-mono-nerd
        ttf-nerd-fonts-symbols-mono
    )

    MISSING_PACMAN=()
    for pkg in "${PACMAN_PACKAGES[@]}"; do
        if [ "$pkg" = "tealdeer" ] && (pacman -Qi tealdeer >/dev/null 2>&1 || pacman -Qi tldr >/dev/null 2>&1 || command -v tldr >/dev/null 2>&1); then
            continue
        fi
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

    # Ensure Flathub repository is configured if Flatpak is present
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
    elif command -v yay >/dev/null 2>&1; then
        log_info "Installing LocalSend via yay..."
        yay -S --needed --noconfirm localsend-bin 2>/dev/null && log_ok "Installed LocalSend via AUR"
    elif command -v paru >/dev/null 2>&1; then
        log_info "Installing LocalSend via paru..."
        paru -S --needed --noconfirm localsend-bin 2>/dev/null && log_ok "Installed LocalSend via AUR"
    elif command -v flatpak >/dev/null 2>&1; then
        log_info "Installing LocalSend via Flatpak..."
        flatpak install -y flathub org.localsend.localsend_app 2>/dev/null || \
        sudo flatpak install -y flathub org.localsend.localsend_app 2>/dev/null || true
        log_ok "Installed LocalSend via Flatpak"
    else
        log_warn "Could not install LocalSend (neither AUR helper nor Flatpak found)"
    fi
}

setup_arch_displaylink() {
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

        ARCH_DISPLAYLINK_DEPS=(
            "$KERNEL_HEADERS"
            dkms
            libdrm
            base-devel
        )
        MISSING_DL_DEPS=()
        for pkg in "${ARCH_DISPLAYLINK_DEPS[@]}"; do
            if ! pacman -Qi "$pkg" >/dev/null 2>&1; then
                MISSING_DL_DEPS+=("$pkg")
            fi
        done
        if [ ${#MISSING_DL_DEPS[@]} -gt 0 ]; then
            log_info "Installing missing build dependencies: ${MISSING_DL_DEPS[*]}..."
            sudo pacman -S --needed --noconfirm "${MISSING_DL_DEPS[@]}" 2>/dev/null || true
            log_ok "Installed DisplayLink build dependencies"
        fi

        # 2. Detect or bootstrap AUR helper (yay / paru)
        AUR_HELPER=""
        if command -v yay >/dev/null 2>&1; then
            AUR_HELPER="yay"
        elif command -v paru >/dev/null 2>&1; then
            AUR_HELPER="paru"
        else
            log_info "No AUR helper found; bootstrapping yay-bin..."
            YAY_TMP="$(mktemp -d)"
            CLEANUP_TMP_DIRS="${CLEANUP_TMP_DIRS:-} $YAY_TMP"
            if git clone https://aur.archlinux.org/yay-bin.git "$YAY_TMP/yay-bin" >/dev/null 2>&1; then
                (cd "$YAY_TMP/yay-bin" && makepkg -si --noconfirm >/dev/null 2>&1) || true
                rm -rf "$YAY_TMP"
                if command -v yay >/dev/null 2>&1; then
                    AUR_HELPER="yay"
                    log_ok "Bootstrapped yay AUR helper"
                fi
            fi
        fi

        # 3. Install evdi and displaylink via AUR helper
        if [ -n "$AUR_HELPER" ]; then
            MISSING_AUR_PACKAGES=()
            if ! pacman -Qi evdi >/dev/null 2>&1 && ! pacman -Qi evdi-dkms >/dev/null 2>&1 && ! pacman -Qi evdi-git >/dev/null 2>&1; then
                MISSING_AUR_PACKAGES+=("evdi")
            fi
            if ! pacman -Qi displaylink >/dev/null 2>&1 && ! pacman -Qi displaylink-connect >/dev/null 2>&1; then
                MISSING_AUR_PACKAGES+=("displaylink")
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
}
