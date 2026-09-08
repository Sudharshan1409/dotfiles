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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
    find "$CONFIG_DIR" -name "*.conf" -type f ! -name "template.conf" ! -name ".*" | while read -r f; do
        basename "$f" .conf
    done | sort
}

# Function to get currently active profile name
get_active_profile() {
    if [ -f "$HOME/.config/hypr/monitors.gen.conf" ]; then
        local target=$(grep -E "^source=" "$HOME/.config/hypr/monitors.gen.conf" 2>/dev/null | cut -d= -f2- | tr -d " ")
        basename "$target" .conf 2>/dev/null || echo ""
    fi
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
    local active_profile=$(get_active_profile)
    local profiles=$(get_profiles)
    
    # Build menu items
    local menu_items=""
    while IFS= read -r profile; do
        [ -z "$profile" ] && continue
        # Get profile description if exists
        local desc=$(grep "^# Description:" "$CONFIG_DIR/$profile.conf" 2>/dev/null | sed 's/^# Description: //')
        local tag="  ${profile}"
        if [ "$profile" = "$active_profile" ]; then
            tag="● ${profile} [Active]"
        fi

        if [ -n "$desc" ]; then
            menu_items="${menu_items}${tag} - ${desc}\n"
        else
            menu_items="${menu_items}${tag}\n"
        fi
    done <<< "$profiles"
    
    # Add special options
    menu_items="${menu_items}───\n"
    menu_items="${menu_items}🪄 Setup Wizard (Create New Profile)\n"
    menu_items="${menu_items}➕ Quick Save Current Setup\n"
    menu_items="${menu_items}🗑️  Clear Cache"
    
    # Show rofi
    local selected=$(echo -e "$menu_items" | rofi -dmenu \
        -p "Monitor Profile" \
        -theme "$ROFI_THEME" \
        -mesg "Active: ${active_profile:-None} | Displays: $(hyprctl monitors -j 2>/dev/null | jq 'length') connected
Click any profile to Apply, Rename, Edit, or Delete" \
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

# Function to quickly save current raw setup without wizard
create_new_profile_raw() {
    # Get profile name from user
    local name=$(rofi -dmenu \
        -p "Profile Name" \
        -theme "$ROFI_THEME" \
        -mesg "Enter a name to quick-save current monitor layout:" \
        -i)
    
    [ -z "$name" ] && return
    
    # Sanitize name
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9_-')
    
    if [ -f "$CONFIG_DIR/$name.conf" ]; then
        notify-send \
            --app-name="Monitor Manager" \
            --icon="dialog-error" \
            --urgency=critical \
            "❌ Profile Already Exists" \
            "A profile named '$name' already exists.\nPlease choose a different name." \
            -t 5000
        return
    fi
    
    # Get current monitor configuration
    local monitor_config=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | 
        "monitor = \(.name), \(.width)x\(.height)@\(.refreshRate | floor), \(.x)x\(.y), \(.scale)"')
    
    # Generate workspace assignments for 9 workspaces
    local workspace_config=$(generate_workspace_assignments)
    
    # Create profile
    cat > "$CONFIG_DIR/$name.conf" << EOF
# Description: Quick-saved profile created on $(date)
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

# Function to create new profile (defaults to Setup Wizard)
create_new_profile() {
    if [ -f "$SCRIPT_DIR/monitor_wizard.sh" ]; then
        exec "$SCRIPT_DIR/monitor_wizard.sh"
    else
        create_new_profile_raw
    fi
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

# Function to open profile in text editor
open_profile_in_editor() {
    local selected="$1"
    local editor=$(find_editor)
    local profile_path="$CONFIG_DIR/$selected.conf"
    
    if [ ! -f "$profile_path" ]; then
        if [[ "$selected" =~ s$ ]] && [ -f "$CONFIG_DIR/${selected%s}.conf" ]; then
            selected="${selected%s}"
            profile_path="$CONFIG_DIR/$selected.conf"
        elif [ -f "$CONFIG_DIR/${selected}s.conf" ]; then
            selected="${selected}s"
            profile_path="$CONFIG_DIR/$selected.conf"
        fi
    fi
    
    if [ -z "$editor" ]; then
        hyprctl notify 3 4000 "rgb(f38ba8)" "fontsize:14 ❌ No text editor found" 2>/dev/null || true
        notify-send \
            --app-name="Monitor Manager" \
            --icon="dialog-error" \
            --urgency=critical \
            "❌ No Editor Found" \
            "Please install a text editor (nvim, vim, nano, etc.)\nor set \$EDITOR environment variable." \
            -t 6000 2>/dev/null &
        return
    fi
    
    # Check if it's a GUI editor
    case "$editor" in
        gedit|mousepad|kate|xed|code)
            # GUI editors - launch directly
            "$editor" "$profile_path" &
            ;;
        *)
            # Terminal editors - launch with available terminal emulator
            if command -v ghostty >/dev/null 2>&1; then
                ghostty -e "$editor" "$profile_path" &
            elif command -v kitty >/dev/null 2>&1; then
                kitty -e "$editor" "$profile_path" &
            elif command -v alacritty >/dev/null 2>&1; then
                alacritty -e "$editor" "$profile_path" &
            else
                x-terminal-emulator -e "$editor" "$profile_path" &
            fi
            ;;
    esac
    
    hyprctl notify 1 3000 "rgb(89b4fa)" "fontsize:14 ✏️ Opened '$selected' in $editor" 2>/dev/null || true
    notify-send \
        --app-name="Monitor Manager" \
        --icon="accessories-text-editor" \
        --urgency=low \
        "✏️ Editor Opened" \
        "Now editing profile: $selected.conf" \
        -t 3000 2>/dev/null &
}

# Function to rename a profile
rename_profile() {
    local old_name="$1"
    [ -z "$old_name" ] && return
    
    # Resolve smart 's' fallback if needed
    if [ ! -f "$CONFIG_DIR/$old_name.conf" ]; then
        if [[ "$old_name" =~ s$ ]] && [ -f "$CONFIG_DIR/${old_name%s}.conf" ]; then
            old_name="${old_name%s}"
        elif [ -f "$CONFIG_DIR/${old_name}s.conf" ]; then
            old_name="${old_name}s"
        fi
    fi
    
    local new_name=$(rofi -dmenu \
        -p "Rename Profile" \
        -theme "$ROFI_THEME" \
        -mesg "Enter a new name for profile '$old_name':" \
        -filter "$old_name" \
        -i)
    
    [ -z "$new_name" ] && return
    
    # Sanitize name
    new_name=$(echo "$new_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9_-')
    
    if [ -z "$new_name" ] || [ "$new_name" = "$old_name" ]; then
        handle_profile_action "$old_name"
        return
    fi
    
    if [ -f "$CONFIG_DIR/$new_name.conf" ]; then
        hyprctl notify 3 4000 "rgb(f38ba8)" "fontsize:14 ❌ Profile '$new_name' already exists" 2>/dev/null || true
        notify-send \
            --app-name="Monitor Manager" \
            --icon="dialog-error" \
            --urgency=critical \
            "❌ Name Already Exists" \
            "A profile named '$new_name' already exists.\nPlease choose a different name." \
            -t 4000 2>/dev/null &
        handle_profile_action "$old_name"
        return
    fi
    
    # Rename the file
    mv "$CONFIG_DIR/$old_name.conf" "$CONFIG_DIR/$new_name.conf"
    
    # If active profile was renamed, update monitors.gen.conf
    local active_profile=$(get_active_profile)
    if [ "$active_profile" = "$old_name" ]; then
        echo "source=$CONFIG_DIR/$new_name.conf" > "$HOME/.config/hypr/monitors.gen.conf"
    fi
    
    # Update cache entries mapping old name to new name
    if [ -f "$CACHE_FILE" ]; then
        jq --arg old "$old_name" --arg new "$new_name" \
            'map_values(if . == $old then $new else . end)' "$CACHE_FILE" > "$CACHE_FILE.tmp" 2>/dev/null && \
            mv "$CACHE_FILE.tmp" "$CACHE_FILE"
    fi
    
    echo "$(date): Renamed profile '$old_name' to '$new_name'" >> "$LOG_FILE"
    
    hyprctl notify 1 3500 "rgb(a6e3a1)" "fontsize:14 ✏️ Renamed: $old_name -> $new_name" 2>/dev/null || true
    notify-send \
        --app-name="Monitor Manager" \
        --icon="accessories-text-editor" \
        --urgency=normal \
        "✏️ Profile Renamed" \
        "Renamed profile '$old_name' to '$new_name'" \
        -t 4000 2>/dev/null &
        
    handle_profile_action "$new_name"
}

# Function to delete a profile with confirmation
delete_profile() {
    local profile="$1"
    [ -z "$profile" ] && return
    
    # Resolve smart 's' fallback if needed
    if [ ! -f "$CONFIG_DIR/$profile.conf" ]; then
        if [[ "$profile" =~ s$ ]] && [ -f "$CONFIG_DIR/${profile%s}.conf" ]; then
            profile="${profile%s}"
        elif [ -f "$CONFIG_DIR/${profile}s.conf" ]; then
            profile="${profile}s"
        fi
    fi
    
    local active_profile=$(get_active_profile)
    if [ "$profile" = "$active_profile" ]; then
        hyprctl notify 3 4000 "rgb(f9e2af)" "fontsize:14 ⚠️ Cannot delete active profile: $profile" 2>/dev/null || true
        notify-send \
            --app-name="Monitor Manager" \
            --icon="dialog-warning" \
            --urgency=critical \
            "⚠️ Cannot Delete Active Profile" \
            "Profile '$profile' is currently active.\nPlease switch to another profile first." \
            -t 5000 2>/dev/null &
        handle_profile_action "$profile"
        return
    fi
    
    local confirm=$(echo -e "❌ No, Keep Profile\n🗑️ Yes, Delete Profile" | rofi -dmenu \
        -p "Confirm Delete" \
        -theme "$ROFI_THEME" \
        -mesg "Are you sure you want to permanently delete profile '$profile'?" \
        -i)
    
    if [[ "$confirm" =~ ^(🗑️|Yes) ]]; then
        rm -f "$CONFIG_DIR/$profile.conf"
        
        # Remove deleted profile from cache
        if [ -f "$CACHE_FILE" ]; then
            jq --arg del "$profile" \
                'with_entries(select(.value != $del))' "$CACHE_FILE" > "$CACHE_FILE.tmp" 2>/dev/null && \
                mv "$CACHE_FILE.tmp" "$CACHE_FILE"
        fi
        
        echo "$(date): Deleted profile '$profile'" >> "$LOG_FILE"
        
        hyprctl notify 1 3500 "rgb(a6e3a1)" "fontsize:14 🗑️ Deleted: $profile" 2>/dev/null || true
        notify-send \
            --app-name="Monitor Manager" \
            --icon="edit-delete" \
            --urgency=normal \
            "🗑️ Profile Deleted" \
            "Deleted profile: $profile.conf" \
            -t 4000 2>/dev/null &
            
        show_profile_switcher
    else
        handle_profile_action "$profile"
    fi
}

# Helper to resolve profile name variations (e.g. singular/plural or benq/bnq)
resolve_profile_name() {
    local name="$1"
    [ -z "$name" ] && echo "" && return
    
    if [ -f "$CONFIG_DIR/$name.conf" ]; then
        echo "$name"
        return
    fi
    
    # Check singular/plural 's'
    if [[ "$name" =~ s$ ]] && [ -f "$CONFIG_DIR/${name%s}.conf" ]; then
        echo "${name%s}"
        return
    fi
    if [ -f "$CONFIG_DIR/${name}s.conf" ]; then
        echo "${name}s"
        return
    fi
    
    # Check benq vs bnq
    if [[ "$name" == *"benq"* ]]; then
        local alt="${name/benq/bnq}"
        [ -f "$CONFIG_DIR/$alt.conf" ] && echo "$alt" && return
    elif [[ "$name" == *"bnq"* ]]; then
        local alt="${name/bnq/benq}"
        [ -f "$CONFIG_DIR/$alt.conf" ] && echo "$alt" && return
    fi
    
    echo "$name"
}

# Function to check if a profile configuration matches the current connected displays
check_profile_compatibility() {
    local profile="$1"
    local resolved=$(resolve_profile_name "$profile")
    local conf_file="$CONFIG_DIR/$resolved.conf"
    
    if [ ! -f "$conf_file" ]; then
        echo "not_found"
        return
    fi
    
    local connected=$(hyprctl monitors -j 2>/dev/null | jq -r '.[].name' | sort -u)
    local prof_mons=$(grep -E '^[ \t]*monitor[ \t]*=' "$conf_file" | \
        sed -E 's/^[ \t]*monitor[ \t]*=[ \t]*//' | cut -d, -f1 | tr -d ' ' | sort -u)
    
    if [ -z "$prof_mons" ]; then
        echo "empty"
        return
    fi
    
    local missing=$(grep -Fxv -f <(echo "$connected") <(echo "$prof_mons") | tr '\n' ' ' | xargs)
    local unconfigured=$(grep -Fxv -f <(echo "$prof_mons") <(echo "$connected") | tr '\n' ' ' | xargs)
    
    if [ -n "$missing" ] || [ -n "$unconfigured" ]; then
        echo "incompatible|${missing}|${unconfigured}"
    else
        echo "compatible"
    fi
}

# Function to display error message dialog when a profile cannot be applied
show_incompatible_profile_error() {
    local profile="$1"
    local missing="$2"
    local unconfigured="$3"
    
    local resolved=$(resolve_profile_name "$profile")
    local conf_file="$CONFIG_DIR/$resolved.conf"
    local connected=$(hyprctl monitors -j 2>/dev/null | jq -r '.[].name' | tr '\n' ' ' | xargs)
    local prof_mons=$(grep -E '^[ \t]*monitor[ \t]*=' "$conf_file" 2>/dev/null | \
        sed -E 's/^[ \t]*monitor[ \t]*=[ \t]*//' | cut -d, -f1 | tr -d ' ' | tr '\n' ' ' | xargs)
    
    # Log error
    echo "$(date): Error: Cannot assign profile '$profile' to current display setup (Missing: ${missing:-None}, Unconfigured: ${unconfigured:-None})" >> "$LOG_FILE"
    echo "Error: Cannot assign profile '$profile' to current display setup." >&2
    echo "  Connected displays: $connected" >&2
    echo "  Profile requires:   $prof_mons" >&2
    [ -n "$missing" ] && echo "  Missing from setup: $missing" >&2
    [ -n "$unconfigured" ] && echo "  Unconfigured:       $unconfigured" >&2

    # Notify on desktop immediately
    hyprctl notify 3 5000 "rgb(f38ba8)" "fontsize:14 ❌ Profile '$profile' cannot be assigned" 2>/dev/null || true
    (
        notify-send \
            --app-name="Monitor Manager" \
            --icon="dialog-error" \
            --urgency=critical \
            "❌ Cannot Assign Profile" \
            "Profile '$profile' cannot be assigned to current displays.\nMissing: ${missing:-None}\nUnconfigured: ${unconfigured:-None}" \
            -t 6000 2>/dev/null || true
    ) &
    
    # Build informative error dialog message
    local err_msg="❌ Cannot assign profile '$profile' to your current display setup."$'\n'$'\n'
    err_msg+="Current Connected Displays:  ${connected}"$'\n'
    err_msg+="Profile '$profile' Requires:  ${prof_mons}"$'\n'$'\n'
    [ -n "$missing" ] && err_msg+="• Missing from your setup:   ${missing}"$'\n'
    [ -n "$unconfigured" ] && err_msg+="• Connected but not in profile: ${unconfigured}"$'\n'$'\n'
    err_msg+="It is not possible to assign this profile without matching displays."
    
    local options="↩  Back to Profile Menu\n🪄 Open Setup Wizard to configure current displays\n⚠️ Force Apply Anyway (Not Recommended)"
    
    local choice=$(echo -e "$options" | rofi -dmenu \
        -p "Incompatible Profile" \
        -theme "$ROFI_THEME" \
        -mesg "$err_msg" \
        -i)
        
    case "$choice" in
        *"Force"*)
            apply_profile "$resolved" "false" "true"
            ;;
        *"Wizard"*)
            exec "$SCRIPT_DIR/monitor_wizard.sh"
            ;;
        *)
            handle_profile_action "$resolved"
            ;;
    esac
}

