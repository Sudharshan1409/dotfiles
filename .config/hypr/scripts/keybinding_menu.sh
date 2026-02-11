#!/bin/bash

# =============================================================================
# Keybinding Help Menu for Hyprland
# Interactive searchable menu showing all keyboard shortcuts
# =============================================================================

ROFI_THEME="$HOME/.config/rofi/keybindings.rasi"

# Create temp file with menu items
TEMP_FILE=$(mktemp)

cat > "$TEMP_FILE" << 'EOF'
📱 APPS | Super + Enter | Open terminal (Ghostty)
📱 APPS | Super + Space | Open application launcher (Rofi)
📱 APPS | Super + Alt + S | Open Spotify
📱 APPS | Super + Alt + D | Open Downloads folder
📱 APPS | Super + Alt + B | Open Backgrounds folder
📱 APPS | Super + Alt + W | Open Wezterm wallpapers folder
📱 APPS | Super + Alt + H | Open Home folder
📱 APPS | Super + Ctrl + V | Open clipboard history
📱 APPS | Super + Ctrl + B | Open Bluetooth menu
📱 APPS | Super + Ctrl + N | Open notification center
📱 APPS | Super + Ctrl + Tab | Show workspace overview
📱 APPS | Super + ` | Show workspace overview (alternate)
⚙️ SYSTEM | Super + Ctrl + M | Exit Hyprland session
⚙️ SYSTEM | Super + Ctrl + R | Reload Hyprland configuration
⚙️ SYSTEM | Super + Ctrl + L | Lock the screen
⚙️ SYSTEM | Super + Ctrl + S | Suspend the system
⚙️ SYSTEM | Super + Ctrl + H | Toggle screen lock on idle
⚙️ SYSTEM | Super + Ctrl + X | Open power menu
⚙️ SYSTEM | Super + Ctrl + W | Change to random wallpaper
⚙️ SYSTEM | Super + Ctrl + D | Open monitor profile manager
⚙️ SYSTEM | Super + Ctrl + Shift + D | Auto-apply monitor profile
⚙️ SYSTEM | Super + Shift + T | Extract text from screen (OCR)
⚙️ SYSTEM | Super + / | Open keybinding help menu
⚙️ SYSTEM | Super + Shift + ? | App-specific shortcuts help
🔧 UTILS | Super + Alt + C | Open calculator
🔧 UTILS | Super + Alt + P | Kill a process
🔧 UTILS | Super + Alt + A | Audio device switcher
🪟 WINDOWS | Super + C | Close active window
🪟 WINDOWS | Super + V | Toggle floating mode
🪟 WINDOWS | Super + F | Toggle fullscreen mode
🪟 WINDOWS | Super + P | Toggle pseudotiling mode
🪟 WINDOWS | Super + T | Toggle split direction (vertical/horizontal)
🪟 WINDOWS | Super + W | Toggle window group
🪟 WINDOWS | Super + Shift + H | Move window left
🪟 WINDOWS | Super + Shift + J | Move window down
🪟 WINDOWS | Super + Shift + K | Move window up
🪟 WINDOWS | Super + Shift + L | Move window right
🪟 WINDOWS | Super + Alt + H | Resize window left (make narrower)
🪟 WINDOWS | Super + Alt + J | Resize window down (make shorter)
🪟 WINDOWS | Super + Alt + K | Resize window up (make taller)
🪟 WINDOWS | Super + Alt + L | Resize window right (make wider)
🧭 NAVIGATION | Super + H | Move focus left
🧭 NAVIGATION | Super + J | Move focus down
🧭 NAVIGATION | Super + K | Move focus up
🧭 NAVIGATION | Super + L | Move focus right
🧭 NAVIGATION | Super + Mouse Left Drag | Move window
🧭 NAVIGATION | Super + Mouse Right Drag | Resize window
🗂️ WORKSPACES | Super + 1 | Switch to workspace 1
🗂️ WORKSPACES | Super + 2 | Switch to workspace 2
🗂️ WORKSPACES | Super + 3 | Switch to workspace 3
🗂️ WORKSPACES | Super + 4 | Switch to workspace 4
🗂️ WORKSPACES | Super + 5 | Switch to workspace 5
🗂️ WORKSPACES | Super + 6 | Switch to workspace 6
🗂️ WORKSPACES | Super + 7 | Switch to workspace 7
🗂️ WORKSPACES | Super + 8 | Switch to workspace 8
🗂️ WORKSPACES | Super + 9 | Switch to workspace 9
🗂️ WORKSPACES | Super + 0 | Switch to workspace 10
🗂️ WORKSPACES | Super + Shift + 1 | Move window to workspace 1
🗂️ WORKSPACES | Super + Shift + 2 | Move window to workspace 2
🗂️ WORKSPACES | Super + Shift + 3 | Move window to workspace 3
🗂️ WORKSPACES | Super + Shift + 4 | Move window to workspace 4
🗂️ WORKSPACES | Super + Shift + 5 | Move window to workspace 5
🗂️ WORKSPACES | Super + Shift + 6 | Move window to workspace 6
🗂️ WORKSPACES | Super + Shift + 7 | Move window to workspace 7
🗂️ WORKSPACES | Super + Shift + 8 | Move window to workspace 8
🗂️ WORKSPACES | Super + Shift + 9 | Move window to workspace 9
🗂️ WORKSPACES | Super + Shift + 0 | Move window to workspace 10
🗂️ WORKSPACES | Super + Mouse Scroll Down | Next workspace
🗂️ WORKSPACES | Super + Mouse Scroll Up | Previous workspace
🗂️ WORKSPACES | Super + M | Toggle Magic workspace (special)
🗂️ WORKSPACES | Super + Shift + M | Send to Magic workspace
🗂️ WORKSPACES | Super + A | Toggle Ad-Hoc workspace (special)
🗂️ WORKSPACES | Super + Shift + A | Send to Ad-Hoc workspace
🗂️ WORKSPACES | Super + E | Toggle Entertainment workspace (special)
🗂️ WORKSPACES | Super + Shift + E | Send to Entertainment workspace
📦 GROUPS | Super + G | Toggle/create window group
📦 GROUPS | Super + Tab | Switch to next window in group
📦 GROUPS | Super + Shift + Tab | Switch to previous window in group
📦 GROUPS | Super + Shift + G | Lock/unlock group (prevent grouping)
🎵 MEDIA | Volume Up | Increase volume
🎵 MEDIA | Volume Down | Decrease volume
🎵 MEDIA | Mute | Toggle mute
🎵 MEDIA | Play/Pause | Toggle media playback
🎵 MEDIA | Next Track | Skip to next track
🎵 MEDIA | Previous Track | Go to previous track
🎵 MEDIA | Brightness Up | Increase screen brightness
🎵 MEDIA | Brightness Down | Decrease screen brightness
📸 SCREENSHOTS | Print | Screenshot active monitor
📸 SCREENSHOTS | Super + Print | Screenshot active window
📸 SCREENSHOTS | Super + Shift + Print | Screenshot selected region
⌨️ INPUT | Super + C | Universal copy
⌨️ INPUT | Super + V | Universal paste
⌨️ INPUT | Super + X | Universal cut
EOF

# Show rofi menu with the temp file
SELECTED=$(cat "$TEMP_FILE" | rofi -dmenu \
    -p "Keybindings" \
    -theme "$ROFI_THEME" \
    -i \
    -no-custom \
    -mesg "Type to search | Press Enter to execute" 2>/dev/null)

# Clean up temp file
rm -f "$TEMP_FILE"

# Check if user made a selection
if [ -z "$SELECTED" ]; then
    exit 0
fi

# Extract keybinding and description
CATEGORY=$(echo "$SELECTED" | cut -d'|' -f1 | xargs)
KEY=$(echo "$SELECTED" | cut -d'|' -f2 | xargs)
DESCRIPTION=$(echo "$SELECTED" | cut -d'|' -f3 | xargs)

# Execute based on description match
case "$DESCRIPTION" in
    "Open terminal (Ghostty)")
        hyprctl dispatch exec ghostty ;;
    "Open application launcher (Rofi)")
        hyprctl dispatch exec "rofi -show drun -show-icons -display-drune 'Apps' -theme ~/.config/rofi/launcher-elegant.rasi" ;;
    "Open Spotify")
        hyprctl dispatch exec spotify ;;
    "Open Downloads folder")
        hyprctl dispatch exec "nautilus ~/Downloads" ;;
    "Open Backgrounds folder")
        hyprctl dispatch exec "nautilus ~/.config/backgrounds" ;;
    "Open Wezterm wallpapers folder")
        hyprctl dispatch exec "nautilus ~/wezterm-wallpapers" ;;
    "Open Home folder")
        hyprctl dispatch exec "nautilus ~" ;;
    "Open clipboard history")
        hyprctl dispatch exec ~/.config/hypr/scripts/clipboard.sh ;;
    "Open Bluetooth menu")
        hyprctl dispatch exec ~/.config/waybar/scripts/launch_bluetooth.sh ;;
    "Open notification center")
        hyprctl dispatch exec ~/.config/waybar/scripts/swaync-client.sh ;;
    "Show workspace overview")
        hyprctl dispatch exec ~/.config/hypr/scripts/workspace_overview.sh ;;
    "Show workspace overview (alternate)")
        hyprctl dispatch exec ~/.config/hypr/scripts/workspace_overview.sh ;;
    "Exit Hyprland session")
        hyprctl dispatch exit ;;
    "Reload Hyprland configuration")
        hyprctl dispatch exec "hyprctl reload && notify-send -i 'dialog-information' -a 'Hyprland' 'Hyprland' 'Config reloaded successfully!'" ;;
    "Lock the screen")
        hyprctl dispatch exec hyprlock ;;
    "Suspend the system")
        hyprctl dispatch exec "systemctl suspend" ;;
    "Toggle screen lock on idle")
        hyprctl dispatch exec ~/.config/hypr/scripts/toggle_hypridle.sh ;;
    "Open power menu")
        hyprctl dispatch exec ~/.config/waybar/scripts/power-menu.sh ;;
    "Change to random wallpaper")
        hyprctl dispatch exec ~/.config/hypr/scripts/set_wallpaper.sh ;;
    "Open monitor profile manager")
        hyprctl dispatch exec ~/.config/hypr/scripts/monitor_profile_manager.sh menu ;;
    "Auto-apply monitor profile")
        hyprctl dispatch exec ~/.config/hypr/scripts/monitor_profile_manager.sh auto ;;
    "Extract text from screen (OCR)")
        hyprctl dispatch exec ~/.config/hypr/scripts/ocr.sh ;;
    "Open keybinding help menu")
        hyprctl dispatch exec ~/.config/hypr/scripts/keybinding_menu.sh ;;
    "App-specific shortcuts help")
        hyprctl dispatch exec ~/.config/hypr/scripts/app_help.sh ;;
    "Open calculator")
        hyprctl dispatch exec ~/.config/hypr/scripts/calculator.sh ;;
    "Kill a process")
        hyprctl dispatch exec ~/.config/hypr/scripts/process_killer.sh ;;
    "Audio device switcher")
        hyprctl dispatch exec ~/.config/hypr/scripts/audio_switcher.sh ;;
    "Close active window")
        hyprctl dispatch killactive ;;
    "Toggle floating mode")
        hyprctl dispatch togglefloating ;;
    "Toggle fullscreen mode")
        hyprctl dispatch fullscreen ;;
    "Toggle pseudotiling mode")
        hyprctl dispatch pseudo ;;
    "Toggle split direction (vertical/horizontal)")
        hyprctl dispatch togglesplit ;;
    "Toggle window group")
        hyprctl dispatch togglegroup ;;
    "Move window left")
        hyprctl dispatch movewindow l ;;
    "Move window down")
        hyprctl dispatch movewindow d ;;
    "Move window up")
        hyprctl dispatch movewindow u ;;
    "Move window right")
        hyprctl dispatch movewindow r ;;
    "Resize window left (make narrower)")
        hyprctl dispatch resizeactive -20 0 ;;
    "Resize window down (make shorter)")
        hyprctl dispatch resizeactive 0 20 ;;
    "Resize window up (make taller)")
        hyprctl dispatch resizeactive 0 -20 ;;
    "Resize window right (make wider)")
        hyprctl dispatch resizeactive 20 0 ;;
    "Move focus left")
        hyprctl dispatch movefocus l ;;
    "Move focus down")
        hyprctl dispatch movefocus d ;;
    "Move focus up")
        hyprctl dispatch movefocus u ;;
    "Move focus right")
        hyprctl dispatch movefocus r ;;
    "Move window")
        hyprctl dispatch movewindow ;;
    "Resize window")
        hyprctl dispatch resizewindow ;;
    "Switch to workspace 1")
        hyprctl dispatch workspace 1 ;;
    "Switch to workspace 2")
        hyprctl dispatch workspace 2 ;;
    "Switch to workspace 3")
        hyprctl dispatch workspace 3 ;;
    "Switch to workspace 4")
        hyprctl dispatch workspace 4 ;;
    "Switch to workspace 5")
        hyprctl dispatch workspace 5 ;;
    "Switch to workspace 6")
        hyprctl dispatch workspace 6 ;;
    "Switch to workspace 7")
        hyprctl dispatch workspace 7 ;;
    "Switch to workspace 8")
        hyprctl dispatch workspace 8 ;;
    "Switch to workspace 9")
        hyprctl dispatch workspace 9 ;;
    "Switch to workspace 10")
        hyprctl dispatch workspace 10 ;;
    "Move window to workspace 1")
        hyprctl dispatch movetoworkspace 1 ;;
    "Move window to workspace 2")
        hyprctl dispatch movetoworkspace 2 ;;
    "Move window to workspace 3")
        hyprctl dispatch movetoworkspace 3 ;;
    "Move window to workspace 4")
        hyprctl dispatch movetoworkspace 4 ;;
    "Move window to workspace 5")
        hyprctl dispatch movetoworkspace 5 ;;
    "Move window to workspace 6")
        hyprctl dispatch movetoworkspace 6 ;;
    "Move window to workspace 7")
        hyprctl dispatch movetoworkspace 7 ;;
    "Move window to workspace 8")
        hyprctl dispatch movetoworkspace 8 ;;
    "Move window to workspace 9")
        hyprctl dispatch movetoworkspace 9 ;;
    "Move window to workspace 10")
        hyprctl dispatch movetoworkspace 10 ;;
    "Next workspace")
        hyprctl dispatch workspace e+1 ;;
    "Previous workspace")
        hyprctl dispatch workspace e-1 ;;
    "Toggle Magic workspace (special)")
        hyprctl dispatch togglespecialworkspace Magic ;;
    "Send to Magic workspace")
        hyprctl dispatch movetoworkspacesilent special:Magic ;;
    "Toggle Ad-Hoc workspace (special)")
        hyprctl dispatch togglespecialworkspace Ad-Hoc ;;
    "Send to Ad-Hoc workspace")
        hyprctl dispatch movetoworkspacesilent special:Ad-Hoc ;;
    "Toggle Entertainment workspace (special)")
        hyprctl dispatch togglespecialworkspace Entertainment ;;
    "Send to Entertainment workspace")
        hyprctl dispatch movetoworkspacesilent special:Entertainment ;;
    "Toggle/create window group")
        hyprctl dispatch togglegroup ;;
    "Switch to next window in group")
        hyprctl dispatch changegroupactive f ;;
    "Switch to previous window in group")
        hyprctl dispatch changegroupactive b ;;
    "Lock/unlock group (prevent grouping)")
        hyprctl dispatch lockgroups toggle ;;
    "Increase volume")
        hyprctl dispatch exec ~/.config/waybar/scripts/volume-control.sh up ;;
    "Decrease volume")
        hyprctl dispatch exec ~/.config/waybar/scripts/volume-control.sh down ;;
    "Toggle mute")
        hyprctl dispatch exec "pactl set-sink-mute @DEFAULT_SINK@ toggle" ;;
    "Toggle media playback")
        hyprctl dispatch exec "playerctl play-pause" ;;
    "Skip to next track")
        hyprctl dispatch exec "playerctl next" ;;
    "Go to previous track")
        hyprctl dispatch exec "playerctl previous" ;;
    "Increase screen brightness")
        hyprctl dispatch exec "brightnessctl set +5%" ;;
    "Decrease screen brightness")
        hyprctl dispatch exec "brightnessctl set 5%-" ;;
    "Screenshot active monitor")
        hyprctl dispatch exec ~/.config/hypr/scripts/screenshot_screen_edit.sh ;;
    "Screenshot active window")
        hyprctl dispatch exec ~/.config/hypr/scripts/screenshot_window_edit.sh ;;
    "Screenshot selected region")
        hyprctl dispatch exec ~/.config/hypr/scripts/screenshot_edit.sh ;;
    "Universal copy")
        hyprctl dispatch sendshortcut CTRL Insert ;;
    "Universal paste")
        hyprctl dispatch sendshortcut SHIFT Insert ;;
    "Universal cut")
        hyprctl dispatch sendshortcut CTRL X ;;
    *)
        notify-send "Keybinding Helper" "Unknown command: $DESCRIPTION" -t 3000
        exit 1
        ;;
esac

# Send notification about executed action
if [ $? -eq 0 ]; then
    notify-send \
        --app-name="Keybinding Helper" \
        --icon="input-keyboard" \
        --urgency=low \
        "Keybinding Executed" \
        "$DESCRIPTION" \
        -t 2000 2>/dev/null
fi
