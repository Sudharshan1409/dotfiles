#!/bin/bash

sketchybar --add item battery right \
           --set battery update_freq=120 \
                         script="$PLUGIN_DIR/battery.sh" \
                         background.color=0x44ffffff \
           --subscribe battery system_woke power_source_change