# Function to edit a profile (wizard for screen positions or text editor)
edit_profile_action() {
    local profile="$1"
    local resolved=$(resolve_profile_name "$profile")
    
    local edit_options="🪄 Reconfigure Layout (Ask Screen Positions & Scales)\n📝 Edit Raw Config File in Text Editor\n↩  Back to Profile Menu"
    local choice=$(echo -e "$edit_options" | rofi -dmenu \
        -p "Edit: $resolved" \
        -theme "$ROFI_THEME" \
        -mesg "Profile: $resolved"$'\n'"Choose how to edit this profile:" \
        -i)
        
    case "$choice" in
        *"Reconfigure"*|*"Layout"*|*"Positions"*|*"🪄"*)
            exec "$SCRIPT_DIR/monitor_wizard.sh" "$resolved"
            ;;
        *"Text"*|*"Config"*|*"Raw"*|*"📝"*)
            open_profile_in_editor "$resolved"
            ;;
        *)
            handle_profile_action "$resolved"
            ;;
    esac
}

# Function to handle actions for a selected profile (Apply, Rename, Edit, Delete)
handle_profile_action() {
    local profile="$1"
    [ -z "$profile" ] && return
    
    profile=$(resolve_profile_name "$profile")
    
    if [ ! -f "$CONFIG_DIR/$profile.conf" ]; then
        hyprctl notify 3 4000 "rgb(f38ba8)" "fontsize:14 ❌ Profile '$profile' not found" 2>/dev/null || true
        notify-send \
            --app-name="Monitor Manager" \
            --icon="dialog-error" \
            --urgency=critical \
            "❌ Profile Not Found" \
            "Profile '$profile.conf' does not exist." \
            -t 4000 2>/dev/null &
        return
    fi

    local active_profile=$(get_active_profile)
    local is_active=false
    [ "$profile" = "$active_profile" ] && is_active=true

    # Exact same uniform options for all profiles, matching user screenshot
    local actions="▶ Select & Apply Profile\n✏️  Rename Profile\n📝 Edit Profile in Editor\n🗑️  Delete Profile\n↩  Back to Menu"

    local mesg_text="Profile: $profile"
    [ "$is_active" = "true" ] && mesg_text+=" [Active]"
    mesg_text+=$'\n'"Choose what to do with this profile:"

    local action=$(echo -e "$actions" | rofi -dmenu \
        -p "Profile: $profile" \
        -theme "$ROFI_THEME" \
        -mesg "$mesg_text" \
        -i)
    
    case "$action" in
        *"Apply"*|*"Select"*)
            apply_profile "$profile"
            ;;
        *"Rename"*)
            rename_profile "$profile"
            ;;
        *"Edit"*)
            edit_profile_action "$profile"
            ;;
        *"Delete"*)
            delete_profile "$profile"
            ;;
        *"Back"*)
            show_profile_switcher
            ;;
        *)
            ;;
    esac
}

