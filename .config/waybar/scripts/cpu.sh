#!/bin/bash

# Read the first line of /proc/stat
read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat

# Calculate total and idle time
idle_total=$((idle + iowait))
total=$((user + nice + system + idle + iowait + irq + softirq + steal))

# Read previous values
if [ -f /tmp/waybar_cpu_prev ]; then
    . /tmp/waybar_cpu_prev
fi

# Calculate usage
prev_idle_total=${prev_idle_total:-0}
prev_total=${prev_total:-0}
total_diff=$((total - prev_total))
idle_diff=$((idle_total - prev_idle_total))
usage=$((100 * (total_diff - idle_diff) / total_diff))

# Save current values
echo "prev_idle_total=$idle_total" > /tmp/waybar_cpu_prev
echo "prev_total=$total" >> /tmp/waybar_cpu_prev

echo "$usage"
