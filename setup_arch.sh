#!/usr/bin/env bash
# ==============================================================================
# setup_arch.sh - Arch Linux Setup Wrapper
# Delegates to the centralized setup.sh with --os arch
# ==============================================================================

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$DOTFILES_DIR/setup.sh" --os arch "$@"
