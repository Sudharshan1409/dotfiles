#!/bin/bash

# OS Name
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ICON="" # Generic Linux icon by default
    case ${ID} in
        arch) OS_ICON="";;
        ubuntu) OS_ICON="";;
        debian) OS_ICON="";;
        fedora) OS_ICON="";;
    esac
    OS_STRING="$OS_ICON $NAME"
else
    OS_STRING=" $(lsb_release -is)"
fi

# Package Count
if command -v pacman &> /dev/null; then
    PACKAGES="󰏖 Packages: $(pacman -Q | wc -l)"
elif command -v dpkg &> /dev/null; then
    PACKAGES="󰏖 Packages: $(dpkg-query -f '.\n' -W | wc -l)"
elif command -v rpm &> /dev/null; then
    PACKAGES="󰏖 Packages: $(rpm -qa | wc -l)"
else
    PACKAGES=""
fi

# Uptime
UPTIME=" Uptime: $(uptime -p | sed 's/up //')"

case "$1" in
    os)
        echo "$OS_STRING"
        ;;
    uptime)
        echo "$UPTIME"
        ;;
    packages)
        echo "$PACKAGES"
        ;;
    kernel)
        echo " Kernel: $(uname -r)"
        ;;
    shell)
        echo " Shell: $($SHELL --version | head -n 1)"
        ;;
    cpu)
        cpu_model=$(lscpu 2>/dev/null | grep "Model name" | head -n 1 | sed 's/Model name:[ \t]*//')
        echo " CPU: ${cpu_model:-$(uname -p)}"
        ;;
    gpu)
        gpu_info=$(lspci 2>/dev/null | grep -E "VGA|3D" | while IFS= read -r line; do
            vendor=""
            [[ "$line" =~ Intel ]] && vendor="Intel "
            [[ "$line" =~ NVIDIA ]] && vendor="NVIDIA "
            [[ "$line" =~ AMD|ATI ]] && vendor="AMD "
            if [[ "$line" =~ \[([^]]+)\] ]]; then
                echo "${vendor}${BASH_REMATCH[1]}"
            else
                cleaned=$(echo "$line" | sed 's/.*: //' | sed 's/ (rev .*)//')
                echo "${cleaned}"
            fi
        done | paste -sd ',' - | sed 's/,/, /g')
        echo " GPU: ${gpu_info:-Unknown}"
        ;;
esac
