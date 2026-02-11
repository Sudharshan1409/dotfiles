#!/bin/bash

# =============================================================================
# Audio Device Switcher - Quick toggle between audio input/output devices
# =============================================================================

ROFI_THEME="$HOME/.config/rofi/audio-switcher.rasi"

# Function to get current default sink (output)
get_current_sink() {
    pactl info | grep "Default Sink:" | cut -d':' -f2 | xargs
}

# Function to get current default source (input/mic)
get_current_source() {
    pactl info | grep "Default Source:" | cut -d':' -f2 | xargs
}

# Function to list all sinks (outputs) - returns "name|description" format
list_sinks_raw() {
    pactl list sinks | awk '/Name:/{name=$2} /Description:/{desc=$2; for(i=3;i<=NF;i++) desc=desc" "$i; print name"|"desc}'
}

# Function to list all sources (inputs) - returns "name|description" format  
list_sources_raw() {
    pactl list sources | grep -v "monitor" | awk '/Name:/{name=$2} /Description:/{desc=$2; for(i=3;i<=NF;i++) desc=desc" "$i; print name"|"desc}'
}

# Function to show sink selection menu
show_sink_menu() {
    local current_sink=$(get_current_sink)
    local menu_items=""
    
    while IFS='|' read -r name desc; do
        if [ -n "$name" ] && [ -n "$desc" ]; then
            if [ "$name" = "$current_sink" ]; then
                menu_items="${menu_items}🔊 $desc\n"
            else
                menu_items="${menu_items}  $desc\n"
            fi
        fi
    done <<< "$(list_sinks_raw)"
    
    echo -e "$menu_items" | head -20
}

# Function to show source selection menu
show_source_menu() {
    local current_source=$(get_current_source)
    local menu_items=""
    
    while IFS='|' read -r name desc; do
        if [ -n "$name" ] && [ -n "$desc" ]; then
            if [ "$name" = "$current_source" ]; then
                menu_items="${menu_items}🎤 $desc\n"
            else
                menu_items="${menu_items}  $desc\n"
            fi
        fi
    done <<< "$(list_sources_raw)"
    
    echo -e "$menu_items" | head -20
}

# Function to set default sink
set_sink_by_desc() {
    local target_desc="$1"
    # Remove emoji and leading spaces
    target_desc=$(echo "$target_desc" | sed 's/^[🔊 ]*//')
    
    # Find and set the sink
    while IFS='|' read -r name desc; do
        if [ "$desc" = "$target_desc" ]; then
            pactl set-default-sink "$name"
            if [ $? -eq 0 ]; then
                notify-send "Audio Switcher" "Output: $desc" -i audio-speakers -t 2000
                return 0
            fi
        fi
    done <<< "$(list_sinks_raw)"
    
    return 1
}

# Function to set default source
set_source_by_desc() {
    local target_desc="$1"
    # Remove emoji and leading spaces
    target_desc=$(echo "$target_desc" | sed 's/^[🎤 ]*//')
    
    # Find and set the source
    while IFS='|' read -r name desc; do
        if [ "$desc" = "$target_desc" ]; then
            pactl set-default-source "$name"
            if [ $? -eq 0 ]; then
                notify-send "Audio Switcher" "Input: $desc" -i audio-input-microphone -t 2000
                return 0
            fi
        fi
    done <<< "$(list_sources_raw)"
    
    return 1
}

# Function to toggle mute
toggle_mute() {
    local type="$1"
    if [ "$type" = "sink" ]; then
        pactl set-sink-mute @DEFAULT_SINK@ toggle
        notify-send "Audio Switcher" "Output mute toggled" -i audio-volume-muted -t 1500
    else
        pactl set-source-mute @DEFAULT_SOURCE@ toggle
        notify-send "Audio Switcher" "Input mute toggled" -i microphone-sensitivity-muted -t 1500
    fi
}

# Main menu
while true; do
    CURRENT_SINK=$(get_current_sink)
    CURRENT_SOURCE=$(get_current_source)
    
    # Get current descriptions
    SINK_DESC=$(pactl list sinks | grep -A1 "Name: $CURRENT_SINK" | grep "Description:" | cut -d':' -f2 | xargs)
    SOURCE_DESC=$(pactl list sources | grep -A1 "Name: $CURRENT_SOURCE" | grep "Description:" | cut -d':' -f2 | xargs)
    
    # Build menu - only actionable items
    MENU="🔄 Change Output Device
🎙️  Change Input Device
🔇 Toggle Output Mute
🤐 Toggle Input Mute
📊 Open Volume Control
❌ Close"
    
    SELECTED=$(echo -e "$MENU" | rofi -dmenu \
        -p "Audio" \
        -theme "$ROFI_THEME" \
        -mesg "🔊 $SINK_DESC" \
        -i)
    
    # Check if cancelled
    if [ -z "$SELECTED" ] || [ "$SELECTED" = "❌ Close" ]; then
        exit 0
    fi
    
    case "$SELECTED" in
        "🔄 Change Output Device")
            DEVICE=$(show_sink_menu | rofi -dmenu \
                -p "Output" \
                -theme "$ROFI_THEME" \
                -mesg "Select output device" \
                -i)
            
            if [ -n "$DEVICE" ] && [ "$DEVICE" != "" ]; then
                set_sink_by_desc "$DEVICE"
                exit 0  # Close menu after switching
            fi
            ;;
            
        "🎙️  Change Input Device")
            DEVICE=$(show_source_menu | rofi -dmenu \
                -p "Input" \
                -theme "$ROFI_THEME" \
                -mesg "Select input device" \
                -i)
            
            if [ -n "$DEVICE" ] && [ "$DEVICE" != "" ]; then
                set_source_by_desc "$DEVICE"
                exit 0  # Close menu after switching
            fi
            ;;
            
        "🔇 Toggle Output Mute")
            toggle_mute "sink"
            exit 0
            ;;
            
        "🤐 Toggle Input Mute")
            toggle_mute "source"
            exit 0
            ;;
            
        "📊 Open Volume Control")
            pavucontrol &
            exit 0
            ;;
    esac
done
