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
    WALLPAPERS=($(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -not -name "$LINK_NAME"))

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

    # --- APPLY THE NEW WALLPAPER (CACHE-BUSTING METHOD) ---
    ln -sf "$RANDOM_WALLPAPER" "$CURRENT_WALLPAPER_LINK"

    # 1. CRITICAL STEP: Unload the 'current.png' path to clear hyprpaper's cache.
    hyprctl hyprpaper unload "$CURRENT_WALLPAPER_LINK"

    # 2. Preload the new image that the link now points to.
    hyprctl hyprpaper preload "$CURRENT_WALLPAPER_LINK"

    # 3. Set the preloaded wallpaper.
    hyprctl hyprpaper wallpaper ",$CURRENT_WALLPAPER_LINK"

    # 4. Save the history.
    echo "$RANDOM_WALLPAPER" > "$HISTORY_FILE"
    echo "Wallpaper successfully set to: $RANDOM_WALLPAPER"

) 200>"$LOCK_FILE"
