#!/bin/bash

# Get RAM for display (in GB)
ram_display=$(free -h --si | awk '/^Mem:/ {print $3 "/" $2}')

# Get detailed info for tooltip (with GiB for accuracy)
tooltip_details=$(free -h)

# Escape special characters for JSON
tooltip_details_escaped=$(echo "$tooltip_details" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed -e ':a;N;$!ba;s/\n/\\n/g')

# Output JSON
echo "{\"text\": \"🧠 $ram_display\", \"tooltip\": \"$tooltip_details_escaped\"}"