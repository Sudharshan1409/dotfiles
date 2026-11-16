#!/bin/bash

# Get the list of items from cliphist
items=$(cliphist list)

# Create a help message with the keybindings
help_message="<span size='small' style='italic'><b>Alt+d</b>: Clear all history</span>"

# Check if the clipboard is empty
if [ -z "$items" ]; then
  rofi -dmenu -i -l 0 -p "Clipboard" -theme ~/.config/rofi/clipboard-elegant.rasi -mesg "Clipboard history is empty" -markup -input /dev/null
  exit 0
fi

# Show the Rofi menu and get the selected item and keybinding
selection=$(echo "$items" | rofi -dmenu -i -l 20 -p "Clipboard" -theme ~/.config/rofi/clipboard-elegant.rasi -kb-custom-1 'Alt+d' -format 's' -mesg "$help_message" -markup)
rofi_exit_code=$?

# Check which key was pressed
case "$rofi_exit_code" in
  0) 
    # Entry selected, decode and copy
    echo "$selection" | cliphist decode | wl-copy
    ;; 
  1) 
    # Cancelled
    exit 0
    ;; 
  10) 
    # Custom keybinding 1 (Alt+d)
    # Ask for confirmation
    confirm=$(echo -e "Yes\nNo" | rofi -dmenu -i -p "Confirmation" -mesg "Are you sure you want to clear all history?" -theme ~/.config/rofi/confirmation.rasi -no-search)
    if [ "$confirm" = "Yes" ]; then
      cliphist wipe
      notify-send \
        --app-name="Clipboard Manager" \
        --icon="edit-clear" \
        --urgency=normal \
        "🗑️  Clipboard Cleared" \
        "All clipboard history has been\nsuccessfully wiped clean." \
        -t 4000
    fi
    ;; 
esac