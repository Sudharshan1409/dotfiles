#!/usr/bin/env bash

# Query NVIDIA GPU if nvidia-smi is available
if command -v nvidia-smi >/dev/null 2>&1; then
    # Check if GPU is in power-saving suspended/D3cold state (Optimus laptops)
    for pci in /sys/bus/pci/devices/*10de*/power/runtime_status /sys/bus/pci/devices/0000:01:00.0/power/runtime_status; do
        if [ -f "$pci" ] && [ "$(cat "$pci" 2>/dev/null)" = "suspended" ]; then
            echo '{"text": "󰢮 Suspend", "tooltip": "NVIDIA GPU (Power-saving / Suspended)", "class": "gpu-suspended", "percentage": 0}'
            exit 0
        fi
    done

    info=$(nvidia-smi --query-gpu=memory.used,memory.total,utilization.gpu,temperature.gpu,name --format=csv,noheader,nounits 2>/dev/null | head -n 1)
    if [ -n "$info" ]; then
        IFS=',' read -r mem_used mem_total util temp name <<< "$info"
        mem_used="${mem_used// /}"
        mem_total="${mem_total// /}"
        util="${util// /}"
        temp="${temp// /}"
        name="$(echo "$name" | xargs)"

        if [ -n "$mem_used" ] && [ -n "$mem_total" ] && [ "$mem_total" -gt 0 ] 2>/dev/null; then
            read -r used_g total_g pct <<< "$(awk -v u="$mem_used" -v t="$mem_total" 'BEGIN { printf "%.1f %.1f %.0f", u/1024, t/1024, (u/t)*100 }')"
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
