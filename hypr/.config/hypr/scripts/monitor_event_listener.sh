#!/bin/bash

# Monitor Event Listener
# Listens for monitor connect/disconnect events and triggers profile manager

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

# Export for child processes
export DISPLAY
export DBUS_SESSION_BUS_ADDRESS

SCRIPT_DIR="$HOME/.config/hypr/scripts"
CACHE_DIR="$HOME/.config/hypr/.cache"
LOGS_DIR="$HOME/.config/hypr/.logs"
CACHE_FILE="$CACHE_DIR/monitor_profile_cache.json"
# Use /run/user/ directory which is cleared on logout - fixes stale lock issues
LOCK_FILE="/run/user/$(id -u)/monitor_profile_listener.lock"
HANDLING_LOCK="/run/user/$(id -u)/monitor_profile_handling.lock"
LAST_FINGERPRINT_FILE="/run/user/$(id -u)/last_monitor_fingerprint"

# Debounce time in seconds (prevent multiple triggers)
DEBOUNCE_TIME=3

# Ensure directories exist
mkdir -p "$CACHE_DIR" "$LOGS_DIR"

# Logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGS_DIR/monitor_listener.log"
}

# Function to get current monitor fingerprint
get_fingerprint() {
    "$SCRIPT_DIR/monitor_profile_manager.sh" current 2>/dev/null
}

# Function to check if we have a cached profile for current setup
get_cached_profile() {
    local current_fp=$(get_fingerprint)
    local normalized=$(echo "$current_fp" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9|:_-]//g')
    
    if [ ! -f "$CACHE_FILE" ]; then
        echo ""
        return
    fi
    
    local profile=$(jq -r --arg fp "$normalized" 'to_entries | map(select(.key == $fp)) | first | .value // empty' "$CACHE_FILE" 2>/dev/null)
    
    if [ -n "$profile" ] && [ "$profile" != "null" ]; then
        echo "$profile"
    else
        echo ""
    fi
}

# Function to handle monitor change
handle_monitor_change() {
    # Prevent re-entry if already handling
    if [ -f "$HANDLING_LOCK" ]; then
        log "Already handling a monitor change, skipping"
        return
    fi
    
    # Create handling lock
    touch "$HANDLING_LOCK"
    
    log "Monitor change detected"
    
    # Wait a moment for monitors to fully initialize
    sleep 2
    
    # Get current fingerprint
    local current_fp=$(get_fingerprint)
    log "Current fingerprint: $current_fp"
    
    # Check if this is actually a change
    if [ -f "$LAST_FINGERPRINT_FILE" ]; then
        local last_fp=$(cat "$LAST_FINGERPRINT_FILE")
        if [ "$current_fp" = "$last_fp" ]; then
            log "Fingerprint unchanged, skipping"
            rm -f "$HANDLING_LOCK"
            return
        fi
    fi
    
    # Save current fingerprint
    echo "$current_fp" > "$LAST_FINGERPRINT_FILE"
    
    # Check if we have a cached profile
    local cached_profile=$(get_cached_profile)
    
    if [ -n "$cached_profile" ]; then
        # Check if the cached profile file actually exists
        if [ ! -f "$HOME/.config/hypr/monitors/$cached_profile.conf" ]; then
            log "Cached profile '$cached_profile' does not exist, showing menu"
            notify-send \
                --app-name="Monitor Manager" \
                --icon="dialog-warning" \
                --urgency=normal \
                "⚠️  Profile Not Found" \
                "Cached profile '$cached_profile' is missing.\nPlease select a new profile from the menu." \
                -t 5000
            
            # Show the profile menu
            if ! pgrep -x "rofi" > /dev/null; then
                sleep 0.5
                "$SCRIPT_DIR/monitor_profile_manager.sh" menu
            fi
        else
            log "Found cached profile: $cached_profile"
            # Apply the profile (notification will be sent by apply_profile function)
            "$SCRIPT_DIR/monitor_profile_manager.sh" auto
        fi
    else
        log "No cached profile found, showing menu"
        # Check if rofi is already running to avoid multiple windows
        if ! pgrep -x "rofi" > /dev/null; then
            # Show the profile menu directly (no notification needed, menu is visible)
            "$SCRIPT_DIR/monitor_profile_manager.sh" menu
        fi
    fi
    
    # Remove handling lock
    rm -f "$HANDLING_LOCK"
}

