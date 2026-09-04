#!/bin/bash

# MRU window switcher (Alt-Tab): list all windows across every workspace sorted
# by most-recently-focused, jump to the chosen one. Current window is excluded
# so the top entry is the previous window (classic Alt-Tab feel).

ROFI_THEME="$HOME/.config/rofi/workspace-overview.rasi"

# TSV: <address>\t<display-text>. focusHistoryID 0 = current; skip it.
data=$(hyprctl clients -j 2>/dev/null | \
    jq -r 'sort_by(.focusHistoryID) | .[] | select(.focusHistoryID > 0) | "\(.address)\t[\(.workspace.id)] \(.class) — \(.title)"')

[ -z "$data" ] && exit 0

display=$(echo "$data" | cut -f2-)

# rofi -format i returns the line index so we can map back to the address
# even if titles contain ambiguous characters.
idx=$(echo "$display" | rofi -dmenu \
    -p "Windows" \
    -theme "$ROFI_THEME" \
    -mesg "MRU sorted — Enter to jump" \
    -i \
    -format i \
    -selected-row 0)

[ -z "$idx" ] && exit 0

addr=$(echo "$data" | sed -n "$((idx + 1))p" | cut -f1)
[ -n "$addr" ] && hyprctl dispatch focuswindow "address:$addr"
