#!/bin/bash

# ==============================================================================
# Interactive Monitor Setup Wizard for Hyprland
# ==============================================================================
# - Detects connected monitors via hyprctl
# - Guides user through left-to-right physical alignment
# - Enforces anti-blur: native panel resolution + crisp fractional scaling
# - Automatically computes logical coordinates: X_n = X_(n-1) + (W / Scale)
# - Provides a 15-second auto-reverting live preview safety net
# - Allocates round-robin workspaces (1-9) and generates a clean profile .conf
# - Caches hardware fingerprint for automatic profile switching
# ==============================================================================

# Source user environment if available
[ -f "$HOME/.config/environment.d/envvars.conf" ] && source "$HOME/.config/environment.d/envvars.conf" 2>/dev/null
[ -f "$HOME/.pam_environment" ] && source "$HOME/.pam_environment" 2>/dev/null

if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
        DBUS=$(find /run/user/$(id -u) -name "bus" -type s 2>/dev/null | head -1)
        [ -n "$DBUS" ] && export DBUS_SESSION_BUS_ADDRESS="unix:path=$DBUS"
    fi
fi

if [ -z "$DISPLAY" ]; then
    [ -S "/tmp/.X11-unix/X0" ] && export DISPLAY=:0
    [ -S "/tmp/.X11-unix/X1" ] && export DISPLAY=:1
fi

export DISPLAY
export DBUS_SESSION_BUS_ADDRESS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/hypr/monitors"
CACHE_DIR="$HOME/.config/hypr/.cache"
LOGS_DIR="$HOME/.config/hypr/.logs"
CACHE_FILE="$CACHE_DIR/monitor_profile_cache.json"
ROFI_THEME="$HOME/.config/rofi/monitor-profile.rasi"
CONFIRM_THEME="$HOME/.config/rofi/confirmation.rasi"
LOG_FILE="$LOGS_DIR/monitor_wizard.log"
TARGET_PROFILE="${1:-}"

mkdir -p "$CONFIG_DIR" "$CACHE_DIR" "$LOGS_DIR"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOG_FILE"
}

# ------------------------------------------------------------------------------
# Helper: Hardware Fingerprinting & Caching (Compatible with profile manager)
# ------------------------------------------------------------------------------
get_mac_fingerprint() {
    local mac=$(ip link show | grep -E "(ether|link/ether)" | awk '{print $2}' | head -1 | tr -d ':')
    [ -z "$mac" ] && mac="nomac"
    echo "$mac"
}

get_monitor_fingerprint() {
    local mac=$(get_mac_fingerprint)
    local monitors=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | "\(.name):\(.description | gsub(" "; "_"))"' | sort | tr '\n' '|')
    if [ -z "$monitors" ]; then
        echo "${mac}|nomonitor"
    else
        monitors="${monitors%|}"
        echo "${mac}|${monitors}"
    fi
}

normalize_fingerprint() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9|:_-]//g'
}

save_to_cache() {
    local profile_name="$1"
    local fingerprint=$(get_monitor_fingerprint)
    local normalized_fp=$(normalize_fingerprint "$fingerprint")

    [ ! -f "$CACHE_FILE" ] && echo "{}" > "$CACHE_FILE"

    jq --arg fp "$normalized_fp" --arg profile "$profile_name" \
        '.[$fp] = $profile' "$CACHE_FILE" > "$CACHE_FILE.tmp" && \
        mv "$CACHE_FILE.tmp" "$CACHE_FILE"

    log "Cached profile '$profile_name' for fingerprint: $fingerprint"
}

clean_label() {
    local port="$1"
    local desc="$2"
    local make="$3"
    local model="$4"

    if [[ "$port" =~ ^eDP ]]; then
        echo "💻 Laptop Display"
        return
    fi

    local brand=""
    if [ -n "$make" ] && [ "$make" != "null" ]; then
        brand=$(echo "$make" | sed 's/ Electric Company//g; s/ Corporation//g; s/ Inc\.//g' | xargs)
    fi

    local name=""
    if [ -n "$model" ] && [ "$model" != "null" ]; then
        name="$model"
    elif [ -n "$desc" ] && [ "$desc" != "null" ]; then
        name=$(echo "$desc" | sed 's/ Electric Company//g; s/ Corporation//g' | xargs)
    else
        name="$port"
    fi

    if [ -n "$brand" ] && [[ ! "$name" =~ "$brand" ]]; then
        echo "🖥️  $brand $name"
    else
        echo "🖥️  $name"
    fi
}

