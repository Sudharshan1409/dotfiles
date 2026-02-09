#!/bin/bash

# Monitor Profile Manager
# Auto-detects monitor configurations and allows quick profile switching
# Caches profiles by MAC address + monitor port + monitor description

# Source user environment if available
[ -f "$HOME/.config/environment.d/envvars.conf" ] && source "$HOME/.config/environment.d/envvars.conf" 2>/dev/null
[ -f "$HOME/.pam_environment" ] && source "$HOME/.pam_environment" 2>/dev/null

# If running under Hyprland, try to get environment from it
if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    # Get environment from Hyprland's socket if available
    if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
        DBUS=$(find /run/user/$(id -u) -name "bus" -type s 2>/dev/null | head -1)
        [ -n "$DBUS" ] && export DBUS_SESSION_BUS_ADDRESS="unix:path=$DBUS"
    fi
fi

# Fallback for DISPLAY
if [ -z "$DISPLAY" ]; then
    [ -S "/tmp/.X11-unix/X0" ] && export DISPLAY=:0
    [ -S "/tmp/.X11-unix/X1" ] && export DISPLAY=:1
fi

# Fallback for DBUS
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    [ -S "/run/user/$(id -u)/bus" ] && export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
fi

CONFIG_DIR="$HOME/.config/hypr/monitors"
CACHE_DIR="$HOME/.config/hypr/.cache"
LOGS_DIR="$HOME/.config/hypr/.logs"
CACHE_FILE="$CACHE_DIR/monitor_profile_cache.json"
ROFI_THEME="$HOME/.config/rofi/monitor-profile.rasi"
LOG_FILE="$LOGS_DIR/monitor_profile.log"

# Ensure directories exist
mkdir -p "$CONFIG_DIR" "$CACHE_DIR" "$LOGS_DIR"

# Function to get current network MAC address (for location fingerprinting)
get_mac_fingerprint() {
    # Get active network interface MAC (prioritize ethernet, then wifi)
    local mac=$(ip link show | grep -E "(ether|link/ether)" | awk '{print $2}' | head -1 | tr -d ':')
    if [ -z "$mac" ]; then
        mac="nomac"
    fi
    echo "$mac"
}

# Function to get current monitor fingerprint
# Format: MAC|port1:monitor_desc1|port2:monitor_desc2|...
get_monitor_fingerprint() {
    local mac=$(get_mac_fingerprint)
    local monitors=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | "\(.name):\(.description | gsub(" "; "_"))"' | sort | tr '\n' '|')
    
    if [ -z "$monitors" ]; then
        echo "${mac}|nomonitor" 
    else
        # Remove trailing |
        monitors="${monitors%|}"
        echo "${mac}|${monitors}"
    fi
}

# Function to normalize fingerprint (for comparison)
normalize_fingerprint() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9|:_-]//g'
}

# Function to get all available profiles
get_profiles() {
    find "$CONFIG_DIR" -name "*.conf" -type f ! -name "template.conf" | while read -r f; do
        basename "$f" .conf
    done | sort
}

