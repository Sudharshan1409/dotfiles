#!/bin/bash

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Memory Usage by Application (macOS):"
    ps -axo %mem,pid,comm | sort -nr | head -10 | awk '{print $2, $1, $3}' | while read pid mem process; do
        app_name=$(basename "$process") # Extract only the application name
        [[ -z "$app_name" ]] && app_name="Unknown"
        printf "PID: %s | Memory: %s%% | Process: %s\n" "$pid" "$mem" "$app_name"
    done
else
    echo "Memory Usage by Application (Linux):"
    ps -eo pid,%mem,comm --sort=-%mem | head -11 | awk '{print $1, $2, $3}' | while read pid mem process; do
        app_name=$(basename "$process") # Extract only the application name
        [[ -z "$app_name" ]] && app_name="Unknown"
        printf "PID: %s | Memory: %s%% | Process: %s\n" "$pid" "$mem" "$app_name"
    done
fi

