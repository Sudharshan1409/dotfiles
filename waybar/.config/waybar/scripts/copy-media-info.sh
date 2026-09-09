#!/usr/bin/env bash

# Fetch current media title and artist
TITLE=$(playerctl metadata --format '{{title}}' 2>/dev/null)
ARTIST=$(playerctl metadata --format '{{artist}}' 2>/dev/null)

if [ -z "$TITLE" ] && [ -z "$ARTIST" ]; then
    notify-send -a "Media" -u low "No Media" "No active media track playing" -t 2000
    exit 0
fi

if [ -n "$ARTIST" ] && [ -n "$TITLE" ]; then
    TRACK_INFO="$ARTIST - $TITLE"
elif [ -n "$TITLE" ]; then
    TRACK_INFO="$TITLE"
else
    TRACK_INFO="$ARTIST"
fi

echo -n "$TRACK_INFO" | wl-copy
notify-send -a "Media" "Copied to Clipboard" "$TRACK_INFO" -t 2500