# Function to read cache and find matching profile
get_cached_profile() {
    local current_fp=$(get_monitor_fingerprint)
    local normalized_current=$(normalize_fingerprint "$current_fp")
    
    if [ ! -f "$CACHE_FILE" ]; then
        echo ""
        return
    fi
    
    # Check for exact match or partial match (same MAC, similar monitors)
    local profile=$(jq -r --arg fp "$normalized_current" '
        to_entries | 
        map(select(.key == $fp)) | 
        first | .value // empty
    ' "$CACHE_FILE" 2>/dev/null)
    
    if [ -n "$profile" ] && [ "$profile" != "null" ]; then
        echo "$profile"
        return
    fi
    
    # Try partial match - same MAC, subset of monitors
    local mac_part=$(echo "$normalized_current" | cut -d'|' -f1)
    profile=$(jq -r --arg mac "$mac_part" '
        to_entries | 
        map(select(.key | startswith($mac))) |
        first | .value // empty
    ' "$CACHE_FILE" 2>/dev/null)
    
    echo "$profile"
}

# Function to save profile to cache
save_to_cache() {
    local fingerprint=$(get_monitor_fingerprint)
    local normalized_fp=$(normalize_fingerprint "$fingerprint")
    local profile_name="$1"
    
    # Create cache file if it doesn't exist
    if [ ! -f "$CACHE_FILE" ]; then
        echo "{}" > "$CACHE_FILE"
    fi
    
    # Add/update entry
    jq --arg fp "$normalized_fp" --arg profile "$profile_name" \
        '.[$fp] = $profile' "$CACHE_FILE" > "$CACHE_FILE.tmp" && \
        mv "$CACHE_FILE.tmp" "$CACHE_FILE"
    
    echo "$(date): Cached profile '$profile_name' for fingerprint: $fingerprint" >> "$LOG_FILE"
}

# Function to show rofi menu for profile selection
show_profile_menu() {
    local current_fp=$(get_monitor_fingerprint)
    local profiles=$(get_profiles)
    
    # Build menu items
    local menu_items=""
    while IFS= read -r profile; do
        [ -z "$profile" ] && continue
        # Get profile description if exists
        local desc=$(grep "^# Description:" "$CONFIG_DIR/$profile.conf" 2>/dev/null | sed 's/^# Description: //')
        if [ -n "$desc" ]; then
            menu_items="${menu_items}${profile} - ${desc}\n"
        else
            menu_items="${menu_items}${profile}\n"
        fi
    done <<< "$profiles"
    
    # Add special options
    menu_items="${menu_items}───\n"
    menu_items="${menu_items}➕ Create New Profile\n"
    menu_items="${menu_items}📝 Edit Existing Profile\n"
    menu_items="${menu_items}🗑️  Clear Cache"
    
    # Show rofi
    local selected=$(echo -e "$menu_items" | rofi -dmenu \
        -p "Monitor Profile" \
        -theme "$ROFI_THEME" \
        -mesg "Current: ${current_fp:0:50}..." \
        -i)
    
    echo "$selected"
}

# Function to generate workspace assignments for all monitors
# Creates round-robin distribution for workspaces 1-9
generate_workspace_assignments() {
    local monitors=$(hyprctl monitors -j 2>/dev/null | jq -r '.[].name' | sort)
    local monitor_count=$(echo "$monitors" | wc -l)
    local workspace_assignments=""
    local monitor_idx=0
    
    # Generate assignments for workspaces 1-9
    for ws in {1..9}; do
        # Get monitor for this workspace (round-robin)
        local monitor=$(echo "$monitors" | sed -n "$(( (ws - 1) % monitor_count + 1 ))p")
        workspace_assignments="${workspace_assignments}workspace=${ws},monitor:${monitor}
"
    done
    
    echo "$workspace_assignments"
}

# Function to create new profile
create_new_profile() {
    # Get profile name from user
    local name=$(rofi -dmenu \
        -p "Profile Name" \
        -theme "$ROFI_THEME" \
        -mesg "Enter a name for this monitor configuration" \
        -i)
    
    [ -z "$name" ] && return
    
    # Sanitize name
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd 'a-z0-9_-')
    
    if [ -f "$CONFIG_DIR/$name.conf" ]; then
        notify-send -u critical "Profile Exists" "A profile named '$name' already exists!"
        return
    fi
    
    # Get current monitor configuration
    local monitor_config=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | 
        "monitor = \(.name), \(.width)x\(.height)@\(.refreshRate | floor), \(.x)x\(.y), \(.scale)"')
    
    # Generate workspace assignments for 9 workspaces
    local workspace_config=$(generate_workspace_assignments)
    
    # Create profile
    cat > "$CONFIG_DIR/$name.conf" << EOF
# Description: Custom profile created on $(date)
# Fingerprint: $(get_monitor_fingerprint)

# --- Monitor Configuration ---
# Auto-generated from current setup
$monitor_config

# --- Workspace Assignments ---
# Round-robin distribution for 9 workspaces
$workspace_config

# --- Additional Rules ---
# Add any window rules or special configurations here

EOF
    
    # Apply the profile immediately (apply_profile will send the notification)
    apply_profile "$name"
}

# Function to find available editor
find_editor() {
    # Check $EDITOR first
    if [ -n "$EDITOR" ] && command -v "$EDITOR" > /dev/null 2>&1; then
        echo "$EDITOR"
        return
    fi
    
    # Try common terminal editors
    for editor in nvim vim vi nano micro; do
        if command -v "$editor" > /dev/null 2>&1; then
            echo "$editor"
            return
        fi
    done
    
    # Try GUI editors as fallback
    for editor in gedit mousepad kate xed; do
        if command -v "$editor" > /dev/null 2>&1; then
            echo "$editor"
            return
        fi
    done
    
    echo ""
}

# Function to edit existing profile
edit_profile() {
    local profiles=$(get_profiles)
    
    local selected=$(echo "$profiles" | rofi -dmenu \
        -p "Edit Profile" \
        -theme "$ROFI_THEME" \
        -mesg "Select a profile to edit" \
        -i)
    
    [ -z "$selected" ] && return
    
    local editor=$(find_editor)
    local profile_path="$CONFIG_DIR/$selected.conf"
    
    if [ -z "$editor" ]; then
        notify-send -u critical "Error" "No text editor found! Please install vim, nano, or set \$EDITOR."
        return
    fi
    
    # Check if it's a GUI editor
    case "$editor" in
        gedit|mousepad|kate|xed)
            # GUI editors - launch directly
            "$editor" "$profile_path" &
            ;;
        *)
            # Terminal editors - launch with ghostty
            ghostty -e "$editor" "$profile_path" &
            ;;
    esac
    
    notify-send "Editor Opened" "Editing profile: $selected.conf"
}

