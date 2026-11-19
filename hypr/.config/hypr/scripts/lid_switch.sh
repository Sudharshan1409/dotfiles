#!/usr/bin/env bash
# =============================================================================
# Smart Laptop Clamshell / Lid-Switch Handler for Hyprland (Lua mode)
# - Docked to external monitor(s): disables internal laptop panel on lid close,
#   restores saved multi-monitor layout on lid open.
# - Undocked (laptop-only): locks screen via Caelestia before system suspend.
# =============================================================================

export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

ACTION="${1:-}"
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/hypr_clamshell_panel"

INTERNAL="$(hyprctl monitors all -j 2>/dev/null | jq -r '.[] | select(.name | test("^(eDP|LVDS|DSI)-")) | .name' | head -n 1)"
[ -z "$INTERNAL" ] && INTERNAL="eDP-1"

case "$ACTION" in
    close)
        EXT_MON="$(hyprctl monitors -j 2>/dev/null | jq -r --arg int "$INTERNAL" '.[] | select(.name != $int and (.disabled | not)) | .name' | head -n 1)"
        if [ -n "$EXT_MON" ]; then
            printf '%s\n' "$INTERNAL" > "$STATE_FILE"
            hyprctl repl "hl.monitor({ output = '$INTERNAL', disabled = true })" >/dev/null 2>&1 || true

            # Move any workspaces stranded on the disabled laptop panel to the primary external monitor
            for ws in $(hyprctl workspaces -j 2>/dev/null | jq -r --arg int "$INTERNAL" '.[] | select(.monitor == $int and .id > 0) | .id'); do
                hyprctl repl "hl.dispatch(hl.dsp.workspace.move({ workspace = '$ws', monitor = '$EXT_MON' }))" >/dev/null 2>&1 || true
            done

            caelestia shell toaster info "Clamshell mode active" "Internal display ($INTERNAL) disabled — docked to $EXT_MON" "laptop_chromebook" >/dev/null 2>&1 || true
        else
            rm -f "$STATE_FILE"
            caelestia shell lock lock >/dev/null 2>&1 || true
        fi
        ;;

    open)
        WAS_CLAMSHELL=false
        [ -f "$STATE_FILE" ] && WAS_CLAMSHELL=true
        rm -f "$STATE_FILE"

        # Reload Hyprland config so monitors_gen.lua restores exact mode/position/scale & workspace rules
        hyprctl reload >/dev/null 2>&1 || true
        sleep 0.3

        # Fallback if internal panel wasn't explicitly listed in monitors_gen.lua
        if hyprctl monitors all -j 2>/dev/null | jq -e --arg int "$INTERNAL" '.[] | select(.name == $int and .disabled == true)' >/dev/null 2>&1; then
            hyprctl repl "hl.monitor({ output = '$INTERNAL', mode = 'preferred', position = 'auto', scale = '1' })" >/dev/null 2>&1 || true
        fi

        if [ -x "$HOME/.config/hypr/scripts/monitor_profile_manager.sh" ]; then
            "$HOME/.config/hypr/scripts/monitor_profile_manager.sh" auto >/dev/null 2>&1 &
        fi

        if [ "$WAS_CLAMSHELL" = true ]; then
            caelestia shell toaster info "Laptop display restored" "Internal panel ($INTERNAL) re-enabled" "desktop_windows" >/dev/null 2>&1 || true
        fi
        ;;
esac