short_name() {
    local port="$1"
    local label="$2"
    if [[ "$port" =~ ^eDP ]]; then
        echo "💻 Laptop"
    else
        local brand_or_model=$(echo "$label" | sed 's/^[^a-zA-Z0-9]*//; s/ .*//')
        echo "🖥️  ${brand_or_model:-Monitor}"
    fi
}

# ------------------------------------------------------------------------------
# Step 1: Detect Connected Monitors
# ------------------------------------------------------------------------------
log "Starting Monitor Setup Wizard..."

MONITORS_JSON=$(hyprctl monitors all -j 2>/dev/null)
if [ -z "$MONITORS_JSON" ] || [ "$MONITORS_JSON" = "[]" ]; then
    MONITORS_JSON=$(hyprctl monitors -j 2>/dev/null)
fi

NUM_MONITORS=$(echo "$MONITORS_JSON" | jq 'length' 2>/dev/null || echo 0)

if [ "$NUM_MONITORS" -le 0 ]; then
    notify-send \
        --app-name="Monitor Wizard" \
        --icon="dialog-error" \
        --urgency=critical \
        "❌ No Displays Detected" \
        "Could not detect any connected monitors via Hyprland." \
        -t 5000
    log "Error: No displays detected."
    exit 1
fi

log "Detected $NUM_MONITORS connected display(s)."

# Arrays to hold display metadata
declare -a PORTS=()
declare -a LABELS=()

for idx in $(seq 0 $((NUM_MONITORS - 1))); do
    port=$(echo "$MONITORS_JSON" | jq -r ".[$idx].name")
    desc=$(echo "$MONITORS_JSON" | jq -r ".[$idx].description // \"\"")
    make=$(echo "$MONITORS_JSON" | jq -r ".[$idx].make // \"\"")
    model=$(echo "$MONITORS_JSON" | jq -r ".[$idx].model // \"\"")
    label=$(clean_label "$port" "$desc" "$make" "$model")

    PORTS+=("$port")
    LABELS+=("$label")
done

# ------------------------------------------------------------------------------
# Step 2: Physical Alignment & Ordering (Left to Right)
# ------------------------------------------------------------------------------
declare -a ORDERED_PORTS=()
declare -a ORDERED_LABELS=()

if [ "$NUM_MONITORS" -eq 1 ]; then
    ORDERED_PORTS=("${PORTS[0]}")
    ORDERED_LABELS=("${LABELS[0]}")
elif [ "$NUM_MONITORS" -eq 2 ]; then
    PORT_A="${PORTS[0]}"
    LABEL_A="${LABELS[0]}"
    SHORT_A=$(short_name "$PORT_A" "$LABEL_A")

    PORT_B="${PORTS[1]}"
    LABEL_B="${LABELS[1]}"
    SHORT_B=$(short_name "$PORT_B" "$LABEL_B")

    OPT1="1. $SHORT_A on Left   ──   $SHORT_B on Right"
    OPT2="2. $SHORT_B on Left   ──   $SHORT_A on Right"

    ALIGN_SELECTION=$(echo -e "${OPT1}\n${OPT2}" | rofi -dmenu \
        -p "Desk Layout" \
        -theme "$ROFI_THEME" \
        -theme-str 'window { width: 850px; } entry { placeholder: "Select physical placement on your desk..."; }' \
        -mesg "Where are your screens placed on your desk? (from Left to Right)" \
        -i)

    [ -z "$ALIGN_SELECTION" ] && { log "Wizard cancelled at alignment."; exit 0; }

    if [[ "$ALIGN_SELECTION" =~ ^1\. ]]; then
        ORDERED_PORTS=("$PORT_A" "$PORT_B")
        ORDERED_LABELS=("$LABEL_A" "$LABEL_B")
    else
        ORDERED_PORTS=("$PORT_B" "$PORT_A")
        ORDERED_LABELS=("$LABEL_B" "$LABEL_A")
    fi
