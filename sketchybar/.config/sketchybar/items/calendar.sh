#!/bin/bash

sketchybar --add item calendar right \
           --set calendar icon=📅 \
                          update_freq=10 \
                          background.color=0x44ffffff \
                          script="$PLUGIN_DIR/calendar.sh"
