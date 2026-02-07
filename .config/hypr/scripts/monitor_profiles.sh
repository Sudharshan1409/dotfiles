#!/bin/bash
# monitor_profiles.sh - Smart monitor profile management with caching
#
# Usage:
#   monitor_profiles.sh select    - Show rofi selector to choose profile
#   monitor_profiles.sh apply     - Auto-apply cached profile or show selector
#   monitor_profiles.sh current   - Show current monitor setup
#
# Cache structure (JSON):
# {
#   "hostname": {
#     "monitor_signature": {
#       "monitors": ["Samsung U32R59x", "BenQ GW2480"],
#       "profile": "triple-dp-hdmi",
#       "last_used": "2024-02-07T12:00:00"
#     }
#   }
# }

CACHE_DIR="$HOME/.cache/hypr-monitors"
CACHE_FILE="$CACHE_DIR/profiles.json"
PROFILES_DIR="$HOME/.config/hypr/monitors"

# Ensure D-Bus is available for notifications
if [[ -z "$DBUS_SESSION_BUS_ADDRESS" ]]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
fi

# Initialize cache file if it doesn't exist
init_cache() {
    mkdir -p "$CACHE_DIR"
    if [[ ! -f "$CACHE_FILE" ]]; then
        echo '{}' > "$CACHE_FILE"
    fi
}

# Get current hostname
get_hostname() {
    hostname
}

# Get connected monitors signature (sorted list of make+model)
get_monitor_signature() {
    hyprctl monitors -j | jq -r '[.[] | "\(.make)|\(.model)"] | sort | join(";")' 2>/dev/null
}

# Get connected monitors as readable list
get_monitor_list() {
    hyprctl monitors -j | jq -r '.[] | "\(.name): \(.make) \(.model)"' 2>/dev/null
}

# Get cached profile for current monitor setup
get_cached_profile() {
    local hostname=$(get_hostname)
    local signature=$(get_monitor_signature)
    
    if [[ -z "$signature" ]]; then
        return 1
    fi
    
    jq -r --arg host "$hostname" --arg sig "$signature" \
        '.[$host][$sig].profile // empty' "$CACHE_FILE" 2>/dev/null
}

# Save profile to cache
save_to_cache() {
    local profile="$1"
    local hostname=$(get_hostname)
    local signature=$(get_monitor_signature)
    local monitors=$(hyprctl monitors -j | jq -c '[.[] | "\(.make) \(.model)"]' 2>/dev/null)
    local timestamp=$(date -Iseconds)
    
    # Read current cache
    local cache=$(cat "$CACHE_FILE" 2>/dev/null || echo '{}')
    
    # Update cache with new entry
    echo "$cache" | jq \
        --arg host "$hostname" \
        --arg sig "$signature" \
        --arg prof "$profile" \
        --argjson mons "$monitors" \
        --arg time "$timestamp" \
        '.[$host][$sig] = {"monitors": $mons, "profile": $prof, "last_used": $time}' \
        > "${CACHE_FILE}.tmp" && mv "${CACHE_FILE}.tmp" "$CACHE_FILE"
    
    logger -t monitor-profiles "Cached profile '$profile' for $hostname with signature: $signature"
}

# List available profiles from kanshi config
list_profiles() {
    grep -oP "^profile \K[^\s{]+" ~/.config/kanshi/config 2>/dev/null | sort -u
}

# Apply a specific profile using hyprctl
apply_profile() {
    local profile="$1"
    
    # Parse the kanshi config to get monitor settings for this profile
    local in_profile=0
    local monitors=()
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^profile\ $profile ]]; then
            in_profile=1
        elif [[ $in_profile -eq 1 ]]; then
            if [[ "$line" =~ ^\} ]]; then
                break
            elif [[ "$line" =~ output\ ([^\ ]+)\ mode\ ([^\ ]+)\ position\ ([^\ ]+) ]]; then
                local output="${BASH_REMATCH[1]}"
                local mode="${BASH_REMATCH[2]}"
                local pos="${BASH_REMATCH[3]}"
                # Apply monitor config via hyprctl
                hyprctl keyword monitor "$output,$mode,$pos,1" >/dev/null 2>&1
            fi
        fi
    done < ~/.config/kanshi/config
    
    # Run the workspace assignment script
    case "$profile" in
        triple-*)
            ~/.config/hypr/scripts/assign_workspaces.sh "$profile" laptop=eDP-1 main=DP-1 secondary=HDMI-A-1
            ;;
        dual-dp)
            ~/.config/hypr/scripts/assign_workspaces.sh "$profile" laptop=eDP-1 main=DP-1
            ;;
        dual-hdmi)
            ~/.config/hypr/scripts/assign_workspaces.sh "$profile" laptop=eDP-1 main=HDMI-A-1
            ;;
        dual-dvi)
            ~/.config/hypr/scripts/assign_workspaces.sh "$profile" laptop=eDP-1 main=DVI-I-1
            ;;
        laptop-only)
            ~/.config/hypr/scripts/assign_workspaces.sh "$profile" laptop=eDP-1
            ;;
        *)
            ~/.config/hypr/scripts/assign_workspaces.sh "$profile" laptop=eDP-1
            ;;
    esac
}

# Show rofi selector for profiles
show_selector() {
    local profiles=$(list_profiles)
    local current_signature=$(get_monitor_signature)
    local cached_profile=$(get_cached_profile)
    local monitor_count=$(hyprctl monitors -j | jq 'length' 2>/dev/null)
    
    # Build rofi prompt with current info
    local prompt="Monitors: $monitor_count"
    
    # Show profiles in rofi
    local selected=$(echo "$profiles" | rofi -dmenu -i \
        -p "$prompt" \
        -mesg "Select a monitor profile (cached: ${cached_profile:-none})" \
        -theme-str 'window {width: 400px;}')
    
    if [[ -n "$selected" ]]; then
        # Save to cache and apply
        save_to_cache "$selected"
        apply_profile "$selected"
        
        notify-send \
            --app-name="Monitor Profiles" \
            --icon="video-display" \
            --urgency=normal \
            --expire-time=3000 \
            "Profile Applied: $selected" \
            "Saved to cache for this monitor configuration"
    fi
}

# Auto-apply cached profile or show selector
auto_apply() {
    local cached_profile=$(get_cached_profile)
    
    if [[ -n "$cached_profile" ]]; then
        logger -t monitor-profiles "Auto-applying cached profile: $cached_profile"
        apply_profile "$cached_profile"
    else
        # No cached profile, show selector
        logger -t monitor-profiles "No cached profile found, showing selector"
        show_selector
    fi
}

# Show current monitor setup
show_current() {
    local hostname=$(get_hostname)
    local signature=$(get_monitor_signature)
    local cached=$(get_cached_profile)
    
    echo "Hostname: $hostname"
    echo "Monitor Signature: $signature"
    echo "Cached Profile: ${cached:-none}"
    echo ""
    echo "Connected Monitors:"
    get_monitor_list
}

# Main
init_cache

case "${1:-}" in
    select)
        show_selector
        ;;
    apply)
        auto_apply
        ;;
    current)
        show_current
        ;;
    *)
        echo "Usage: $0 {select|apply|current}"
        exit 1
        ;;
esac
