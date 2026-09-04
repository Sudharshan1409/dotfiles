#!/bin/bash
# Workspace Overview
# Shows all workspaces with their windows in a rofi menu
# Press Super+Tab to activate

# Get workspace info from hyprctl
# Using `hyprctl workspaces` is good for getting active workspaces
# Using `hyprctl clients` is good for getting windows
# We want to group windows by workspace

# Get all windows with their workspace ID and Title
# Format: "[ID] Title"
windows=$(hyprctl clients -j | jq -r '.[] | select(.workspace.id > 0) | "[\(.workspace.id)] \(.title)"' | sort -n)

# Show rofi menu
selected=$(echo "$windows" | rofi -dmenu \
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
