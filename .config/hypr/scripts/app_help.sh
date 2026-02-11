#!/bin/bash

# =============================================================================
# App-Specific Help - Show keyboard shortcuts for the active application
# =============================================================================

ROFI_THEME="$HOME/.config/rofi/app-help.rasi"

# Function to get active window class
get_active_window_class() {
    hyprctl activewindow -j 2>/dev/null | jq -r '.class' | tr '[:upper:]' '[:lower:]'
}

# Function to get active window title
get_active_window_title() {
    hyprctl activewindow -j 2>/dev/null | jq -r '.title'
}

# Function to get help for specific apps
get_app_help() {
    local app_class="$1"
    
    case "$app_class" in
        *ghostty*|*kitty*|*alacritty*|*terminal*)
            cat << 'EOF'
📋 Ghostty/Terminal Shortcuts:

⌨️  Navigation:
  Ctrl + Shift + C    Copy selection
  Ctrl + Shift + V    Paste
  Ctrl + Shift + K    Clear screen
  Ctrl + Shift + T    New tab
  Ctrl + Shift + W    Close tab
  Ctrl + Tab          Next tab
  Ctrl + Shift + Tab  Previous tab
  Ctrl + +            Zoom in
  Ctrl + -            Zoom out
  Ctrl + 0            Reset zoom

⌨️  Search:
  Ctrl + Shift + F    Search in terminal

⌨️  Other:
  F11                 Toggle fullscreen
  Ctrl + Shift + ↑    Scroll up one line
  Ctrl + Shift + ↓    Scroll down one line
EOF
            ;;
            
        *firefox*|*brave*|*chrome*|*chromium*)
            cat << 'EOF'
🌐 Browser Shortcuts:

⌨️  Navigation:
  Ctrl + T            New tab
  Ctrl + W            Close tab
  Ctrl + Shift + T    Reopen closed tab
  Ctrl + Tab          Next tab
  Ctrl + Shift + Tab  Previous tab
  Ctrl + 1-8          Go to tab 1-8
  Ctrl + 9            Go to last tab
  Ctrl + L            Focus address bar
  Ctrl + K            Search in page
  Ctrl + R            Refresh page
  Ctrl + Shift + R    Hard refresh
  Alt + ←             Back
  Alt + →             Forward
  Ctrl + H            History
  Ctrl + J            Downloads
  Ctrl + Shift + N    New private window

⌨️  Bookmarks:
  Ctrl + D            Bookmark current page
  Ctrl + Shift + D    Bookmark all tabs
  Ctrl + Shift + B    Toggle bookmarks bar
  Ctrl + B            Show bookmarks

⌨️  Other:
  Ctrl + +            Zoom in
  Ctrl + -            Zoom out
  Ctrl + 0            Reset zoom
  F11                 Fullscreen
  Ctrl + P            Print
  Ctrl + S            Save page
EOF
            ;;
            
        *code*|*vscode*|*vscodium*)
            cat << 'EOF'
📝 VS Code Shortcuts:

⌨️  File Operations:
  Ctrl + N            New file
  Ctrl + O            Open file
  Ctrl + S            Save
  Ctrl + Shift + S    Save as
  Ctrl + W            Close file
  Ctrl + Shift + N    New window

⌨️  Editing:
  Ctrl + X            Cut line
  Ctrl + C            Copy line
  Ctrl + V            Paste
  Ctrl + Z            Undo
  Ctrl + Shift + Z    Redo
  Ctrl + F            Find
  Ctrl + H            Replace
  Ctrl + D            Add selection to next find match
  Ctrl + Shift + L    Select all occurrences
  Alt + ↑             Move line up
  Alt + ↓             Move line down
  Ctrl + /            Toggle comment
  Ctrl + Shift + K    Delete line

⌨️  Navigation:
  Ctrl + P            Quick open file
  Ctrl + G            Go to line
  Ctrl + Shift + O    Go to symbol
  Ctrl + T            Show all symbols
  F12                 Go to definition
  Alt + F12           Peek definition
  Ctrl + Shift + F    Search across files