# Function to clear cache
clear_cache() {
    local confirm=$(rofi -dmenu -p "Confirm" -theme "$ROFI_THEME" \
        -mesg "Are you sure you want to clear the monitor profile cache?" <<< $'Yes\nNo')
    
    if [ "$confirm" = "Yes" ]; then
        rm -f "$CACHE_FILE"
        notify-send "Cache Cleared" "Monitor profile cache has been cleared."
    fi
}

# Function to apply a profile
apply_profile() {
    local profile_name="$1"
    local skip_cache="${2:-false}"
    
    if [ ! -f "$CONFIG_DIR/$profile_name.conf" ]; then
        notify-send -u critical "Error" "Profile '$profile_name' not found!"
        return 1
    fi
    
    # Generate the config file
    echo "source=$CONFIG_DIR/$profile_name.conf" > "$HOME/.config/hypr/monitors.gen.conf"
    
    # Apply the configuration
    hyprctl reload
    
    # Move existing windows to appropriate monitors if needed
    # This is done automatically by Hyprland's workspace rules
    
    # Cache this profile for this fingerprint
    if [ "$skip_cache" != "true" ]; then
        save_to_cache "$profile_name"
    fi
    
    # Notify user
    # Debug: log environment variables
    echo "$(date): DEBUG - DISPLAY=$DISPLAY, DBUS=$DBUS_SESSION_BUS_ADDRESS" >> "$LOG_FILE"
    
    if notify-send -i "video-display" "Monitor Profile Applied" "Loaded profile: $profile_name" 2>>"$LOG_FILE"; then
        echo "$(date): Notification sent successfully" >> "$LOG_FILE"
    else
        echo "$(date): Notification failed with exit code $?" >> "$LOG_FILE"
    fi
    
    echo "$(date): Applied profile '$profile_name'" >> "$LOG_FILE"
}

# Function to show profile switcher (for manual invocation)
show_profile_switcher() {
    local selected=$(show_profile_menu)
    
    [ -z "$selected" ] && return
    
    # Handle special options
    case "$selected" in
        "➕ Create New Profile")
            create_new_profile
            ;;
        "📝 Edit Existing Profile")
            edit_profile
            ;;
        "🗑️  Clear Cache")
            clear_cache
            ;;
        "───")
            # Separator, ignore
            ;;
        *)
            # Extract profile name (remove description if present)
            local profile=$(echo "$selected" | cut -d'-' -f1 | xargs)
            apply_profile "$profile"
            ;;
    esac
}

# Main logic
main() {
    case "${1:-auto}" in
        auto)
            # Try to auto-detect and apply cached profile
            echo "$(date): Starting auto-detection..." >> "$LOG_FILE"
            echo "$(date): Current fingerprint: $(get_monitor_fingerprint)" >> "$LOG_FILE"
            
            local cached=$(get_cached_profile)
            
            if [ -n "$cached" ]; then
                # Check if the profile file actually exists
                if [ ! -f "$CONFIG_DIR/$cached.conf" ]; then
                    echo "$(date): Cached profile '$cached' not found on disk, showing menu..." >> "$LOG_FILE"
                    notify-send -i "dialog-warning" "Monitor Profile" "Cached profile '$cached' not found. Please select a new profile." -t 4000
                    show_profile_switcher
                else
                    echo "$(date): Found cached profile: $cached" >> "$LOG_FILE"
                    apply_profile "$cached" "true"  # Don't re-cache
                fi
            else
                echo "$(date): No cached profile found, showing menu..." >> "$LOG_FILE"
                # No cached profile, show menu
                show_profile_switcher
            fi
            ;;
        menu)
            # Force show menu
            show_profile_switcher
            ;;
        list)
            # List all profiles
            get_profiles
            ;;
        current)
            # Show current fingerprint
            get_monitor_fingerprint
            ;;
        cache)
            # Show cache contents
            if [ -f "$CACHE_FILE" ]; then
                cat "$CACHE_FILE" | jq '.'
            else
                echo "{}"
            fi
            ;;
        apply)
            # Apply specific profile: monitor_profile_manager.sh apply <profile_name>
            if [ -n "$2" ]; then
                apply_profile "$2"
            else
                echo "Usage: $0 apply <profile_name>"
                exit 1
            fi
            ;;
        *)
            echo "Usage: $0 [auto|menu|list|current|cache|apply <profile>]"
            echo ""
            echo "Commands:"
            echo "  auto          - Auto-detect and apply cached profile (default)"
            echo "  menu          - Force show profile selector menu"
            echo "  list          - List all available profiles"
            echo "  current       - Show current monitor fingerprint"
            echo "  cache         - Show cache contents"
            echo "  apply <name>  - Apply specific profile"
            exit 1
            ;;
    esac
}

main "$@"
