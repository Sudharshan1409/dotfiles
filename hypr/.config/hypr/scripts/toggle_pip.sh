#!/bin/bash
# Smart Picture-in-Picture (PiP) toggle for the focused window in Hyprland

WINDOW_INFO=$(hyprctl activewindow -j 2>/dev/null)
if [ -z "$WINDOW_INFO" ] || [ "$WINDOW_INFO" = "{}" ]; then
    notify-send "PiP Mode" "No active window found" -u low -t 2000
    exit 0
fi

ADDRESS=$(echo "$WINDOW_INFO" | jq -r '.address')
FLOATING=$(echo "$WINDOW_INFO" | jq -r '.floating')
PINNED=$(echo "$WINDOW_INFO" | jq -r '.pinned')

if [ "$PINNED" = "true" ]; then
    # Currently in PiP mode: restore to normal tiling
    hyprctl dispatch pin address:$ADDRESS >/dev/null 2>&1
    hyprctl dispatch togglefloating address:$ADDRESS >/dev/null 2>&1
    notify-send "PiP Mode" "Window restored to normal tiling" -i window-restore -t 2000
else
    # Enable PiP mode
    # 1. Float the window if not already floating
    if [ "$FLOATING" != "true" ]; then
        hyprctl dispatch togglefloating address:$ADDRESS >/dev/null 2>&1
    fi

    # 2. Pin the window across all workspaces
    hyprctl dispatch pin address:$ADDRESS >/dev/null 2>&1

    # 3. Calculate target position on active monitor
    MONITOR_INFO=$(hyprctl monitors -j 2>/dev/null | jq '.[] | select(.focused == true)')
    if [ -z "$MONITOR_INFO" ]; then
        MONITOR_INFO=$(hyprctl monitors -j 2>/dev/null | jq '.[0]')
    fi

    MON_X=$(echo "$MONITOR_INFO" | jq -r '.x // 0')
    MON_Y=$(echo "$MONITOR_INFO" | jq -r '.y // 0')
    MON_W=$(echo "$MONITOR_INFO" | jq -r '.width // 1920')
    MON_H=$(echo "$MONITOR_INFO" | jq -r '.height // 1080')
    SCALE=$(echo "$MONITOR_INFO" | jq -r '.scale // 1')

    # Convert to logical dimensions
    LOGICAL_W=$(python3 -c "import sys; print(int(float(sys.argv[1]) / float(sys.argv[2])))" "$MON_W" "$SCALE" 2>/dev/null || echo 1920)
    LOGICAL_H=$(python3 -c "import sys; print(int(float(sys.argv[1]) / float(sys.argv[2])))" "$MON_H" "$SCALE" 2>/dev/null || echo 1080)

    # 16:9 ratio, roughly 22% of screen width (min 420px, max 640px)
    PIP_W=$(( LOGICAL_W * 22 / 100 ))
    [ "$PIP_W" -lt 420 ] && PIP_W=420
    [ "$PIP_W" -gt 640 ] && PIP_W=640
    PIP_H=$(( PIP_W * 9 / 16 ))

    # Dock in bottom-right corner with 24px right margin and 64px bottom margin (clearing Waybar)
    TARGET_X=$(( MON_X + LOGICAL_W - PIP_W - 24 ))
    TARGET_Y=$(( MON_Y + LOGICAL_H - PIP_H - 64 ))

    hyprctl dispatch resizewindowpixel exact ${PIP_W} ${PIP_H},address:$ADDRESS >/dev/null 2>&1
    hyprctl dispatch movewindowpixel exact ${TARGET_X} ${TARGET_Y},address:$ADDRESS >/dev/null 2>&1

    TITLE=$(echo "$WINDOW_INFO" | jq -r '.title // "Window"')
    notify-send "PiP Mode" "Pinned '${TITLE:0:30}' to Picture-in-Picture" -i view-paged -t 2000
fi