else
    # 3 or more displays: Stepwise Left-to-Right assignment
    declare -a REMAINING_PORTS=("${PORTS[@]}")
    declare -a REMAINING_LABELS=("${LABELS[@]}")

    for step in $(seq 1 "$NUM_MONITORS"); do
        MENU_ITEMS=""
        for r_idx in "${!REMAINING_PORTS[@]}"; do
            MENU_ITEMS="${MENU_ITEMS}${REMAINING_PORTS[$r_idx]} - ${REMAINING_LABELS[$r_idx]}\n"
        done

        SELECTED=$(echo -e "$MENU_ITEMS" | rofi -dmenu \
            -p "Position $step of $NUM_MONITORS" \
            -theme "$ROFI_THEME" \
            -theme-str 'window { width: 850px; } entry { placeholder: "Select display at this position..."; }' \
            -mesg "Select display for Position $step (leftmost ➔ rightmost):" \
            -i)

        [ -z "$SELECTED" ] && { log "Wizard cancelled at multi-monitor ordering."; exit 0; }

        SEL_PORT=$(echo "$SELECTED" | awk '{print $1}')
        SEL_LABEL=$(echo "$SELECTED" | sed 's/^[^ ]* - //')

        ORDERED_PORTS+=("$SEL_PORT")
        ORDERED_LABELS+=("$SEL_LABEL")

        # Remove chosen port from remaining
        NEW_REM_PORTS=()
        NEW_REM_LABELS=()
        for r_idx in "${!REMAINING_PORTS[@]}"; do
            if [ "${REMAINING_PORTS[$r_idx]}" != "$SEL_PORT" ]; then
                NEW_REM_PORTS+=("${REMAINING_PORTS[$r_idx]}")
                NEW_REM_LABELS+=("${REMAINING_LABELS[$r_idx]}")
            fi
        done
        REMAINING_PORTS=("${NEW_REM_PORTS[@]}")
        REMAINING_LABELS=("${NEW_REM_LABELS[@]}")
    done
fi

log "Ordered displays: ${ORDERED_PORTS[*]}"

# ------------------------------------------------------------------------------
# Step 3: Resolution & Anti-Blur Scale Selection
# ------------------------------------------------------------------------------
declare -a CHOSEN_W=()
declare -a CHOSEN_H=()
declare -a CHOSEN_HZ=()
declare -a CHOSEN_SCALE=()

