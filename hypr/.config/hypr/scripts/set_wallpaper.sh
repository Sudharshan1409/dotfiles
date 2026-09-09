#!/bin/bash

# --- ATOMIC LOCKING MECHANISM using flock ---
LOCK_FILE="/tmp/wallpaper.lock"
(
    flock -n 200 || exit 1

    # --- SCRIPT LOGIC ---
    if [ "$1" == "--init" ]; then
        sleep 2
    fi

    # --- CONFIGURATION ---
    WALLPAPER_DIR=$(readlink -f "$HOME/.config/backgrounds")
    LINK_NAME="current.png"
    CURRENT_WALLPAPER_LINK="$WALLPAPER_DIR/$LINK_NAME"
    HISTORY_FILE="/tmp/wallpaper.history"

    # --- WALLPAPER SELECTION ---
    mapfile -d '' WALLPAPERS < <(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -not -name "$LINK_NAME" -print0)

    if [ ${#WALLPAPERS[@]} -eq 0 ]; then
        echo "Error: No wallpapers found in $WALLPAPER_DIR"
        exit 1
    fi

    LAST_WALLPAPER=$(cat "$HISTORY_FILE" 2>/dev/null)
    RANDOM_WALLPAPER="${WALLPAPERS[RANDOM % ${#WALLPAPERS[@]}]}"

    if [ ${#WALLPAPERS[@]} -gt 1 ]; then
        while [ "$RANDOM_WALLPAPER" == "$LAST_WALLPAPER" ]; do
            RANDOM_WALLPAPER="${WALLPAPERS[RANDOM % ${#WALLPAPERS[@]}]}"
        done
    fi

    # --- APPLY THE NEW WALLPAPER ---
    ln -sf "$RANDOM_WALLPAPER" "$CURRENT_WALLPAPER_LINK"

    # Prefer swww for GPU-accelerated smooth transitions (wipe, wave, outer, grow, etc.)
    if command -v swww >/dev/null 2>&1; then
        if ! pgrep -x swww-daemon >/dev/null 2>&1; then
            swww-daemon &
            sleep 0.5
        fi
        TRANSITIONS=("wipe" "wave" "outer" "grow" "center" "any")
        RANDOM_TRANS="${TRANSITIONS[RANDOM % ${#TRANSITIONS[@]}]}"
        swww img "$RANDOM_WALLPAPER" \
            --transition-type "$RANDOM_TRANS" \
            --transition-step 90 \
            --transition-fps 60 \
            --transition-angle 30 \
            --transition-duration 1.2 2>/dev/null || \
        swww img "$RANDOM_WALLPAPER" 2>/dev/null
    elif command -v hyprctl >/dev/null 2>&1 && pgrep -x hyprpaper >/dev/null 2>&1; then
        # Fallback to hyprpaper: apply actual image path to all active monitors
        if command -v jq >/dev/null 2>&1; then
            MONITORS=$(hyprctl monitors -j 2>/dev/null | jq -r '.[].name' 2>/dev/null)
        else
            MONITORS=$(hyprctl monitors 2>/dev/null | awk '/Monitor/{print $2}')
        fi
        for mon in $MONITORS; do
            hyprctl hyprpaper wallpaper "$mon,$RANDOM_WALLPAPER" 2>/dev/null || true
        done
        hyprctl hyprpaper wallpaper ",$RANDOM_WALLPAPER" 2>/dev/null || true
    fi

    # Save the history
    echo "$RANDOM_WALLPAPER" > "$HISTORY_FILE"
    echo "Wallpaper successfully set to: $RANDOM_WALLPAPER"

    # Send visual confirmation notification
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -i "$CURRENT_WALLPAPER_LINK" -a "Wallpaper" "Wallpaper Updated" "$(basename "$RANDOM_WALLPAPER")" -t 2500 2>/dev/null || true
    fi

) 200>"$LOCK_FILE"
