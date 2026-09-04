#!/bin/bash

# Set the maximum volume limit
MAX_VOLUME=153

case $1 in
    up)
        # Get current volume and calculate the new target
        current=$(pamixer --get-volume)
        new=$((current + 5))

        # Cap the volume at the max limit
        if [ "$new" -gt "$MAX_VOLUME" ]; then
            pamixer --allow-boost --set-volume $MAX_VOLUME
        else
            # Otherwise, just increase by 5
            pamixer --allow-boost -i 5
        fi
        ;;
    down)
        # Get current volume
        current=$(pamixer --get-volume)

        # THIS IS THE FIX: Handle boosted volume differently
        if [ "$current" -gt 100 ]; then
            # Manually set the volume to ensure a smooth decrease
            new_volume=$((current - 5))
            pamixer --allow-boost --set-volume $new_volume
        else
            # In the normal range, the standard command is fine
            pamixer -d 5
        fi
        ;;
esac
