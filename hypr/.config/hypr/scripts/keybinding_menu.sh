#!/bin/bash

# =============================================================================
# Keybinding Help Menu for Hyprland (Lua + Caelestia Shell)
# Interactive searchable menu showing all keyboard shortcuts & gestures
# =============================================================================

ROFI_THEME="$HOME/.config/rofi/keybindings.rasi"

TEMP_FILE=$(mktemp)

cat > "$TEMP_FILE" << 'EOF'
📱 APPS | Super + Enter | Open terminal (Ghostty)
📱 APPS | Super + S | Toggle scratchpad terminal
📱 APPS | Super + Space | Open application launcher (Caelestia, Ctrl+HJKL)
📱 APPS | Super + D | Toggle Caelestia dashboard (media, stats, weather)
📱 APPS | Super + . | Open Emoji & Nerd Font glyph picker
📱 APPS | Super + Shift + F | Quick FZF Finder (Folders in Yazi / Files in Neovim)
📱 APPS | Super + Alt + S | Open Spotify
📱 APPS | Super + Alt + M | Toggle Spotify music scratchpad (special:music)
📱 APPS | Super + Alt + T | Toggle btop system monitor scratchpad (special:sysmon)
📱 APPS | Ctrl + Shift + Esc | Toggle btop system monitor scratchpad (alternate)
📱 APPS | Super + Alt + D | Open Downloads folder
📱 APPS | Super + Alt + B | Open Backgrounds folder
📱 APPS | Super + Ctrl + V | Open clipboard history
📱 APPS | Super + Ctrl + N | Open notification sidebar
📱 APPS | Super + ` | Show workspace overview
⚙️ SYSTEM | Super + Ctrl + M | Exit Hyprland session
⚙️ SYSTEM | Super + Ctrl + R | Reload Hyprland configuration
⚙️ SYSTEM | Super + Ctrl + L | Lock the screen (Caelestia lock)
⚙️ SYSTEM | Super + Ctrl + S | Suspend the system
⚙️ SYSTEM | Super + Ctrl + H | Toggle Keep Awake (Caelestia idle inhibitor)
⚙️ SYSTEM | Super + Ctrl + X | Open session power menu
⚙️ SYSTEM | Super + Ctrl + W | Open wallpaper picker (live preview)
⚙️ SYSTEM | Super + Ctrl + Shift + W | Change to random wallpaper
⚙️ SYSTEM | Super + Ctrl + , | Open Caelestia settings (Nexus floating window)
⚙️ SYSTEM | Super + Ctrl + D | Open monitor profile manager
⚙️ SYSTEM | Super + Ctrl + Shift + D | Auto-apply monitor profile
⚙️ SYSTEM | Super + Shift + T | Extract text from screen (OCR)
⚙️ SYSTEM | Super + / | Open keybinding help menu
⚙️ SYSTEM | Super + Shift + ? | App-specific shortcuts help
🔧 UTILS | Super + Alt + C | Open scientific calculator
🔧 UTILS | Super + Alt + P | Kill a process
🔧 UTILS | Super + Alt + A | Audio device switcher
🔧 UTILS | Super + Alt + R | Screen recorder (Caelestia utilities / stop)
🔧 UTILS | Super + Alt + Shift + R | Quick record region with audio (toggle)
🔧 UTILS | Super + Alt + F | Focus mode (toggle DND + dim inactive)
🔧 UTILS | Super + Alt + G | Toggle Game Mode (zero animations/blur/gaps)
🪟 WINDOWS | Super + C | Close active window
🪟 WINDOWS | Super + V | Toggle floating mode
🪟 WINDOWS | Super + F | Toggle fullscreen mode
🪟 WINDOWS | Super + P | Toggle pseudotiling mode
🪟 WINDOWS | Super + Shift + P | Toggle Picture-in-Picture (PiP) mode
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
🧭 NAVIGATION | Alt + Tab | Live visual window switcher (next window)
🧭 NAVIGATION | Alt + Shift + Tab | Live visual window switcher (previous window)
👆 GESTURES | 3-Finger Swipe Left/Right | Switch workspaces smoothly
👆 GESTURES | 3-Finger Swipe Up | Toggle Caelestia launcher
👆 GESTURES | 3-Finger Swipe Down | Toggle Caelestia dashboard
👆 GESTURES | 4-Finger Swipe Up | Toggle Caelestia quick utilities
👆 GESTURES | 4-Finger Swipe Down | Toggle scratchpad terminal
🗂️ WORKSPACES | Super + 1..0 | Switch to workspace 1..10
🗂️ WORKSPACES | Super + Shift + 1..0 | Move window to workspace 1..10
🗂️ WORKSPACES | Super + Mouse Scroll Down | Next workspace
🗂️ WORKSPACES | Super + Mouse Scroll Up | Previous workspace
🗂️ WORKSPACES | Super + Backspace | Jump to previously focused workspace
🗂️ WORKSPACES | Super + Shift + Left | Move workspace to monitor on the left
🗂️ WORKSPACES | Super + Shift + Right | Move workspace to monitor on the right
🗂️ WORKSPACES | Super + Shift + Up | Move workspace to monitor above
🗂️ WORKSPACES | Super + Shift + Down | Move workspace to monitor below
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
📸 SCREENSHOTS | Super + Shift + S | Freeze screen, snap window or region & annotate (Satty)
📸 SCREENSHOTS | Super + Shift + Print | Freeze screen, snap window or region & annotate (Satty)
📸 SCREENSHOTS | Super + Print | Freeze screen, snap window or region to clipboard
📸 SCREENSHOTS | Print | Capture active monitor & annotate (Satty)
EOF

SELECTED=$(cat "$TEMP_FILE" | rofi -dmenu \
    -p "Keybindings" \
    -theme "$ROFI_THEME" \
    -i \
    -no-custom \
    -mesg "Type to search | Press Enter to execute" 2>/dev/null)

rm -f "$TEMP_FILE"

if [ -z "$SELECTED" ]; then
    exit 0
fi

DESCRIPTION=$(echo "$SELECTED" | cut -d'|' -f3 | xargs)

case "$DESCRIPTION" in
    "Open terminal (Ghostty)")
        hyprctl repl 'hl.exec_cmd("ghostty")' ;;
    "Toggle scratchpad terminal")
        hyprctl repl 'hl.exec_cmd("~/.config/hypr/scripts/scratchpad_terminal.sh")' ;;
    "Open application launcher (Caelestia, Ctrl+HJKL)"|"Toggle Caelestia launcher")
        hyprctl repl 'hl.exec_cmd("caelestia shell drawers toggle launcher")' ;;
    "Toggle Caelestia dashboard (media, stats, weather)"|"Toggle Caelestia dashboard")
        hyprctl repl 'hl.exec_cmd("caelestia shell drawers toggle dashboard")' ;;
    "Toggle Caelestia quick utilities")
        hyprctl repl 'hl.exec_cmd("caelestia shell drawers toggle utilities")' ;;
    "Open Emoji & Nerd Font glyph picker")
        hyprctl repl 'hl.exec_cmd("~/.config/hypr/scripts/emoji_picker.sh")' ;;
    "Quick FZF Finder (Folders in Yazi / Files in Neovim)")
        hyprctl repl 'hl.exec_cmd("~/.config/hypr/scripts/quick_fzf_finder.sh")' ;;
    "Open Spotify")
        hyprctl repl 'hl.exec_cmd("spotify")' ;;
    "Toggle Spotify music scratchpad (special:music)")
        hyprctl repl 'hl.exec_cmd("caelestia toggle music")' ;;
    "Toggle btop system monitor scratchpad (special:sysmon)"|"Toggle btop system monitor scratchpad (alternate)")
        hyprctl repl 'hl.exec_cmd("caelestia toggle sysmon")' ;;
    "Open Downloads folder")
        hyprctl repl 'hl.exec_cmd("nautilus ~/Downloads")' ;;
    "Open Backgrounds folder")
        hyprctl repl 'hl.exec_cmd("nautilus ~/.config/backgrounds")' ;;
    "Open clipboard history")
        hyprctl repl 'hl.exec_cmd("~/.config/hypr/scripts/clipboard.sh")' ;;
    "Open notification sidebar")
        hyprctl repl 'hl.exec_cmd("caelestia shell drawers toggle sidebar")' ;;
    "Show workspace overview")
        hyprctl repl 'hl.exec_cmd("~/.config/hypr/scripts/workspace_overview.sh")' ;;
    "Exit Hyprland session")
        hyprctl repl 'hl.exec_cmd("~/.config/hypr/scripts/exit_hyprland.sh")' ;;
    "Reload Hyprland configuration")
        hyprctl repl 'hl.exec_cmd("hyprctl reload && notify-send -i '\''dialog-information'\'' -a '\''Hyprland'\'' '\''Hyprland'\'' '\''Config reloaded successfully!'\''")' ;;
    "Lock the screen (Caelestia lock)")
        hyprctl repl 'hl.exec_cmd("caelestia shell lock lock")' ;;
    "Suspend the system")
        hyprctl repl 'hl.exec_cmd("systemctl suspend")' ;;
    "Toggle Keep Awake (Caelestia idle inhibitor)")
        hyprctl repl 'hl.exec_cmd("~/.config/hypr/scripts/toggle_keep_awake.sh")' ;;
    "Open session power menu")
        hyprctl repl 'hl.exec_cmd("caelestia shell drawers toggle session")' ;;
    "Open wallpaper picker (live preview)")
        hyprctl repl 'hl.exec_cmd("caelestia shell wallpaper picker || caelestia shell nexus open")' ;;
    "Change to random wallpaper")
        hyprctl repl 'hl.exec_cmd("caelestia wallpaper -r ~/.config/backgrounds -n -N")' ;;
    "Open Caelestia settings (Nexus floating window)")
        hyprctl repl 'hl.exec_cmd("caelestia shell nexus open")' ;;
    "Open monitor profile manager")
        hyprctl repl 'hl.exec_cmd("~/.config/hypr/scripts/monitor_profile_manager.sh menu")' ;;
    "Auto-apply monitor profile")
        hyprctl repl 'hl.exec_cmd("~/.config/hypr/scripts/monitor_profile_manager.sh auto")' ;;
    "Extract text from screen (OCR)")
        hyprctl repl 'hl.exec_cmd("~/.config/hypr/scripts/ocr.sh")' ;;
    "Open keybinding help menu")
        hyprctl repl 'hl.exec_cmd("~/.config/hypr/scripts/keybinding_menu.sh")' ;;
    "App-specific shortcuts help")
        hyprctl repl 'hl.exec_cmd("~/.config/hypr/scripts/app_help.sh")' ;;
    "Open scientific calculator")
        hyprctl repl 'hl.exec_cmd("~/.config/hypr/scripts/calculator.sh")' ;;
    "Kill a process")
        hyprctl repl 'hl.exec_cmd("~/.config/hypr/scripts/process_killer.sh")' ;;
    "Audio device switcher")
        hyprctl repl 'hl.exec_cmd("~/.config/hypr/scripts/audio_switcher.sh")' ;;
    "Screen recorder (Caelestia utilities / stop)")
        hyprctl repl 'hl.exec_cmd("pidof gpu-screen-recorder >/dev/null && caelestia record -c || caelestia shell drawers toggle utilities")' ;;
    "Quick record region with audio (toggle)")
        hyprctl repl 'hl.exec_cmd("caelestia record -sr -c")' ;;
    "Focus mode (toggle DND + dim inactive)")
        hyprctl repl 'hl.exec_cmd("~/.config/hypr/scripts/focus_mode.sh")' ;;
    "Toggle Game Mode (zero animations/blur/gaps)")
        hyprctl repl 'hl.exec_cmd("caelestia shell gameMode toggle")' ;;
    "Close active window")
        hyprctl repl 'hl.dispatch(hl.dsp.window.close())' ;;
    "Toggle floating mode")
        hyprctl repl 'hl.dispatch(hl.dsp.window.float({ action = "toggle" }))' ;;
    "Toggle fullscreen mode")
        hyprctl repl 'hl.dispatch(hl.dsp.window.fullscreen({ action = "toggle" }))' ;;
    "Toggle pseudotiling mode")
        hyprctl repl 'hl.dispatch(hl.dsp.window.pseudo())' ;;
    "Toggle Picture-in-Picture (PiP) mode")
        hyprctl repl 'hl.exec_cmd("~/.config/hypr/scripts/toggle_pip.sh")' ;;
    "Toggle split direction (vertical/horizontal)")
        hyprctl repl 'hl.dispatch(hl.dsp.layout("togglesplit"))' ;;
    "Toggle window group")
        hyprctl repl 'hl.dispatch(hl.dsp.group.toggle())' ;;
    "Move window left")
        hyprctl repl 'hl.dispatch(hl.dsp.window.move({direction="l"}))' ;;
    "Move window down")
        hyprctl repl 'hl.dispatch(hl.dsp.window.move({direction="d"}))' ;;
    "Move window up")
        hyprctl repl 'hl.dispatch(hl.dsp.window.move({direction="u"}))' ;;
    "Move window right")
        hyprctl repl 'hl.dispatch(hl.dsp.window.move({direction="r"}))' ;;
    "Resize window left (make narrower)")
        hyprctl repl 'hl.dispatch(hl.dsp.window.resize({x=-20, y=0, relative=true}))' ;;
    "Resize window down (make shorter)")
        hyprctl repl 'hl.dispatch(hl.dsp.window.resize({x=0, y=20, relative=true}))' ;;
    "Resize window up (make taller)")
        hyprctl repl 'hl.dispatch(hl.dsp.window.resize({x=0, y=-20, relative=true}))' ;;
    "Resize window right (make wider)")
        hyprctl repl 'hl.dispatch(hl.dsp.window.resize({x=20, y=0, relative=true}))' ;;
    "Move focus left")
        hyprctl repl 'hl.dispatch(hl.dsp.focus({direction="l"}))' ;;
    "Move focus down")
        hyprctl repl 'hl.dispatch(hl.dsp.focus({direction="d"}))' ;;
    "Move focus up")
        hyprctl repl 'hl.dispatch(hl.dsp.focus({direction="u"}))' ;;
    "Move focus right")
        hyprctl repl 'hl.dispatch(hl.dsp.focus({direction="r"}))' ;;
    "Move window")
        hyprctl repl 'hl.dispatch(hl.dsp.window.drag())' ;;
    "Resize window")
        hyprctl repl 'hl.dispatch(hl.dsp.window.resize())' ;;
    "Live visual window switcher (next window)")
        hyprctl repl 'hl.exec_cmd("caelestia shell windowSwitcher open")' ;;
    "Live visual window switcher (previous window)")
        hyprctl repl 'hl.exec_cmd("caelestia shell windowSwitcher prev")' ;;
    "Next workspace"|"Switch workspaces smoothly")
        hyprctl repl 'hl.dispatch(hl.dsp.focus({workspace="e+1"}))' ;;
    "Previous workspace")
        hyprctl repl 'hl.dispatch(hl.dsp.focus({workspace="e-1"}))' ;;
    "Jump to previously focused workspace")
        hyprctl repl 'hl.dispatch(hl.dsp.focus({workspace="previous"}))' ;;
    "Move workspace to monitor on the left")
        hyprctl repl 'hl.dispatch(hl.dsp.workspace.move({monitor="l"}))' ;;
    "Move workspace to monitor on the right")
        hyprctl repl 'hl.dispatch(hl.dsp.workspace.move({monitor="r"}))' ;;
    "Move workspace to monitor above")
        hyprctl repl 'hl.dispatch(hl.dsp.workspace.move({monitor="u"}))' ;;
    "Move workspace to monitor below")
        hyprctl repl 'hl.dispatch(hl.dsp.workspace.move({monitor="d"}))' ;;
    "Toggle Magic workspace (special)")
        hyprctl repl 'hl.dispatch(hl.dsp.workspace.toggle_special("Magic"))' ;;
    "Send to Magic workspace")
        hyprctl repl 'hl.dispatch(hl.dsp.window.move({workspace="special:Magic", follow=false}))' ;;
    "Toggle Ad-Hoc workspace (special)")
        hyprctl repl 'hl.dispatch(hl.dsp.workspace.toggle_special("Ad-Hoc"))' ;;
    "Send to Ad-Hoc workspace")
        hyprctl repl 'hl.dispatch(hl.dsp.window.move({workspace="special:Ad-Hoc", follow=false}))' ;;
    "Toggle Entertainment workspace (special)")
        hyprctl repl 'hl.dispatch(hl.dsp.workspace.toggle_special("Entertainment"))' ;;
    "Send to Entertainment workspace")
        hyprctl repl 'hl.dispatch(hl.dsp.window.move({workspace="special:Entertainment", follow=false}))' ;;
    "Toggle/create window group")
        hyprctl repl 'hl.dispatch(hl.dsp.group.toggle())' ;;
    "Switch to next window in group")
        hyprctl repl 'hl.dispatch(hl.dsp.group.next())' ;;
    "Switch to previous window in group")
        hyprctl repl 'hl.dispatch(hl.dsp.group.prev())' ;;
    "Lock/unlock group (prevent grouping)")
        hyprctl repl 'hl.dispatch(hl.dsp.group.lock())' ;;
    "Increase volume")
        hyprctl repl 'hl.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+")' ;;
    "Decrease volume")
        hyprctl repl 'hl.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")' ;;
    "Toggle mute")
        hyprctl repl 'hl.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")' ;;
    "Toggle media playback")
        hyprctl repl 'hl.exec_cmd("playerctl play-pause")' ;;
    "Skip to next track")
        hyprctl repl 'hl.exec_cmd("playerctl next")' ;;
    "Go to previous track")
        hyprctl repl 'hl.exec_cmd("playerctl previous")' ;;
    "Increase screen brightness")
        hyprctl repl 'hl.exec_cmd("caelestia shell brightness set +5% || brightnessctl -q set +5%")' ;;
    "Decrease screen brightness")
        hyprctl repl 'hl.exec_cmd("caelestia shell brightness set 5%- || brightnessctl -q set 5%-")' ;;
    "Capture active monitor & annotate (Satty)")
        hyprctl repl 'hl.exec_cmd("~/.config/hypr/scripts/screenshot_screen_edit.sh")' ;;
    "Freeze screen, snap window or region to clipboard")
        hyprctl repl 'hl.exec_cmd("caelestia shell picker openFreezeClip")' ;;
    "Freeze screen, snap window or region & annotate (Satty)")
        hyprctl repl 'hl.exec_cmd("caelestia shell picker openFreeze")' ;;
    *)
        exit 0
        ;;
esac
