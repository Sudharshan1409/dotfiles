#!/bin/bash

active_window_info=$(hyprctl activewindow -j)
active_window_class=$(echo "$active_window_info" | grep '"class":' | awk -F '"' '{print $4}')

if [ "$active_window_class" = "kitty" ]; then
    active_window_pid=$(echo "$active_window_info" | grep '"pid":' | awk -F ': ' '{print $2}' | sed 's/,//')
    # Hyprland may return the PID of the parent process, not the shell.
    # We need to find the child process (the shell) to get the correct CWD.
    shell_pids=$(pgrep -P "$active_window_pid")

    for pid in $shell_pids; do
        cwd=$(readlink "/proc/$pid/cwd")
        if [ "$cwd" != "/home/enigma" ]; then
            kitty --directory "$cwd" &
            exit 0
        fi
    done

    # If no better CWD was found, open in home.
    kitty &
else
    kitty &
fi