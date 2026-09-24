#!/usr/bin/env bash
# ==============================================================================
# setup.sh - Centralized system setup & dotfiles provisioning for Linux
# ==============================================================================
# Usage:
#   ./setup.sh               Auto-detects distribution and executes setup
#   ./setup.sh --os ubuntu   Forces Ubuntu / Debian setup
#   ./setup.sh --os arch     Forces Arch Linux setup
#   ./setup.sh --check       Runs diagnostic dotfiles-doctor
#   ./setup.sh --help        Displays usage information
# ==============================================================================

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.local/bin:/home/linuxbrew/.linuxbrew/bin:/snap/bin:$PATH"

show_help() {
    cat << EOF
Dotfiles Setup Script - Unified Provisioning for Linux

Usage:
  ./setup.sh [OPTIONS]

Options:
  -o, --os <type>       Specify OS target explicitly: 'ubuntu' or 'arch'
  -s, --screen <res>    Specify GRUB theme resolution: 1080p, 2k, 4k (default: 1080p)
  -c, --check, doctor   Run configuration health check without making changes
  -h, --help            Show this help message and exit

Examples:
  ./setup.sh                     # Auto-detect OS and run complete setup
  ./setup.sh --os ubuntu         # Run Ubuntu setup explicitly
  ./setup.sh --os arch           # Run Arch Linux setup explicitly
  ./setup.sh --screen 2k         # Run setup with 2K GRUB resolution
  ./setup.sh --check             # Health check dotfiles & system dependencies
EOF
    exit 0
}

# Parse command line options
OS_OVERRIDE=""
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_help
            ;;
        -c|--check|doctor)
            exec "$DOTFILES_DIR/scripts/dotfiles-doctor.sh"
            ;;
        -o|--os)
            shift
            OS_OVERRIDE="${1:-}"
            ;;
        --os=*)
            OS_OVERRIDE="${1#*=}"
            ;;
        -s|--screen)
            shift
            export GRUB_THEME_SCREEN="${1:-1080p}"
            ;;
        --screen=*)
            export GRUB_THEME_SCREEN="${1#*=}"
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Run './setup.sh --help' for available options." >&2
            exit 1
            ;;
    esac
    shift
done

# Detect operating system if not overridden
detect_os() {
    if [ -n "$OS_OVERRIDE" ]; then
        echo "$OS_OVERRIDE"
        return
    fi

    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        case "${ID:-}" in
            ubuntu|debian|pop|linuxmint|elementary|zorin)
                echo "ubuntu"
                ;;
            arch|endeavouros|manjaro|garuda|artix)
                echo "arch"
                ;;
            *)
                case "${ID_LIKE:-}" in
                    *ubuntu*|*debian*)
                        echo "ubuntu"
                        ;;
                    *arch*)
                        echo "arch"
                        ;;
                    *)
                        echo "unknown"
                        ;;
                esac
                ;;
        esac
    else
        echo "unknown"
    fi
}

OS_TYPE="$(detect_os)"

# Source setup modules
# shellcheck disable=SC1091
source "$DOTFILES_DIR/scripts/setup/lib.sh"
# shellcheck disable=SC1091
source "$DOTFILES_DIR/scripts/setup/common.sh"

case "$OS_TYPE" in
    ubuntu|debian)
        # shellcheck disable=SC1091
        source "$DOTFILES_DIR/scripts/setup/ubuntu.sh"
        TOTAL_STEPS=23
        OS_DISPLAY_NAME="Ubuntu"
        ;;
    arch)
        # shellcheck disable=SC1091
        source "$DOTFILES_DIR/scripts/setup/arch.sh"
        TOTAL_STEPS=19
        OS_DISPLAY_NAME="Arch Linux"
        ;;
    *)
        log_err "Unsupported or undetected operating system."
        echo "Please specify your distribution manually using: ./setup.sh --os <ubuntu|arch>"
        exit 1
        ;;
esac

echo -e "${BOLD}==================================================================${RESET}"
echo -e "${BOLD}  Starting Dotfiles & System Setup (${OS_DISPLAY_NAME})${RESET}"
echo -e "${BOLD}==================================================================${RESET}"

# 1. Elevate and keep alive sudo
init_sudo

# 2. Run Distribution-Specific Package Management
if [ "$OS_TYPE" = "ubuntu" ] || [ "$OS_TYPE" = "debian" ]; then
    setup_ubuntu_packages
    setup_ubuntu_homebrew
elif [ "$OS_TYPE" = "arch" ]; then
    setup_arch_packages
fi

# 3. Run Common System & Dotfile Configurations
setup_common_stow
setup_common_git
setup_common_zsh_plugins
setup_common_python_venv
setup_common_neovim
setup_common_tmux
setup_common_bat
setup_common_yazi
setup_common_picture_dirs
setup_common_permissions
setup_common_services
setup_common_rfkill
setup_common_shell
setup_common_brightness
setup_common_ethernet

# 4. Run Hardware & Bootloader Setup
if [ "$OS_TYPE" = "ubuntu" ] || [ "$OS_TYPE" = "debian" ]; then
    setup_ubuntu_displaylink
elif [ "$OS_TYPE" = "arch" ]; then
    setup_arch_displaylink
fi

setup_common_grub_theme

# 5. Final Summary
print_summary "$OS_DISPLAY_NAME"
