#!/bin/bash

if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" == "arch" || "$ID_LIKE" == "arch" ]]; then
        blueberry &
    elif [[ "$ID" == "ubuntu" ]]; then
        blueman-manager &
    else
        # Default fallback
        blueman-manager &
    fi
else
    # Default fallback
    blueman-manager &
fi
