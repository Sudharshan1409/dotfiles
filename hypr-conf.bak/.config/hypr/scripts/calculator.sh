#!/bin/bash

# =============================================================================
# Quick Calculator - Calculate expressions instantly via rofi
# =============================================================================

ROFI_THEME="$HOME/.config/rofi/calculator.rasi"

# Function to calculate
calculate() {
    local expr="$1"
    # Use bc for calculations
    result=$(echo "$expr" | bc 2>/dev/null)
    
    if [ -z "$result" ] || [ "$result" = "" ]; then
        echo "Error"
    else
        # Remove trailing zeros and decimal point if whole number
        echo "$result" | sed 's/^\./0./;s/\.$//;s/\.0*$//'
    fi
}

# Function to show history
show_history() {
    if [ -f "$HOME/.cache/hypr/calc_history" ]; then
        tac "$HOME/.cache/hypr/calc_history" | head -20
    fi
}

# Create cache directory
mkdir -p "$HOME/.cache/hypr"

# Main loop
while true; do
    # Build menu with history
    HISTORY=$(show_history)
    if [ -n "$HISTORY" ]; then
        MENU="$HISTORY
───────────────────────
Type expression and press Enter"
    else
        MENU="Type expression and press Enter
Examples: 2+2, 10*5, 130000-55000"
    fi
    
    # Show rofi
    INPUT=$(echo -e "$MENU" | rofi -dmenu \
        -p "Calculator" \
        -theme "$ROFI_THEME" \
        -mesg "Enter: Calculate | Ctrl+C: Copy result | Esc: Exit" \
        -i)
    
    # Check if user cancelled
    if [ -z "$INPUT" ]; then
        exit 0
    fi
    
    # Skip separators and help text
    if [[ "$INPUT" == "─"* ]] || [[ "$INPUT" == "Type expression"* ]] || [[ "$INPUT" == "Examples:"* ]]; then
        continue
    fi
    
    # Check if it's a previous result (starts with =)
    if [[ "$INPUT" == "="* ]]; then
        # Extract just the expression
        EXPR=$(echo "$INPUT" | sed 's/^= //' | sed 's/←.*$//')
    else
        EXPR="$INPUT"
    fi
    
    # Clean up expression - keep only numbers and operators
    EXPR=$(echo "$EXPR" | tr -d '[:space:]')
    
    # Calculate
    RESULT=$(calculate "$EXPR")
    
    if [ "$RESULT" != "Error" ]; then
        # Save to history
        echo "= $RESULT  ←  $EXPR" >> "$HOME/.cache/hypr/calc_history"
        
        # Show result with options
        CHOICE=$(echo -e "📋 Copy to clipboard: $RESULT
🔄 Use in new calculation
📊 Result: $RESULT
❌ Close" | rofi -dmenu \
            -p "Result" \
            -theme "$ROFI_THEME" \
            -mesg "$EXPR = $RESULT" \
            -i)
        
        case "$CHOICE" in
            "📋 Copy to clipboard:"*)
                echo -n "$RESULT" | wl-copy
                notify-send "Calculator" "Result copied to clipboard: $RESULT" -t 2000
                exit 0
                ;;
            "🔄 Use in new calculation")
                continue
                ;;
            "❌ Close"|"")
                exit 0
                ;;
            *)
                continue
                ;;
        esac
    else
        notify-send "Calculator" "Invalid expression: $EXPR" -t 3000
    fi
done
