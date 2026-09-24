#!/usr/bin/env bash
# ==============================================================================
# setup_ubuntu.sh - Ubuntu Setup Wrapper
# Delegates to the centralized setup.sh with --os ubuntu
# ==============================================================================

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$DOTFILES_DIR/setup.sh" --os ubuntu "$@"
