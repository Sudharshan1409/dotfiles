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
        echo " CPU: $(lscpu | grep "Model name" | sed 's/Model name:[ \t]*//')"
        ;;
    gpu)
        echo " GPU: $(lspci | grep -E "VGA|3D" | sed 's/.*: //')"
        ;;
esac