# Function to manage existing profiles
manage_profiles() {
    show_profile_switcher
}

# Function to clear cache
clear_cache() {
    local confirm=$(rofi -dmenu -p "Confirm" -theme "$ROFI_THEME" \
        -mesg "Are you sure you want to clear the monitor profile cache?" <<< $'Yes\nNo')
    
    if [ "$confirm" = "Yes" ]; then
        rm -f "$CACHE_FILE"
        hyprctl notify 1 3500 "rgb(a6e3a1)" "fontsize:14 🗑️ Cache Cleared" 2>/dev/null || true
        notify-send \
            --app-name="Monitor Manager" \
            --icon="edit-clear" \
            --urgency=normal \
            "🗑️ Cache Cleared" \
            "All monitor profile cache data\nhas been successfully cleared." \
            -t 4000 2>/dev/null &
    fi
}

# Function to apply a profile
apply_profile() {
    local profile_name="$1"
    local skip_cache="${2:-false}"
    local force="${3:-false}"
    
    profile_name=$(resolve_profile_name "$profile_name")
    local conf_file="$CONFIG_DIR/$profile_name.conf"
    
    if [ ! -f "$conf_file" ]; then
        hyprctl notify 3 4000 "rgb(f38ba8)" "fontsize:14 ❌ Profile '${profile_name:-unspecified}' not found" 2>/dev/null || true
        notify-send \
            --app-name="Monitor Manager" \
            --icon="dialog-error" \
            --urgency=critical \
            "❌ Profile Not Found" \
            "Profile file '${profile_name:-unspecified}.conf' does not exist.\nThe profile may have been deleted or renamed." \
            -t 5000 2>/dev/null &
        return 1
    fi
    
    # Check compatibility if not forced
    if [ "$force" != "true" ]; then
        local compat=$(check_profile_compatibility "$profile_name")
        if [[ "$compat" == incompatible* ]]; then
            local missing=$(echo "$compat" | cut -d'|' -f2)
            local unconfigured=$(echo "$compat" | cut -d'|' -f3)
            show_incompatible_profile_error "$profile_name" "$missing" "$unconfigured"
            return 1
        fi
    fi
    
    # 1. Update the sourced configuration file atomically
    echo "source=$conf_file" > "$HOME/.config/hypr/monitors.gen.conf"
    
    # 2. Directly apply each monitor definition line via hyprctl keyword
    # This guarantees immediate compositor re-layout without waiting for full config parse
    while IFS= read -r line; do
        local monitor_rule=$(echo "$line" | sed 's/^[ \t]*monitor[ \t]*=[ \t]*//')
        [ -n "$monitor_rule" ] && hyprctl keyword monitor "$monitor_rule" >/dev/null 2>&1
    done < <(grep -E '^[ \t]*monitor[ \t]*=' "$conf_file")
    
    # 3. Directly apply workspace assignments
    while IFS= read -r line; do
        local ws_rule=$(echo "$line" | sed 's/^[ \t]*workspace[ \t]*=[ \t]*//')
        [ -n "$ws_rule" ] && hyprctl keyword workspace "$ws_rule" >/dev/null 2>&1
    done < <(grep -E '^[ \t]*workspace[ \t]*=' "$conf_file")
    
    # 4. Trigger Hyprland full reload to ensure rules and state synchronize
    hyprctl reload >/dev/null 2>&1
    
    # 5. Cache this profile for this fingerprint
    if [ "$skip_cache" != "true" ]; then
        save_to_cache "$profile_name"
    fi
    
    # 6. Notify user immediately via hyprctl notify and async notify-send
    hyprctl notify 1 3500 "rgb(a6e3a1)" "fontsize:14 🖥️ Profile Applied: $profile_name" 2>/dev/null || true
    (
        notify-send \
            --app-name="Monitor Manager" \
            --icon="video-display" \
            --urgency=normal \
            "🖥️ Profile Applied Successfully" \
            "Loaded profile: '$profile_name'\nMonitor configuration updated" \
            -t 4000 2>>"$LOG_FILE" || true
    ) &
    
    echo "$(date): Applied profile '$profile_name'" >> "$LOG_FILE"
}

