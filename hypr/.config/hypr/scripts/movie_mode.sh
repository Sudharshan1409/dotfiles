#!/bin/bash

# Movie Mode (Solo Display)
# Powers off all displays except the selected one via DPMS and enables Caelestia's idle inhibitor.
# Uses Rofi for the interface and hyprctl for display control.

ROFI_THEME="$HOME/.config/rofi/monitor-profile.rasi"
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

# Function to get active monitors
get_monitors() {
    hyprctl monitors -j | jq -r '.[] | "\(.name) [\(.description)]"'
}

# Function to restore monitors and disable idle inhibitor
restore_all() {
    # Turn all DPMS back on
    local all_monitors=$(hyprctl monitors -j | jq -r '.[].name')
    for mon in $all_monitors; do
        hyprctl repl "hl.dispatch(hl.dsp.dpms({state='on', monitor='$mon'}))"
    done

    # Restore normal Caelestia idle timeouts
    caelestia shell idleInhibitor disable >/dev/null 2>&1

    notify-send -a "Movie Mode" -i "video-display" "🎬 Restore Mode" "All displays powered on and normal idle lock restored."
}

# Function to solo a monitor
solo_monitor() {
    local target_name="$1"
    # Get all monitors (including inactive ones to be thorough)
    local all_monitors=$(hyprctl monitors all -j | jq -r '.[].name')

    # Enable Caelestia's native Wayland idle inhibitor for the movie
    caelestia shell idleInhibitor enable >/dev/null 2>&1
    
    # Build a batch command for Hyprland to execute all at once
    # 1. Focus the target monitor first
    # 2. Ensure target is ON
    # 3. Turn others OFF
    hyprctl repl "hl.dispatch(hl.dsp.focus({monitor='$target_name'}))" >/dev/null 2>&1
    hyprctl repl "hl.dispatch(hl.dsp.dpms({state='on', monitor='$target_name'}))" >/dev/null 2>&1
    for mon in $all_monitors; do
        if [ "$mon" != "$target_name" ]; then
            hyprctl repl "hl.dispatch(hl.dsp.dpms({state='off', monitor='$mon'}))" >/dev/null 2>&1
        fi
    done
    
    notify-send -a "Movie Mode" -i "video-display" "🎬 Movie Mode Active" "Solo display: $target_name\nScreen lock and other displays disabled."
}

# Show menu
show_menu() {
    local monitors=$(get_monitors)
    local menu_content="🔄 Restore All Displays\n---\n$monitors"
    
    local selected=$(echo -e "$menu_content" | rofi -dmenu -i -p "Movie Mode" -theme "$ROFI_THEME" -mesg "Select the Solo display for your movie (others will go to sleep)")
    
    [ -z "$selected" ] && exit 0
    
    if [[ "$selected" == "🔄 Restore All Displays" ]]; then
        restore_all
    elif [[ "$selected" == "---" ]]; then
        exit 0
    else
        # Extract the name (first word)
        local name=$(echo "$selected" | awk '{print $1}')
        solo_monitor "$name"
    fi
}

show_menu
