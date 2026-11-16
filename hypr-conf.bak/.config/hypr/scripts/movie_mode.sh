#!/bin/bash

# Movie Mode (Solo Display)
# Powers off all displays except the selected one via DPMS and stops hypridle.
# Uses Rofi for the interface and hyprctl for display control.

ROFI_THEME="$HOME/.config/rofi/monitor-profile.rasi"

# Function to get active monitors
get_monitors() {
    hyprctl monitors -j | jq -r '.[] | "\(.name) [\(.description)]"'
}

# Function to stop hypridle if it's running
stop_idle() {
    if pgrep -x "hypridle" > /dev/null; then
        killall hypridle
        return 0 # Was running
    fi
    return 1 # Was not running
}

# Function to restore monitors and restart hypridle
restore_all() {
    # Turn all DPMS back on
    local all_monitors=$(hyprctl monitors -j | jq -r '.[].name')
    for mon in $all_monitors; do
        hyprctl dispatch dpms on "$mon"
    done
    
    # Restart hypridle
    if ! pgrep -x "hypridle" > /dev/null; then
        hypridle &
    fi
    
    notify-send -a "Movie Mode" -i "video-display" "🎬 Restore Mode" "All displays powered on and screen lock re-enabled."
}

# Function to solo a monitor
solo_monitor() {
    local target_name="$1"
    # Get all monitors (including inactive ones to be thorough)
    local all_monitors=$(hyprctl monitors all -j | jq -r '.[].name')
    
    # Stop hypridle for the movie
    stop_idle
    
    # Build a batch command for Hyprland to execute all at once
    # 1. Focus the target monitor first
    # 2. Ensure target is ON
    # 3. Turn others OFF
    local batch_cmd="dispatch focusmonitor $target_name; dispatch dpms on $target_name"
    
    for mon in $all_monitors; do
        if [ "$mon" != "$target_name" ]; then
            batch_cmd="$batch_cmd; dispatch dpms off $mon"
        fi
    done
    
    # Execute everything in one go to prevent flickering/sequential lag
    hyprctl --batch "$batch_cmd"
    
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