# Function to show profile switcher (for manual invocation)
show_profile_switcher() {
    local selected=$(show_profile_menu)
    
    [ -z "$selected" ] && return
    
    # Handle special options by strict prefix
    case "$selected" in
        "🪄 "*)
            exec "$SCRIPT_DIR/monitor_wizard.sh"
            ;;
        "➕ "*)
            create_new_profile_raw
            ;;
        "🗑️ "*)
            clear_cache
            ;;
        "───"|"")
            # Separator or empty, ignore
            ;;
        *)
            # Extract profile name (remove bullet, [Active], and description)
            local profile=$(echo "$selected" | sed 's/^[●○ ]*//; s/ \[Active\]//; s/ - .*//; s/^[ \t]*//; s/[ \t]*$//')
            [ -n "$profile" ] && handle_profile_action "$profile"
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
                    notify-send \
                        --app-name="Monitor Manager" \
                        --icon="dialog-warning" \
                        --urgency=normal \
                        "⚠️  Cached Profile Missing" \
                        "Cached profile '$cached' was not found on disk.\nPlease select a new profile from the menu." \
                        -t 5000 2>/dev/null &
                    show_profile_switcher
                else
                    echo "$(date): Found cached profile: $cached" >> "$LOG_FILE"
                    local compat=$(check_profile_compatibility "$cached")
                    if [[ "$compat" == compatible* ]]; then
                        apply_profile "$cached" "true"
                    else
                        echo "$(date): Cached profile '$cached' is incompatible with current displays, showing menu..." >> "$LOG_FILE"
                        notify-send \
                            --app-name="Monitor Manager" \
                            --icon="dialog-warning" \
                            --urgency=normal \
                            "⚠️  Display Configuration Changed" \
                            "Cached profile '$cached' does not match current displays.\nPlease select or create a profile." \
                            -t 5000 2>/dev/null &
                        show_profile_switcher
                    fi
                fi
            else
                echo "$(date): No cached profile found, showing menu..." >> "$LOG_FILE"
                show_profile_switcher
            fi
            ;;
        wizard)
            # Launch interactive monitor wizard
            exec "$SCRIPT_DIR/monitor_wizard.sh"
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
            # Apply specific profile: monitor_profile_manager.sh apply <profile_name> [--force]
            if [ -n "$2" ]; then
                local force="false"
                [ "$3" = "--force" ] && force="true"
                apply_profile "$2" "false" "$force"
            else
                echo "Usage: $0 apply <profile_name> [--force]"
                exit 1
            fi
            ;;
        rename)
            # Rename profile CLI: monitor_profile_manager.sh rename <old_name> <new_name>
            if [ -n "$2" ] && [ -n "$3" ]; then
                local old_name="$2"
                local new_name="$3"
                if [ -f "$CONFIG_DIR/$old_name.conf" ]; then
                    mv "$CONFIG_DIR/$old_name.conf" "$CONFIG_DIR/$new_name.conf"
                    if [ "$(get_active_profile)" = "$old_name" ]; then
                        echo "source=$CONFIG_DIR/$new_name.conf" > "$HOME/.config/hypr/monitors.gen.conf"
                    fi
                    if [ -f "$CACHE_FILE" ]; then
                        jq --arg old "$old_name" --arg new "$new_name" \
                            'map_values(if . == $old then $new else . end)' "$CACHE_FILE" > "$CACHE_FILE.tmp" 2>/dev/null && \
                            mv "$CACHE_FILE.tmp" "$CACHE_FILE"
                    fi
                    echo "Renamed '$old_name' to '$new_name'"
                else
                    echo "Error: Profile '$old_name.conf' not found."
                    exit 1
                fi
            else
                echo "Usage: $0 rename <old_name> <new_name>"
                exit 1
            fi
            ;;
        delete)
            # Delete profile CLI: monitor_profile_manager.sh delete <profile_name>
            if [ -n "$2" ]; then
                local profile="$2"
                if [ "$(get_active_profile)" = "$profile" ]; then
                    echo "Error: Cannot delete currently active profile '$profile'."
                    exit 1
                fi
                if [ -f "$CONFIG_DIR/$profile.conf" ]; then
                    rm -f "$CONFIG_DIR/$profile.conf"
                    if [ -f "$CACHE_FILE" ]; then
                        jq --arg del "$profile" \
                            'with_entries(select(.value != $del))' "$CACHE_FILE" > "$CACHE_FILE.tmp" 2>/dev/null && \
                            mv "$CACHE_FILE.tmp" "$CACHE_FILE"
                    fi
                    echo "Deleted profile '$profile'"
                else
                    echo "Error: Profile '$profile.conf' not found."
                    exit 1
                fi
            else
                echo "Usage: $0 delete <profile_name>"
                exit 1
            fi
            ;;
        *)
            echo "Usage: $0 [auto|wizard|menu|list|current|cache|apply <name>|rename <old> <new>|delete <name>]"
            echo ""
            echo "Commands:"
            echo "  auto                  - Auto-detect and apply cached profile (default)"
            echo "  wizard                - Launch interactive Monitor Setup Wizard"
            echo "  menu                  - Force show profile selector menu"
            echo "  list                  - List all available profiles"
            echo "  current               - Show current monitor fingerprint"
            echo "  cache                 - Show cache contents"
            echo "  apply <name>          - Apply specific profile"
            echo "  rename <old> <new>    - Rename a profile"
            echo "  delete <name>         - Delete a profile"
            exit 1
            ;;
    esac
}

main "$@"
