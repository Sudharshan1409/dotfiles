#!/bin/bash

# Emits JSON for the waybar recording-indicator module.
# When wf-recorder is active: shows elapsed time + pulses red.
# When idle: empty text with class "idle" so CSS collapses it.

pid=$(pgrep -x wf-recorder | head -n1)

if [ -z "$pid" ]; then
    echo '{"text":"","tooltip":"","class":"idle"}'
    exit 0
fi

# Elapsed time of the wf-recorder process (e.g. 00:42 or 01:23:05)
elapsed=$(ps -o etime= -p "$pid" 2>/dev/null | tr -d ' ')

# Latest recording file for the tooltip
latest=$(ls -t "$HOME/Videos/Recordings"/*.mp4 2>/dev/null | head -1)
if [ -n "$latest" ]; then
    filename=$(basename "$latest")
else
    filename="(file pending)"
fi

tooltip="<b>🔴 Recording in progress</b>\nElapsed: ${elapsed}\nFile: ${filename}\n\nClick to stop • Right-click to open folder"

printf '{"text":"● REC %s","tooltip":"%s","class":"recording"}\n' "$elapsed" "$tooltip"
