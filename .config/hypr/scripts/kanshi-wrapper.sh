#!/bin/bash
# kanshi-wrapper.sh - Keeps kanshi running and restarts it on crash
#
# This is needed because kanshi can crash with "invalid object" errors
# when monitors are hotplugged due to Wayland race conditions.

RESTART_DELAY=2

# Ensure only one instance runs
exec 200>/tmp/kanshi-wrapper.lock
flock -n 200 || { echo "kanshi-wrapper already running"; exit 1; }

cleanup() {
    pkill -P $$ kanshi 2>/dev/null
    exit 0
}

trap cleanup SIGINT SIGTERM

while true; do
    echo "[kanshi-wrapper] Starting kanshi..."
    kanshi 2>&1 &
    KANSHI_PID=$!
    
    # Wait for kanshi to exit
    wait $KANSHI_PID
    EXIT_CODE=$?
    
    if [[ $EXIT_CODE -ne 0 ]]; then
        echo "[kanshi-wrapper] kanshi crashed (exit code: $EXIT_CODE), restarting in ${RESTART_DELAY}s..."
        sleep $RESTART_DELAY
    else
        echo "[kanshi-wrapper] kanshi exited normally, restarting in ${RESTART_DELAY}s..."
        sleep $RESTART_DELAY
    fi
done