for idx in $(seq 0 $((NUM_MONITORS - 1))); do
    port="${ORDERED_PORTS[$idx]}"
    label="${ORDERED_LABELS[$idx]}"

    # Extract available modes for this monitor
    MODES_JSON=$(echo "$MONITORS_JSON" | jq --arg p "$port" '
        .[] | select(.name == $p) |
        [
          .availableModes // [] | .[] |
          capture("(?<w>[0-9]+)x(?<h>[0-9]+)@(?<hz>[0-9.]+)Hz") |
          {w: (.w|tonumber), h: (.h|tonumber), res: "\(.w)x\(.h)", hz: (.hz|tonumber)}
        ] | group_by(.res) | map({
          res: .[0].res,
          w: .[0].w,
          h: .[0].h,
          max_hz: (map(.hz) | max)
        }) | sort_by(-.w, -.h, -.max_hz)
    ' 2>/dev/null)

    # Current fallback width/height from monitor object
    CURR_W=$(echo "$MONITORS_JSON" | jq --arg p "$port" '.[] | select(.name == $p) | .width // 1920')
    CURR_H=$(echo "$MONITORS_JSON" | jq --arg p "$port" '.[] | select(.name == $p) | .height // 1080')
    CURR_HZ=$(echo "$MONITORS_JSON" | jq --arg p "$port" '.[] | select(.name == $p) | (.refreshRate | floor) // 60')

    # Build resolution menu
    RES_MENU=""
    MODE_COUNT=$(echo "$MODES_JSON" | jq 'length' 2>/dev/null || echo 0)

    if [ "$MODE_COUNT" -gt 0 ]; then
        NATIVE_RES=$(echo "$MODES_JSON" | jq -r '.[0].res')
        NATIVE_HZ=$(echo "$MODES_JSON" | jq -r '.[0].max_hz | floor')

        RES_MENU="${NATIVE_RES}@${NATIVE_HZ}Hz  ★ (Recommended - Sharpest Native)\n"

        for m_idx in $(seq 1 $((MODE_COUNT - 1))); do
            [ "$m_idx" -ge 12 ] && break # Show top 12 resolutions
            r=$(echo "$MODES_JSON" | jq -r ".[$m_idx].res")
            hz=$(echo "$MODES_JSON" | jq -r ".[$m_idx].max_hz | floor")
            RES_MENU="${RES_MENU}${r}@${hz}Hz\n"
        done
    else
        RES_MENU="${CURR_W}x${CURR_H}@${CURR_HZ}Hz  ★ (Current/Native)\n"
    fi
    RES_MENU="${RES_MENU}Custom resolution..."

    STEP_NUM=$((idx + 1))
    SHORT_NAME=$(short_name "$port" "$label")

    RES_CHOICE=$(echo -e "$RES_MENU" | rofi -dmenu \
        -p "[$STEP_NUM/$NUM_MONITORS] $SHORT_NAME" \
        -theme "$ROFI_THEME" \
        -theme-str 'window { width: 900px; } entry { placeholder: "Select resolution..."; } textbox { text-color: #CDD6F4; font: "JetBrains Mono Nerd Font 13"; }' \
        -mesg "Configuring: $label ($port) — Screen $STEP_NUM of $NUM_MONITORS
Select resolution and refresh rate.
💡 Live Preview: After setup, you will test this layout live for 15s before saving." \
        -i)

    [ -z "$RES_CHOICE" ] && { log "Wizard cancelled at resolution selection for $port."; exit 0; }

    SELECTED_W=""
    SELECTED_H=""
    SELECTED_HZ=""

    if [[ "$RES_CHOICE" =~ Custom ]]; then
        CUSTOM_INPUT=$(rofi -dmenu \
            -p "Custom Mode: $SHORT_NAME" \
            -theme "$ROFI_THEME" \
            -theme-str 'window { width: 900px; }' \
            -filter "${CURR_W}x${CURR_H}@${CURR_HZ}" \
            -mesg "Enter custom mode for $SHORT_NAME formatted as WIDTHxHEIGHT@REFRESH (e.g. 2560x1440@60):" \
            -i)
        [ -z "$CUSTOM_INPUT" ] && { log "Wizard cancelled at custom resolution."; exit 0; }
        SELECTED_W=$(echo "$CUSTOM_INPUT" | sed -E 's/^([0-9]+)x([0-9]+)@?([0-9.]*).*$/\1/')
        SELECTED_H=$(echo "$CUSTOM_INPUT" | sed -E 's/^([0-9]+)x([0-9]+)@?([0-9.]*).*$/\2/')
        SELECTED_HZ=$(echo "$CUSTOM_INPUT" | sed -E 's/^([0-9]+)x([0-9]+)@?([0-9.]*).*$/\3/')
        [ -z "$SELECTED_HZ" ] && SELECTED_HZ="60"
    else
        SELECTED_RES=$(echo "$RES_CHOICE" | awk '{print $1}')
        SELECTED_W=$(echo "$SELECTED_RES" | cut -d'x' -f1)
        SELECTED_H=$(echo "$SELECTED_RES" | cut -d'x' -f2 | cut -d'@' -f1)
        SELECTED_HZ=$(echo "$SELECTED_RES" | cut -d'@' -f2 | sed 's/Hz//')
    fi

    [ -z "$SELECTED_W" ] && SELECTED_W=1920
    [ -z "$SELECTED_H" ] && SELECTED_H=1080
    [ -z "$SELECTED_HZ" ] && SELECTED_HZ=60

    # Scale / UI size selection based on anti-blur guidelines
    SCALE_MENU=""
    if [ "$SELECTED_W" -ge 3840 ]; then
        # 4K UHD
        SCALE_MENU="1.50  ★ (Recommended - 1440p UI size, Razor-Sharp Text)\n1.25    (More screen real estate, Balanced)\n1.75    (Larger UI / High Readability)\n1.00    (100% Native Unscaled - Tiny UI)\n2.00    (200% Integer Scale - 1080p UI size)\nCustom scale..."
    elif [ "$SELECTED_W" -ge 2560 ]; then
        # 1440p QHD / Ultrawide
        SCALE_MENU="1.00  ★ (Recommended - 100% Native Crisp)\n1.25    (Slightly larger UI)\n1.15    (Subtle enlargement)\nCustom scale..."
    else
        # 1080p FHD
        SCALE_MENU="1.00  ★ (Recommended - 100% Native 1:1 Pixel Mapping)\n1.25    (Slightly larger UI)\nCustom scale..."
    fi

    SCALE_CHOICE=$(echo -e "$SCALE_MENU" | rofi -dmenu \
        -p "Scale: $SHORT_NAME" \
        -theme "$ROFI_THEME" \
        -theme-str 'window { width: 900px; } entry { placeholder: "Select UI scaling factor..."; } textbox { text-color: #CDD6F4; font: "JetBrains Mono Nerd Font 13"; }' \
        -mesg "Configuring: $label ($port) at ${SELECTED_W}x${SELECTED_H}
Select text and UI size.
💡 Live Preview: After setup, you will test this layout live for 15s before saving." \
        -i)

    [ -z "$SCALE_CHOICE" ] && { log "Wizard cancelled at scale selection for $port."; exit 0; }

    SELECTED_SCALE=""
    if [[ "$SCALE_CHOICE" =~ Custom ]]; then
        CUSTOM_SCALE_INPUT=$(rofi -dmenu \
            -p "Custom Scale" \
            -theme "$ROFI_THEME" \
            -filter "1.33" \
            -mesg "Enter custom scale decimal factor (e.g. 1.20, 1.33, 1.50):" \
            -i)
        [ -z "$CUSTOM_SCALE_INPUT" ] && { log "Wizard cancelled at custom scale input."; exit 0; }
        SELECTED_SCALE=$(echo "$CUSTOM_SCALE_INPUT" | tr -cd '0-9.')
    else
        SELECTED_SCALE=$(echo "$SCALE_CHOICE" | awk '{print $1}')
    fi

    [ -z "$SELECTED_SCALE" ] && SELECTED_SCALE="1.00"

    CHOSEN_W+=("$SELECTED_W")
    CHOSEN_H+=("$SELECTED_H")
    CHOSEN_HZ+=("$SELECTED_HZ")
    CHOSEN_SCALE+=("$SELECTED_SCALE")

    log "Config for $port: ${SELECTED_W}x${SELECTED_H}@${SELECTED_HZ}Hz, Scale: $SELECTED_SCALE"
done

# ------------------------------------------------------------------------------
# Step 4: Automatic Logical Coordinate Math
# ------------------------------------------------------------------------------
# Hyprland coordinates are defined in logical space:
# Logical Width = Physical Width / Scale
declare -a POS_X=()
declare -a POS_Y=()

CURRENT_X=0

for idx in $(seq 0 $((NUM_MONITORS - 1))); do
    POS_X+=("$CURRENT_X")
    POS_Y+=("0")

    w="${CHOSEN_W[$idx]}"
    s="${CHOSEN_SCALE[$idx]}"
    # Calculate logical width rounded to nearest integer
    LOGICAL_W=$(awk -v w="$w" -v s="$s" 'BEGIN { printf "%d", (w / s) + 0.5 }')
    CURRENT_X=$((CURRENT_X + LOGICAL_W))
done

log "Computed logical coordinates:"
for idx in $(seq 0 $((NUM_MONITORS - 1))); do
    log "  ${ORDERED_PORTS[$idx]}: position=${POS_X[$idx]}x${POS_Y[$idx]}, size=${CHOSEN_W[$idx]}x${CHOSEN_H[$idx]}, scale=${CHOSEN_SCALE[$idx]}"
done

# ------------------------------------------------------------------------------
# Step 5: Live Preview with 15-Second Auto-Revert Safety Net
# ------------------------------------------------------------------------------
BACKUP_GEN="/tmp/hypr_monitors_backup_$$.conf"
PREVIEW_FILE="$CONFIG_DIR/.preview.conf"

if [ -f "$HOME/.config/hypr/monitors.gen.conf" ]; then
    cp "$HOME/.config/hypr/monitors.gen.conf" "$BACKUP_GEN"
fi

restore_previous_state() {
    log "Reverting monitor layout to previous working state..."
    if [ -f "$BACKUP_GEN" ]; then
        local target_src=$(grep -E "^source=" "$BACKUP_GEN" 2>/dev/null | cut -d= -f2- | sed "s|~|$HOME|" | xargs)
        if [ -n "$target_src" ] && [ -f "$target_src" ]; then
            cp "$BACKUP_GEN" "$HOME/.config/hypr/monitors.gen.conf"
        else
            echo "# Reverted to previous runtime state" > "$HOME/.config/hypr/monitors.gen.conf"
        fi
        rm -f "$BACKUP_GEN"
    else
        rm -f "$HOME/.config/hypr/monitors.gen.conf"
    fi

    rm -f "$PREVIEW_FILE" 2>/dev/null || true
    hyprctl reload
    hyprctl dismissnotify 10 2>/dev/null || true
}

# Trap unexpected termination during preview
trap 'restore_previous_state' INT TERM

# Build preview monitor configuration lines
PREVIEW_CONF_LINES=""
for idx in $(seq 0 $((NUM_MONITORS - 1))); do
    p="${ORDERED_PORTS[$idx]}"
    res="${CHOSEN_W[$idx]}x${CHOSEN_H[$idx]}"
    hz="${CHOSEN_HZ[$idx]}"
    pos="${POS_X[$idx]}x${POS_Y[$idx]}"
    sc="${CHOSEN_SCALE[$idx]}"
    label="${ORDERED_LABELS[$idx]}"

    PREVIEW_CONF_LINES="${PREVIEW_CONF_LINES}# $label ($p)
monitor = $p, $res@$hz, $pos, $sc
"
done

# Write temporary preview file and reload Hyprland atomically
cat > "$PREVIEW_FILE" << PREVIEW_EOF
# Description: Temporary Preview created by Monitor Setup Wizard
$PREVIEW_CONF_LINES
PREVIEW_EOF

log "Applying live preview layout atomically via .preview.conf..."
echo "source=$PREVIEW_FILE" > "$HOME/.config/hypr/monitors.gen.conf"
hyprctl reload
hyprctl dismissnotify 10 2>/dev/null || true

notify-send \
    --app-name="Monitor Wizard" \
    --icon="video-display" \
    --urgency=normal \
    "🖥️ Live Preview Active" \
    "Testing new layout. Please confirm within 15 seconds." \
    -t 5000

# 15-second background watchdog timer
(
    sleep 15
    pkill -f "rofi.*Confirm New Layout" 2>/dev/null || true
) &
WATCHDOG_PID=$!

CONFIRM_RESULT=$(echo -e "✓ Keep Configuration (Save & Apply)\n✗ Revert to Previous Settings" | rofi -dmenu \
    -p "Preview Active" \
    -theme "$CONFIRM_THEME" \
    -theme-str 'window { width: 850px; } textbox { text-color: #CDD6F4; font: "JetBrains Mono Nerd Font 13"; }' \
    -mesg "🖥️  Live Preview Active (Auto-reverting in 15 seconds)
Move your mouse across screens to test alignment and text clarity.
Click 'Keep Configuration' to save, or wait/revert to cancel." \
    -title "Confirm New Layout" \
    -i || true)

kill $WATCHDOG_PID 2>/dev/null || true
wait $WATCHDOG_PID 2>/dev/null || true

if [[ ! "$CONFIRM_RESULT" =~ Keep ]]; then
    restore_previous_state
    notify-send \
        --app-name="Monitor Wizard" \
        --icon="dialog-warning" \
        --urgency=normal \
        "↩ Layout Reverted" \
        "Monitor configuration restored to previous settings." \
        -t 4000
    log "User reverted layout or timer expired."
    exit 0
fi

log "User confirmed new layout."

# ------------------------------------------------------------------------------
# Step 6: Workspace Allocation & Profile Generation
# ------------------------------------------------------------------------------
# Generate smart default profile name based on hardware (or use TARGET_PROFILE if editing)
DEFAULT_NAME="$TARGET_PROFILE"
if [ -z "$DEFAULT_NAME" ]; then
    PRIMARY_MODEL=$(echo "${ORDERED_LABELS[0]}" | sed 's/^[^a-zA-Z0-9]*//' | awk '{print $1}' | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')
    [ -z "$PRIMARY_MODEL" ] && PRIMARY_MODEL="display"

    if [ "$NUM_MONITORS" -eq 1 ]; then
        DEFAULT_NAME="${PRIMARY_MODEL}-single"
    elif [ "$NUM_MONITORS" -eq 2 ]; then
        DEFAULT_NAME="${PRIMARY_MODEL}-dual"
    else
        DEFAULT_NAME="${PRIMARY_MODEL}-${NUM_MONITORS}-screens"
    fi
fi

PROFILE_INPUT=$(echo "$DEFAULT_NAME" | rofi -dmenu \
    -p "Profile Name" \
    -theme "$ROFI_THEME" \
    -theme-str 'window { width: 850px; } entry { placeholder: "Enter profile name (press Enter for default)..."; }' \
    -filter "$DEFAULT_NAME" \
    -mesg "Enter a name to save this monitor configuration:" \
    -i)

ROFI_EXIT=$?
if [ "$ROFI_EXIT" -ne 0 ] || [ -z "$PROFILE_INPUT" ]; then
    log "Profile naming cancelled by user (exit code $ROFI_EXIT). Reverting..."
    restore_previous_state
    notify-send \
        --app-name="Monitor Wizard" \
        --icon="dialog-warning" \
        --urgency=normal \
        "↩ Save Cancelled" \
        "Profile was not saved. Restored previous monitor settings." \
        -t 4000
    exit 0
fi

PROFILE_NAME=$(echo "$PROFILE_INPUT" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9_-')
[ -z "$PROFILE_NAME" ] && PROFILE_NAME="$DEFAULT_NAME"

PROFILE_FILE="$CONFIG_DIR/$PROFILE_NAME.conf"

# Generate monitor configuration lines
MONITOR_CONF_LINES=""
for idx in $(seq 0 $((NUM_MONITORS - 1))); do
    p="${ORDERED_PORTS[$idx]}"
    res="${CHOSEN_W[$idx]}x${CHOSEN_H[$idx]}"
    hz="${CHOSEN_HZ[$idx]}"
    pos="${POS_X[$idx]}x${POS_Y[$idx]}"
    sc="${CHOSEN_SCALE[$idx]}"
    label="${ORDERED_LABELS[$idx]}"
    MONITOR_CONF_LINES="${MONITOR_CONF_LINES}# $label ($p)
monitor = $p, $res@$hz, $pos, $sc
"
done

# Generate round-robin workspace assignments for workspaces 1-9
WORKSPACE_CONF_LINES=""
for ws in {1..9}; do
    mon_idx=$(( (ws - 1) % NUM_MONITORS ))
    target_p="${ORDERED_PORTS[$mon_idx]}"
    WORKSPACE_CONF_LINES="${WORKSPACE_CONF_LINES}workspace=${ws},monitor:${target_p}
"
done

# Write the profile file
cat > "$PROFILE_FILE" << PROFILE_EOF
# Description: Custom profile created by Monitor Setup Wizard on $(date)
# Fingerprint: $(get_monitor_fingerprint)

# --- Monitor Configuration ---
# Configured with anti-blur fractional scaling and logical coordinate math:
$MONITOR_CONF_LINES
# --- Workspace Assignments ---
# Round-robin distribution for 9 workspaces
$WORKSPACE_CONF_LINES
# --- Additional Rules ---
# Add any window rules or special configurations here

PROFILE_EOF

log "Profile saved to $PROFILE_FILE"

# Apply profile permanently and cache fingerprint
if [ -n "$PROFILE_FILE" ] && [ -f "$PROFILE_FILE" ]; then
    echo "source=$PROFILE_FILE" > "$HOME/.config/hypr/monitors.gen.conf"
    save_to_cache "$PROFILE_NAME"
    hyprctl reload
    hyprctl dismissnotify 10 2>/dev/null || true

    # Safe to clean up preview file and backup now that final profile is active
    trap - INT TERM
    rm -f "$PREVIEW_FILE" "$BACKUP_GEN" 2>/dev/null || true
else
    log "Error: Target profile file '$PROFILE_FILE' was not generated properly."
    restore_previous_state
    exit 1
fi

notify-send \
    --app-name="Monitor Wizard" \
    --icon="video-display" \
    --urgency=normal \
    "🎉 Profile '$PROFILE_NAME' Active!" \
    "Layout saved and cached for automatic hardware detection." \
    -t 5000

log "Monitor Wizard completed successfully for '$PROFILE_NAME'."
