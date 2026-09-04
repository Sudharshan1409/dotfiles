#!/bin/bash

# =============================================================================
# Process Killer - Kill hung or unwanted processes via rofi
# =============================================================================

ROFI_THEME="$HOME/.config/rofi/process-killer.rasi"

# Function to get process list
get_processes() {
    # Get processes with CPU and memory usage, format nicely
    ps -eo pid,ppid,cmd:50,%cpu,%mem --sort=-%cpu | 
    tail -n +2 | 
    awk '{
        pid=$1
        ppid=$2
        cmd=$3
        cpu=$4
        mem=$5
        # Skip kernel processes and important system processes
        if (cmd !~ /^\[/ && cmd !~ /systemd|dbus|network|pipewire|polkit|swaync|waybar|hypr/) {
            printf "%-8s │ %-6s │ %-6s │ %s\n", pid, cpu, mem, cmd
        }
    }'
}

# Function to get detailed process info
get_process_info() {
    local pid="$1"
    ps -p "$pid" -o pid,ppid,cmd,%cpu,%mem,etime 2>/dev/null | tail -n +2
}

# Function to kill process
kill_process() {
    local pid="$1"
    local signal="${2:-TERM}"
    
    if kill -$signal "$pid" 2>/dev/null; then
        notify-send "Process Killer" "Process $pid terminated successfully" -i dialog-information -t 2000
        return 0
    else
        notify-send "Process Killer" "Failed to kill process $pid" -i dialog-error -t 3000
        return 1
    fi
}

# Main menu
while true; do
    # Get current processes
    PROCESSES=$(get_processes)
    
    # Add header and instructions
    MENU="PID      │ CPU%   │ MEM%   │ Command
────────────────────────────────────────────
$PROCESSES"
    
    # Show rofi
    SELECTED=$(echo -e "$MENU" | rofi -dmenu \
        -p "Process Killer" \
        -theme "$ROFI_THEME" \
        -mesg "Select a process to kill | Type to filter" \
        -i)
    
    # Check if cancelled
    if [ -z "$SELECTED" ]; then
        exit 0
    fi
    
    # Skip header
    if [[ "$SELECTED" == "PID"* ]] || [[ "$SELECTED" == "─"* ]]; then
        continue
    fi
    
    # Extract PID
    PID=$(echo "$SELECTED" | awk '{print $1}')
    
    # Validate PID
    if ! [[ "$PID" =~ ^[0-9]+$ ]]; then
        notify-send "Process Killer" "Invalid selection" -i dialog-error -t 2000
        continue
    fi
    
    # Check if process exists
    if ! ps -p "$PID" > /dev/null 2>&1; then
        notify-send "Process Killer" "Process $PID no longer exists" -i dialog-warning -t 2000
        continue
    fi
    
    # Get process details
    PROC_INFO=$(get_process_info "$PID")
    PROC_CMD=$(echo "$SELECTED" | cut -d'│' -f4 | xargs)
    
    # Show confirmation menu
    CHOICE=$(echo -e "☠️  Kill Process (PID: $PID)
☠️  Kill -9 (Force Kill)
ℹ️  Process Info
❌ Cancel" | rofi -dmenu \
        -p "Action" \
        -theme "$ROFI_THEME" \
        -mesg "$PROC_CMD" \
        -i)
    
    case "$CHOICE" in
        "☠️  Kill Process"*)
            kill_process "$PID" "TERM"
            ;;
        "☠️  Kill -9"*)
            kill_process "$PID" "KILL"
            ;;
        "ℹ️  Process Info")
            # Show detailed info
            INFO=$(ps -p "$PID" -o pid,ppid,user,cmd,%cpu,%mem,nlwp,etime 2>/dev/null | column -t)
            echo -e "$INFO" | rofi -dmenu \
                -p "Process Info" \
                -theme "$ROFI_THEME" \
                -mesg "PID $PID Details"
            ;;
        "❌ Cancel"|"")
            continue
            ;;
    esac
done
