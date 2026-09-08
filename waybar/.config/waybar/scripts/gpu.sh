#!/usr/bin/env bash

# Query NVIDIA GPU if nvidia-smi is available
if command -v nvidia-smi >/dev/null 2>&1; then
    info=$(nvidia-smi --query-gpu=memory.used,memory.total,utilization.gpu,temperature.gpu,name --format=csv,noheader,nounits 2>/dev/null | head -n 1)
    if [ -n "$info" ]; then
        IFS=',' read -r mem_used mem_total util temp name <<< "$info"
        mem_used=$(echo "$mem_used" | tr -d ' ')
        mem_total=$(echo "$mem_total" | tr -d ' ')
        util=$(echo "$util" | tr -d ' ')
        temp=$(echo "$temp" | tr -d ' ')
        name=$(echo "$name" | sed 's/^[ \t]*//')

        if [ -n "$mem_used" ] && [ -n "$mem_total" ] && [ "$mem_total" -gt 0 ] 2>/dev/null; then
            used_g=$(awk "BEGIN {printf \"%.1f\", $mem_used / 1024}")
            total_g=$(awk "BEGIN {printf \"%.1f\", $mem_total / 1024}")
            pct=$(awk "BEGIN {printf \"%.0f\", ($mem_used / $mem_total) * 100}")

            echo "{\"text\": \"󰢮 ${used_g}G/${total_g}G\", \"tooltip\": \"${name}\nGPU Util: ${util}%\nVRAM: ${used_g}G / ${total_g}G (${pct}%)\nTemp: ${temp}°C\", \"class\": \"gpu\", \"percentage\": ${pct}}"
            exit 0
        fi
    fi
fi

# Query AMD GPU via sysfs if available
for card in /sys/class/drm/card*/device; do
    if [ -f "$card/mem_info_vram_used" ] && [ -f "$card/mem_info_vram_total" ]; then
        vram_used=$(cat "$card/mem_info_vram_used" 2>/dev/null)
        vram_total=$(cat "$card/mem_info_vram_total" 2>/dev/null)
        if [ -n "$vram_used" ] && [ -n "$vram_total" ] && [ "$vram_total" -gt 0 ] 2>/dev/null; then
            used_g=$(awk "BEGIN {printf \"%.1f\", $vram_used / 1073741824}")
            total_g=$(awk "BEGIN {printf \"%.1f\", $vram_total / 1073741824}")
            pct=$(awk "BEGIN {printf \"%.0f\", ($vram_used / $vram_total) * 100}")
            echo "{\"text\": \"󰢮 ${used_g}G/${total_g}G\", \"tooltip\": \"AMD Radeon GPU\nVRAM: ${used_g}G / ${total_g}G (${pct}%)\", \"class\": \"gpu\", \"percentage\": ${pct}}"
            exit 0
        fi
    fi
done

# If no dedicated GPU is detected, output empty string to hide module
echo '{"text": ""}'
