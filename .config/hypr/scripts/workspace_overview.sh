#!/bin/bash

# Workspace Overview
# Shows all workspaces with their windows in a rofi menu
# Press Super+Tab to activate

# Get workspace info from hyprctl
workspaces=$(hyprctl workspaces -j | jq -r '.[] | "\(.id): \(.windows) windows"' | sort -t: -k1 -n)

# Get all windows with their workspace
windows=$(hyprctl clients -j | jq -r '.[] | select(.workspace.id > 0) | "[\(.workspace.id)] \(.title)"' | sort)

# Show rofi menu
selected=$(echo -e "${windows}" | rofi -dmenu \
    -p "Workspaces" \
    -theme ~/.config/rofi/workspace-overview.rasi \
    -i)

# If selection made, switch to that workspace
if [ -n "$selected" ]; then
    # Extract workspace ID from selection (format: [ID] title)
    workspace_id=$(echo "$selected" | grep -oE '^\[[0-9]+\]' | tr -d '[]')
    if [ -n "$workspace_id" ]; then
        hyprctl dispatch workspace "$workspace_id"
    fi
fi
