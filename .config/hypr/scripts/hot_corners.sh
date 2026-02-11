#!/bin/bash

# =============================================================================
# Hot Corners - Trigger actions when mouse hits screen corners
# =============================================================================

# Configuration
CORNER_SIZE=15          
CHECK_INTERVAL=0.1      
LOG_FILE="$HOME/.config/hypr/.logs/hot_corners.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Lock file
LOCK_FILE="/run/user/$(id -u)/hot_corners.lock"

# Check if already running
if [ -f "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "Hot corners already running (PID: $PID)"
        exit 0
    fi
fi

echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"; exit 0' EXIT INT TERM

# Function to log
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log "Hot corners started"

# Function to get mouse position
get_mouse_pos() {
    hyprctl cursorpos 2>/dev/null | tr ',' ' '
}

# Function to get monitor dimensions
get_monitor_dimensions() {
    hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | "\(.x) \(.y) \(.width) \(.height)"' | head -1
}

# Function to check if mouse is in a corner
check_corners() {
    local mouse_x=$1
    local mouse_y=$2
    local mon_x=$3
    local mon_y=$4
    local mon_w=$5
    local mon_h=$6
    
    local left_edge=$((mon_x))
    local right_edge=$((mon_x + mon_w - 1))
    local top_edge=$((mon_y))
    local bottom_edge=$((mon_y + mon_h - 1))
    
    # Top-left
    if [ $mouse_x -le $((left_edge + CORNER_SIZE)) ] && [ $mouse_y -le $((top_edge + CORNER_SIZE)) ]; then
        echo "top-left"
        return
    fi
    
    # Top-right
    if [ $mouse_x -ge $((right_edge - CORNER_SIZE)) ] && [ $mouse_y -le $((top_edge + CORNER_SIZE)) ]; then
        echo "top-right"
        return
    fi
    
    # Bottom-left
    if [ $mouse_x -le $((left_edge + CORNER_SIZE)) ] && [ $mouse_y -ge $((bottom_edge - CORNER_SIZE)) ]; then
        echo "bottom-left"
        return
    fi
    
    # Bottom-right
    if [ $mouse_x -ge $((right_edge - CORNER_SIZE)) ] && [ $mouse_y -ge $((bottom_edge - CORNER_SIZE)) ]; then
        echo "bottom-right"
        return
    fi
    
    echo "none"
}

# Function to execute corner action
execute_action() {
    local corner="$1"
    local last_corner="$2"
    
    if [ "$corner" = "$last_corner" ]; then
        return
    fi
    
    log "Triggering action for corner: $corner"
    
    # Show visual notification BEFORE executing
    case "$corner" in
        "top-left")
            notify-send --app-name="Hot Corner" --icon="system-lock-screen" --urgency=low "🔒 Lock Screen" "Screen locking..." -t 1500 &
            sleep 0.3
            hyprlock &
            ;;
        "top-right")
            notify-send --app-name="Hot Corner" --icon="view-grid" --urgency=low "🔲 Workspace Overview" "Opening..." -t 1500 &
            sleep 0.3
            ~/.config/hypr/scripts/workspace_overview.sh &
            ;;
        "bottom-left")
            notify-send --app-name="Hot Corner" --icon="application-x-executable" --urgency=low "🚀 App Launcher" "Opening..." -t 1500 &
            sleep 0.3
            rofi -show drun -show-icons -display-drune 'Apps' -theme ~/.config/rofi/launcher-elegant.rasi &
            ;;
        "bottom-right")
            notify-send --app-name="Hot Corner" --icon="input-keyboard" --urgency=low "⌨️ Keybinding Help" "Opening..." -t 1500 &
            sleep 0.3
            ~/.config/hypr/scripts/keybinding_menu.sh &
            ;;
    esac
    
    # Cooldown
    sleep 2
}

# Main loop
last_corner="none"

while true; do
    read mouse_x mouse_y <<< $(get_mouse_pos)
    
    if [ -z "$mouse_x" ] || [ -z "$mouse_y" ]; then
        sleep $CHECK_INTERVAL
        continue
    fi
    
    read mon_x mon_y mon_w mon_h <<< $(get_monitor_dimensions)
    
    corner=$(check_corners $mouse_x $mouse_y $mon_x $mon_y $mon_w $mon_h)
    
    if [ "$corner" != "none" ]; then
        execute_action "$corner" "$last_corner"
        last_corner="$corner"
    else
        last_corner="none"
    fi
    
    sleep $CHECK_INTERVAL
done