⌨️  Terminal:
  Ctrl + `            Toggle terminal
  Ctrl + Shift + `    New terminal

⌨️  View:
  Ctrl + B            Toggle sidebar
  Ctrl + Shift + E    Explorer
  Ctrl + Shift + F    Search
  Ctrl + Shift + G    Source control
  Ctrl + Shift + D    Debug
  Ctrl + Shift + X    Extensions
  Ctrl + Shift + M    Problems
  F5                  Start debugging
  Shift + F5          Stop debugging
EOF
            ;;
            
        *jetbrains*|*idea*|*pycharm*|*webstorm*)
            cat << 'EOF'
🎯 JetBrains IDE Shortcuts:

⌨️  Navigation:
  Ctrl + N            Go to class
  Ctrl + Shift + N    Go to file
  Ctrl + Alt + Shift + N  Go to symbol
  Ctrl + B            Go to declaration
  Ctrl + Alt + B      Go to implementation
  Ctrl + U            Go to super method
  Ctrl + ]            Move to code block end
  Ctrl + [            Move to code block start
  Ctrl + G            Go to line
  Ctrl + E            Recent files
  Ctrl + Shift + E    Recent locations
  Alt + ←             Back
  Alt + →             Forward

⌨️  Editing:
  Ctrl + Space        Basic completion
  Ctrl + Shift + Space  Smart completion
  Ctrl + P            Parameter info
  Ctrl + Q            Quick documentation
  Ctrl + F1           Error description
  Alt + Insert        Generate code
  Ctrl + O            Override methods
  Ctrl + I            Implement methods
  Ctrl + Alt + T      Surround with
  Ctrl + /            Comment/uncomment line
  Ctrl + Shift + /    Comment/uncomment block
  Ctrl + W            Select word
  Ctrl + Shift + W    Deselect
  Ctrl + D            Duplicate line
  Ctrl + Y            Delete line
  Ctrl + Shift + ↑    Move line up
  Ctrl + Shift + ↓    Move line down

⌨️  Refactoring:
  Shift + F6          Rename
  Ctrl + F6           Change signature
  F6                  Move
  Ctrl + Alt + N      Inline
  Ctrl + Alt + M      Extract method
  Ctrl + Alt + V      Extract variable
  Ctrl + Alt + F      Extract field
  Ctrl + Alt + C      Extract constant
  Ctrl + Alt + P      Extract parameter

⌨️  Build & Run:
  Ctrl + F9           Build project
  Ctrl + Shift + F9   Rebuild
  Shift + F10         Run
  Shift + F9          Debug
  Alt + Shift + F10   Select configuration
  Ctrl + F2           Stop
  F9                  Resume program
  F8                  Step over
  F7                  Step into
  Shift + F7          Smart step into
  Shift + F8          Step out
  Alt + F9            Run to cursor
  Alt + F8            Evaluate expression
EOF
            ;;
            
        *sublime*|*subl*)
            cat << 'EOF'
✨ Sublime Text Shortcuts:

⌨️  File Operations:
  Ctrl + N            New file
  Ctrl + O            Open file
  Ctrl + S            Save
  Ctrl + Shift + S    Save as
  Ctrl + W            Close file
  Ctrl + Shift + T    Reopen closed file

⌨️  Editing:
  Ctrl + X            Cut line
  Ctrl + C            Copy line
  Ctrl + V            Paste
  Ctrl + Shift + V    Paste and indent
  Ctrl + Z            Undo
  Ctrl + Shift + Z    Redo
  Ctrl + Y            Redo (alternate)
  Ctrl + F            Find
  Ctrl + H            Replace
  Ctrl + Shift + F    Find in files
  Ctrl + D            Select word
  Ctrl + D (again)    Select next occurrence
  Ctrl + K, Ctrl + D  Skip and add next
  Ctrl + Shift + L    Split selection into lines
  Ctrl + Shift + ↑    Swap line up
  Ctrl + Shift + ↓    Swap line down
  Ctrl + /            Toggle comment
  Ctrl + Shift + /    Toggle block comment
  Ctrl + Shift + D    Duplicate line
  Ctrl + J            Join lines
  Ctrl + K, Ctrl + K  Delete to end
  Ctrl + K, Ctrl + ←  Delete to beginning

