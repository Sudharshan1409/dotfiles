#!/usr/bin/env bash
# ==============================================================================
# scripts/setup/lib.sh - Shared utilities, logging, and helpers for setup scripts
# ==============================================================================

BOLD="\033[1m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
CYAN="\033[1;36m"
BLUE="\033[1;34m"
DIM="\033[2m"
RESET="\033[0m"

TOTAL_STEPS=0
CURRENT_STEP=0

ACTIONS_DONE=0
ACTIONS_SKIPPED=0
ACTIONS_FAILED=0

step_header() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    if [ "$TOTAL_STEPS" -gt 0 ]; then
        echo -e "\n${BOLD}${BLUE}[${CURRENT_STEP}/${TOTAL_STEPS}] $1${RESET}"
    else
        echo -e "\n${BOLD}${BLUE}[${CURRENT_STEP}] $1${RESET}"
    fi
}

log_ok() {
    echo -e "  ${GREEN}✓ [DONE]${RESET} $1"
    ACTIONS_DONE=$((ACTIONS_DONE + 1))
}

log_skip() {
    echo -e "  ${CYAN}➜ [SKIPPED]${RESET} $1 ${DIM}(already configured)${RESET}"
    ACTIONS_SKIPPED=$((ACTIONS_SKIPPED + 1))
}

log_info() {
    echo -e "  ${BLUE}ℹ [INFO]${RESET} $1"
}

log_warn() {
    echo -e "  ${YELLOW}⚠ [WARN]${RESET} $1"
}

log_err() {
    echo -e "  ${RED}✗ [ERROR]${RESET} $1"
    ACTIONS_FAILED=$((ACTIONS_FAILED + 1))
}

init_sudo() {
    step_header "Verifying sudo privileges"
    if sudo -n true 2>/dev/null; then
        log_skip "Sudo authentication already active"
    else
        log_info "Requesting sudo privileges for system configuration..."
        sudo -v
        log_ok "Sudo credentials acquired"
    fi
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    SUDO_PID=$!
    trap 'cleanup_setup' EXIT
}

cleanup_setup() {
    if [ -n "${SUDO_PID:-}" ]; then
        kill "$SUDO_PID" 2>/dev/null || true
    fi
    if [ -n "${CLEANUP_TMP_DIRS:-}" ]; then
        for tmp_d in $CLEANUP_TMP_DIRS; do
            rm -rf "$tmp_d" 2>/dev/null || true
        done
    fi
}

print_summary() {
    local os_title="$1"
    echo -e "\n${BOLD}==================================================================${RESET}"
    echo -e "${BOLD}${GREEN}  Complete Setup for ${os_title} Finished Successfully!${RESET}"
    echo -e "${BOLD}==================================================================${RESET}"
    echo -e "  Summary of actions:"
    echo -e "    ${GREEN}✓ Newly Configured :${RESET} ${ACTIONS_DONE}"
    echo -e "    ${CYAN}➜ Already In Place :${RESET} ${ACTIONS_SKIPPED}"
    echo -e "    ${RED}✗ Warnings/Failures:${RESET} ${ACTIONS_FAILED}"
    echo -e "${BOLD}==================================================================${RESET}\n"
}
