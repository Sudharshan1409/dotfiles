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
if [ "$total_diff" -gt 0 ]; then
    usage=$((100 * (total_diff - idle_diff) / total_diff))
else
    usage=0
fi

# Save current values
echo "prev_idle_total=$idle_total" > /tmp/waybar_cpu_prev
echo "prev_total=$total" >> /tmp/waybar_cpu_prev

# Build tooltip: load average + top 5 CPU-hungry processes
load_avg=$(awk '{print $1", "$2", "$3}' /proc/loadavg)
top_procs=$(ps -eo pcpu,comm --sort=-pcpu --no-headers | head -n 5 | awk '{printf "  %5.1f%%  %s\\n", $1, $2}')

tooltip="<b>CPU: ${usage}%</b>\nLoad avg: ${load_avg}\n\n<b>Top processes</b>\n${top_procs}"

printf '{"text":"%s","tooltip":"%s","percentage":%d,"class":"%s"}\n' \
    "$usage" "$tooltip" "$usage" \
    "$([ "$usage" -ge 90 ] && echo critical || echo normal)"