# Function to get monitor count
get_monitor_count() {
    hyprctl monitors -j 2>/dev/null | jq 'length'
}

# Polling-based monitor detection
poll_monitors() {
    log "Starting polling-based monitor listener"
    
    local last_count=$(get_monitor_count)
    log "Initial monitor count: $last_count"
    
    # Save initial fingerprint
    get_fingerprint > "$LAST_FINGERPRINT_FILE"
    
    # Wait for monitors to stabilize after startup (avoid startup spam)
    log "Waiting 2 seconds for monitors to stabilize..."
    sleep 2
    
    # Update baseline after stabilization
    last_count=$(get_monitor_count)
    get_fingerprint > "$LAST_FINGERPRINT_FILE"
    log "Monitor monitoring active (count: $last_count)"
    
    while true; do
        sleep 1
        
        local current_count=$(get_monitor_count)
        
        if [ "$current_count" != "$last_count" ]; then
            log "Monitor count changed: $last_count -> $current_count"
            handle_monitor_change
            last_count=$current_count
        else
            # Also check if fingerprint changed (same count but different monitors)
            local current_fp=$(get_fingerprint)
            if [ -f "$LAST_FINGERPRINT_FILE" ]; then
                local last_fp=$(cat "$LAST_FINGERPRINT_FILE")
                if [ "$current_fp" != "$last_fp" ]; then
                    log "Fingerprint changed (same count): $last_fp -> $current_fp"
                    handle_monitor_change
                    last_count=$current_count
                fi
            fi
        fi
    done
}

# Wait for DBUS and Notification Service to be available
log "Waiting for DBUS and Notification Service..."
DBUS_WAIT_COUNT=0
MAX_WAIT=60

while [ $DBUS_WAIT_COUNT -lt $MAX_WAIT ]; do
    # 1. Ensure DBUS variable is set (from environment or socket)
    if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
        if [ -S "/run/user/$(id -u)/bus" ]; then
            export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
            log "Found DBUS socket: $DBUS_SESSION_BUS_ADDRESS"
        fi
    fi

    # 2. Check if swaync is running
    if ! pgrep -x "swaync" > /dev/null 2>&1; then
        log "Waiting for swaync to start..."
        DBUS_WAIT_COUNT=$((DBUS_WAIT_COUNT + 1))
        sleep 1
        continue
    fi

    # 3. Try to verify notification service is actually responsive
    if notify-send -t 500 \
        --app-name="Hyprland" \
        --icon="dialog-information" \
        --urgency=low \
        "Monitor System Ready" \
        "Notification daemon initialized successfully" >/dev/null 2>&1; then
        log "Notification daemon is ready."
        break
    fi

    DBUS_WAIT_COUNT=$((DBUS_WAIT_COUNT + 1))
    sleep 1
done

if [ $DBUS_WAIT_COUNT -eq $MAX_WAIT ]; then
    log "WARNING: Notification daemon did not respond after 60 seconds. Notifications might fail."
fi

# Ensure DISPLAY is set
if [ -z "$DISPLAY" ]; then
    export DISPLAY=:0
fi

log "Environment ready: DISPLAY=$DISPLAY, DBUS=$DBUS_SESSION_BUS_ADDRESS"

# Check for lock file (prevent multiple instances)
if [ -f "$LOCK_FILE" ]; then
    pid=$(cat "$LOCK_FILE")
    # Check if process exists AND is actually our script (not a reused PID)
    if ps -p "$pid" > /dev/null 2>&1 && ps -p "$pid" -o cmd= | grep -q "monitor_event_listener"; then
        log "Listener already running (PID: $pid)"
        exit 0
    else
        log "Removing stale lock file (PID $pid not found or not our script)"
        rm -f "$LOCK_FILE"
    fi
fi

# Create lock file
echo $$ > "$LOCK_FILE"

# Cleanup on exit
trap 'rm -f "$LOCK_FILE" "$HANDLING_LOCK"; log "Listener stopped"; exit 0' EXIT INT TERM

log "Monitor listener started (PID: $$)"

# Test notification on startup
if notify-send \
    --app-name="Monitor Manager" \
    --icon="video-display" \
    --urgency=low \
    "🖥️  Monitor Listener Active" \
    "Auto-detecting monitor changes...\nProfile switching enabled" \
    -t 4000 2>/dev/null; then
    log "Startup notification sent successfully"
else
    log "Startup notification failed"
fi

# Use polling-based detection (more reliable)
poll_monitors
