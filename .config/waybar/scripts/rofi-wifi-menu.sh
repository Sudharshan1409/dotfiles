#!/usr/bin/env bash

# Rofi Wi-Fi menu

# Rescan for networks
nmcli device wifi rescan

# Get a list of available Wi-Fi networks, including active one
networks=$(nmcli -fields active,ssid,signal,security device wifi list | grep -E "^yes|^no" | awk -F' {2,}' '{if ($3 >= 50 && $2 != "") {if (!seen[$2]++) {printf "%03d %s%s (%s%%)\n", $3, ($1 == "yes" ? "*" : ""), $2, $3}}}' | sort -nr | awk '{$1=""; print substr($0,2)}')

chosen_option=$(echo -e "$networks\n--enable-wifi\n--disable-wifi\n--settings" | rofi -dmenu -i -p "Wi-Fi Networks" -theme ~/.config/rofi/bluetooth-menu.rasi)

if [ "$chosen_option" ]; then
    case "$chosen_option" in
        "--enable-wifi")
            nmcli radio wifi on
            ;;
        "--disable-wifi")
            nmcli radio wifi off
            ;;
        "--settings")
            nm-connection-editor &
            ;;
        *)
            ssid=$(echo "$chosen_option" | sed 's/^\*//' | awk '{print $1}')
            echo "DEBUG: SSID is '$ssid'" >> /tmp/rofi_wifi_debug.log
            
            # Check if the network requires a password
            security=$(nmcli -fields security device wifi list | grep "$ssid" | awk '{print $2}')

            if [ "$security" = "--" ]; then
                # No password required
                nmcli device wifi connect "$ssid"
            else
                # Password required
                password=$(rofi -dmenu -p "Password for $ssid" -placeholder "Enter password" -theme ~/.config/rofi/bluetooth-menu.rasi)
                if [ "$password" ]; then
                    nmcli device wifi connect "$ssid" password "$password"
                fi
            fi
            ;;
    esac
fi