⌨️  Navigation:
  Ctrl + P            Quick open file
  Ctrl + R            Go to symbol
  Ctrl + ;            Go to word
  Ctrl + G            Go to line
  Ctrl + M            Jump to matching bracket
  F12                 Go to definition
  Alt + -             Jump back
  Alt + Shift + -     Jump forward

⌨️  Multi-Cursor:
  Ctrl + Click        Add cursor
  Ctrl + Alt + ↑      Add cursor above
  Ctrl + Alt + ↓      Add cursor below
  Esc                 Exit multi-cursor mode

⌨️  View:
  F11                 Distraction-free mode
  Shift + F11         Fullscreen
  Ctrl + K, Ctrl + B  Toggle sidebar
  Ctrl + `            Show console
EOF
            ;;
            
        *spotify*)
            cat << 'EOF'
🎵 Spotify Shortcuts:

⌨️  Playback:
  Space               Play/Pause
  Ctrl + →            Next track
  Ctrl + ←            Previous track
  Ctrl + Shift + →    Skip forward 15s
  Ctrl + Shift + ←    Skip back 15s
  Ctrl + ↑            Volume up
  Ctrl + ↓            Volume down
  Ctrl + Shift + ↑    Max volume
  Ctrl + Shift + ↓    Mute
  S                   Shuffle
  R                   Repeat

⌨️  Navigation:
  Ctrl + L            Focus search
  Ctrl + Shift + F    Search in playlists
  Ctrl + 1            Home
  Ctrl + 2            Browse
  Ctrl + 3            Radio
  Ctrl + 4            Your Library
  Ctrl + Shift + 1    Made For You
  Ctrl + Shift + 2    Recently Played
  Ctrl + Shift + 3    Liked Songs
  Ctrl + Shift + 4    Albums
  Ctrl + Shift + 5    Artists
  Ctrl + Shift + 6    Podcasts

⌨️  Queue & Playlists:
  Ctrl + Q            View queue
  Ctrl + J            View lyrics
  Ctrl + Enter        Add to queue
  Delete              Remove from playlist
  Ctrl + N            New playlist
  Ctrl + S            Save to Your Library
EOF
            ;;
            
        *gimp*|*krita*|*pinta*)
            cat << 'EOF'
🎨 Image Editor Shortcuts:

⌨️  Tools:
  R                   Rectangle select
  E                   Ellipse select
  F                   Free select
  I                   Intelligent scissors
  Z                   Zoom tool
  M                   Move tool
  C                   Crop tool
  Shift + C           Clone tool
  H                   Healing tool
  P                   Paintbrush
  B                   Bucket fill
  G                   Gradient
  T                   Text tool
  N                   Pencil
  Shift + B           Paths tool
  Shift + P           Perspective tool

⌨️  Colors:
  Shift + O           Color balance
  Shift + L           Levels
  Shift + C           Curves
  Shift + U           Hue-Saturation
  Shift + B           Brightness-Contrast
  Shift + H           Desaturate
  Shift + T           Colorize
  Shift + N           Invert

⌨️  File & Edit:
  Ctrl + N            New image
  Ctrl + O            Open
  Ctrl + S            Save
  Ctrl + Shift + E    Export
  Ctrl + Z            Undo
  Ctrl + Shift + Z    Redo
  Ctrl + X            Cut
  Ctrl + C            Copy
  Ctrl + V            Paste
  Ctrl + Shift + V    Paste as new layer
  Ctrl + A            Select all
  Ctrl + Shift + A    Deselect
  Ctrl + Shift + F    Flatten image
  Ctrl + Shift + D    Duplicate

⌨️  View:
  +                   Zoom in
  -                   Zoom out
  1                   100% zoom
  Shift + E           Show grid
  Ctrl + ;            Toggle guides
  F11                 Fullscreen
  Tab                 Toggle docks
  Shift + Q           Quick mask

⌨️  Layers:
  Ctrl + Shift + N    New layer
  Ctrl + Shift + D    Duplicate layer
  Ctrl + Shift + L    Anchor layer
  Page Up             Layer up
  Page Down           Layer down
  Home                Layer to top
  End                 Layer to bottom
EOF
            ;;
            
        *vlc*|*mpv*)
            cat << 'EOF'
🎬 Media Player Shortcuts:

⌨️  Playback:
  Space               Play/Pause
  →                   Forward 5s
  ←                   Backward 5s
  ↑                   Forward 1 min
  ↓                   Backward 1 min
  Shift + →           Forward 3 min
  Shift + ←           Backward 3 min
  Ctrl + T            Always on top
  T                   Always on top
  F                   Fullscreen
  Esc                 Exit fullscreen
  Q                   Quit
  ]                   Next frame
  [                   Previous frame

⌨️  Audio:
  Ctrl + ↑            Volume up
  Ctrl + ↓            Volume down
  M                   Mute
  A                   Audio track cycle
  Shift + A           Audio device cycle
  Ctrl + ←            Audio delay -
  Ctrl + →            Audio delay +

⌨️  Video:
  S                   Take screenshot
  Ctrl + 1            50% scale
  Ctrl + 2            100% scale
  Ctrl + 3            150% scale
  Ctrl + 4            200% scale
  Z                   Zoom in
  Shift + Z           Zoom out
  Ctrl + 0            Reset zoom
  V                   Subtitle track cycle
  Shift + V           Subtitle visibility toggle
  Ctrl + T            Subtitle delay +
  Ctrl + Shift + T    Subtitle delay -

⌨️  Playlist:
  N                   Next
  P                   Previous
  L                   Loop
  R                   Random
  Ctrl + P            Playlist
  Delete              Remove from playlist
EOF
            ;;
            
        *)
            echo "❓ No specific shortcuts available for: $app_class"
            echo ""
            echo "🌐 Try these general shortcuts:"
            echo "  Ctrl + C          Copy"
            echo "  Ctrl + X          Cut"
            echo "  Ctrl + V          Paste"
            echo "  Ctrl + Z          Undo"
            echo "  Ctrl + Y          Redo"
            echo "  Ctrl + S          Save"
            echo "  Ctrl + O          Open"
            echo "  Ctrl + N          New"
            echo "  Ctrl + F          Find"
            echo "  Ctrl + P          Print"
            echo "  Ctrl + A          Select All"
            echo "  F1                Help"
            echo "  F11               Fullscreen"
            echo "  Alt + F4          Close Window"
            ;;
    esac
}

# Main function
main() {
    # Get active window info
    WINDOW_CLASS=$(get_active_window_class)
    WINDOW_TITLE=$(get_active_window_title)
    
    if [ -z "$WINDOW_CLASS" ] || [ "$WINDOW_CLASS" = "null" ]; then
        # No active window
        echo -e "No active window detected\n\nPress any key in Hyprland to see app shortcuts" | \
            rofi -dmenu -p "App Help" -theme "$ROFI_THEME" -mesg "App-specific keyboard shortcuts"
        exit 0
    fi
    
    # Get help content
    HELP_CONTENT=$(get_app_help "$WINDOW_CLASS")
    
    # Show in rofi
    echo -e "$HELP_CONTENT" | rofi -dmenu \
        -p "$WINDOW_CLASS" \
        -theme "$ROFI_THEME" \
        -mesg "Keyboard shortcuts for $WINDOW_TITLE" \
        -no-custom
}

main
