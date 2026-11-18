#!/usr/bin/env bash
# ==============================================================================
# scripts/setup/ubuntu.sh - Ubuntu / Debian specific setup procedures
# ==============================================================================

setup_ubuntu_packages() {
    # 2. Update APT and install system dependencies
    step_header "Verifying APT system packages & Wayland environment"

    # Ensure cppiber/hyprland PPA is configured and enabled for the latest Hyprland release
    UBUNTU_CODENAME="${UBUNTU_CODENAME:-$(. /etc/os-release && echo "$VERSION_CODENAME")}"
    PPA_UPDATED=false

    for src in /etc/apt/sources.list.d/*hyprland*.sources /etc/apt/sources.list.d/*hyprland*.list; do
        if [ -f "$src" ]; then
            if grep -q "Enabled: no" "$src" 2>/dev/null; then
                log_info "Re-enabling Hyprland PPA in $(basename "$src")..."
                sudo sed -i 's/Enabled: no/Enabled: yes/g' "$src"
                PPA_UPDATED=true
            fi
            if [ -n "$UBUNTU_CODENAME" ] && grep -q "Suites:" "$src" 2>/dev/null && ! grep -q "Suites: $UBUNTU_CODENAME" "$src" 2>/dev/null; then
                log_info "Updating Hyprland PPA suite to $UBUNTU_CODENAME in $(basename "$src")..."
                sudo sed -i "s/Suites: .*/Suites: $UBUNTU_CODENAME/g" "$src"
                PPA_UPDATED=true
            fi
        fi
    done

    if ! grep -rq "ppa.launchpadcontent.net/cppiber/hyprland" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
        log_info "Adding ppa:cppiber/hyprland for latest Hyprland release..."
        sudo DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:cppiber/hyprland
        PPA_UPDATED=true
    fi

    if [ "$PPA_UPDATED" = true ]; then
        sudo apt-get update -qq
    fi

    # Determine Hyprland GUI dialog helper (hyprland-guiutils on 0.56+, hyprland-qtutils on legacy)
    HYPR_GUI_HELPER="hyprland-guiutils"
    if ! apt-cache show hyprland-guiutils >/dev/null 2>&1; then
        HYPR_GUI_HELPER="hyprland-qtutils"
    fi

    APT_PACKAGES=(
        build-essential
        tree
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
        "$HYPR_GUI_HELPER"
        xdg-desktop-portal-hyprland
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
        tmux
        neovim
        fastfetch
        btop
        fonts-jetbrains-mono
        fonts-font-awesome
    )

    # Conditionally include ghostty if available in APT repositories (e.g. Ubuntu 26.04+)
    if apt-cache show ghostty >/dev/null 2>&1; then
        APT_PACKAGES+=(ghostty)
    fi

    MISSING_APT=()
    for pkg in "${APT_PACKAGES[@]}"; do
        if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
            MISSING_APT+=("$pkg")
        fi
    done

    # Check and repair any broken dependencies or half-installed packages from previous interruptions
    if ! dpkg --audit >/dev/null 2>&1 || ! apt-get check >/dev/null 2>&1; then
        log_info "Repairing broken APT dependencies..."
        # If older distribution libraries conflict with PPA renamed packages (e.g. libhyprcursor0 vs libhyprcursor1)
        sudo dpkg --configure -a 2>/dev/null || true
        sudo DEBIAN_FRONTEND=noninteractive apt-get install --fix-broken -y -o Dpkg::Options::="--force-overwrite"
        log_ok "Repaired APT dependencies"
    fi

    if [ ${#MISSING_APT[@]} -eq 0 ]; then
        log_skip "All ${#APT_PACKAGES[@]} base APT packages are already installed"
    else
        log_info "Installing ${#MISSING_APT[@]} missing APT package(s)..."
        sudo apt-get update -qq
        sudo DEBIAN_FRONTEND=noninteractive apt-get install --fix-broken -y -o Dpkg::Options::="--force-overwrite" "${MISSING_APT[@]}"
        log_ok "Installed missing APT package(s)"
    fi

    # Ensure latest Hyprland version (upgrade if a lower distribution release like 0.53 is installed)
    if dpkg-query -W -f='${Status}' hyprland 2>/dev/null | grep -q "ok installed"; then
        CURRENT_HYPR_VER="$(dpkg-query -W -f='${Version}' hyprland 2>/dev/null || true)"
        CANDIDATE_HYPR_VER="$(apt-cache policy hyprland 2>/dev/null | awk '/Candidate:/ {print $2}')"
        if [ -n "$CANDIDATE_HYPR_VER" ] && [ "$CURRENT_HYPR_VER" != "$CANDIDATE_HYPR_VER" ]; then
            log_info "Upgrading Hyprland from $CURRENT_HYPR_VER to latest PPA version ($CANDIDATE_HYPR_VER)..."
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y hyprland "$HYPR_GUI_HELPER"
            log_ok "Upgraded Hyprland to latest ($CANDIDATE_HYPR_VER)"
        fi
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

    # Ensure Ghostty terminal emulator (APT on Ubuntu 26+, Snap fallback on Ubuntu 24 and earlier)
    if command -v ghostty >/dev/null 2>&1; then
        log_skip "Ghostty terminal is already installed"
    elif apt-cache show ghostty >/dev/null 2>&1; then
        log_info "Installing Ghostty via APT..."
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ghostty && log_ok "Installed Ghostty via APT"
    elif command -v snap >/dev/null 2>&1; then
        log_info "Installing Ghostty via Snap (not available in this Ubuntu release's APT repositories)..."
        sudo snap install ghostty --classic && log_ok "Installed Ghostty via Snap" || log_warn "Failed to install Ghostty via Snap"
    else
        log_warn "Ghostty terminal could not be installed (not found in APT and Snap is unavailable)"
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
        if [ "$tool" = "ghostty" ] && [ -x "/usr/bin/ghostty" ]; then
            TOOL_PATH="/usr/bin/ghostty"
        else
            TOOL_PATH="$(command -v "$tool" 2>/dev/null || true)"
        fi
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
setup_caelestia_shell_ubuntu() {
    step_header "Verifying Caelestia Shell (Desktop UI) & Dependencies"

    if command -v caelestia-shell >/dev/null 2>&1 && command -v qs >/dev/null 2>&1 && command -v caelestia >/dev/null 2>&1; then
        log_skip "Caelestia Shell and its core components are already installed"
        return
    fi

    log_info "Installing build dependencies via APT..."
    local CAEL_DEPS=(
        libcli11-dev
        libxkbcommon-dev libx11-xcb-dev
        qt6-shadertools-dev
        pipx
        python3-build python3-installer python3-hatchling python3-hatch-vcs
        cmake ninja-build golang
        qt6-base-dev qt6-declarative-dev qt6-multimedia-dev qt6-wayland-dev qt6-wayland
        wayland-protocols libwayland-dev libpipewire-0.3-dev libpulse-dev libpam0g-dev
        libfftw3-dev libasound2-dev libiniparser-dev libtool automake autoconf
        libsensors-dev libddcutil-dev libqalculate-dev libaubio-dev libnm-dev
    )
    sudo apt-get install -y "${CAEL_DEPS[@]}"

    local SRC_DIR="$HOME/src"
    mkdir -p "$SRC_DIR"

    # Build and install cava (shared library)
    if [ ! -f "/usr/local/lib/libcava.so" ] && [ ! -f "/usr/lib/libcava.so" ]; then
        log_info "Building libcava from source..."
        if [ -d "$SRC_DIR/cava" ]; then rm -rf "$SRC_DIR/cava"; fi
        git clone https://github.com/LukashonakV/cava.git "$SRC_DIR/cava" >/dev/null 2>&1
        (
            cd "$SRC_DIR/cava"
            ./autogen.sh >/dev/null 2>&1
            ./configure --prefix=/usr/local >/dev/null 2>&1
            make -j$(nproc) >/dev/null 2>&1
            sudo make install >/dev/null 2>&1
        )
        log_ok "Installed libcava"
    else
        log_skip "libcava already installed"
    fi

    # Build and install caelestia-cli
    if ! command -v caelestia >/dev/null 2>&1; then
        log_info "Building caelestia-cli..."
        if [ -d "$SRC_DIR/caelestia-cli" ]; then rm -rf "$SRC_DIR/caelestia-cli"; fi
        git clone https://github.com/caelestia-dots/cli.git "$SRC_DIR/caelestia-cli" >/dev/null 2>&1
        (
            cd "$SRC_DIR/caelestia-cli"
            # python3 -m build --wheel >/dev/null 2>&1
            pipx install . --force
        )
        log_ok "Installed caelestia-cli"
    else
        log_skip "caelestia-cli already installed"
    fi

    # Build and install m3shapes
    if [ ! -d "/usr/local/lib/qt6/qml/M3Shapes" ] && [ ! -d "/usr/lib/qt6/qml/M3Shapes" ] && [ ! -d "/usr/lib/x86_64-linux-gnu/qt6/qml/M3Shapes" ]; then
        log_info "Building qt6-m3shapes..."
        if [ -d "$SRC_DIR/m3shapes" ]; then rm -rf "$SRC_DIR/m3shapes"; fi
        git clone https://github.com/soramanew/m3shapes.git "$SRC_DIR/m3shapes" >/dev/null 2>&1
        (
            cd "$SRC_DIR/m3shapes"
            cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local >/dev/null 2>&1
            cmake --build build >/dev/null 2>&1
            sudo cmake --install build >/dev/null 2>&1
        )
        log_ok "Installed qt6-m3shapes"
    else
        log_skip "qt6-m3shapes already installed"
    fi

    # Build and install quickshell
    if ! command -v qs >/dev/null 2>&1; then
        log_info "Building quickshell-git..."
        if [ -d "$SRC_DIR/quickshell" ]; then rm -rf "$SRC_DIR/quickshell"; fi
        git clone https://git.outfoxxed.me/quickshell/quickshell.git "$SRC_DIR/quickshell" >/dev/null 2>&1
        (
            cd "$SRC_DIR/quickshell"
            cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DQS_USE_X11=OFF >/dev/null 2>&1
            cmake --build build >/dev/null 2>&1
            sudo cmake --install build >/dev/null 2>&1
        )
        log_ok "Installed quickshell"
    else
        log_skip "quickshell already installed"
    fi

    # Build and install caelestia-shell
    if ! command -v caelestia-shell >/dev/null 2>&1; then
        log_info "Building caelestia-shell..."
        local CAEL_CONF="$HOME/.config/quickshell/caelestia"
        if [ -d "$CAEL_CONF" ]; then rm -rf "$CAEL_CONF"; fi
        mkdir -p "$HOME/.config/quickshell"
        git clone https://github.com/caelestia-dots/shell.git "$CAEL_CONF" >/dev/null 2>&1
        (
            cd "$CAEL_CONF"
            # Get qt6 qml path dynamically for install
            local QML_DIR=$(qmake6 -query QT_INSTALL_QML 2>/dev/null || echo "/usr/lib/x86_64-linux-gnu/qt6/qml")
            cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DINSTALL_QSCONFDIR="$CAEL_CONF" -DINSTALL_QMLDIR="$QML_DIR" >/dev/null 2>&1
            cmake --build build >/dev/null 2>&1
            sudo cmake --install build >/dev/null 2>&1
            
            # create wrapper
            echo '#!/bin/bash' > caelestia-shell
            echo 'CAELESTIA_LIB_DIR=/usr/local/lib /usr/local/bin/qs -p '"$CAEL_CONF"' "$@"' >> caelestia-shell
            chmod +x caelestia-shell
            sudo cp caelestia-shell /usr/local/bin/
            
            sudo chown -R $USER:$USER "$CAEL_CONF"
        )
        log_ok "Installed caelestia-shell"
    else
        log_skip "caelestia-shell already installed"
    fi
    
    sudo ldconfig 2>/dev/null || true
}
