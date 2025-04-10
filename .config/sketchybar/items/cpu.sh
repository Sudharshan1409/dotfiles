#!/bin/bash

sketchybar --add item cpu right \
           --set cpu  update_freq=2 \
                      icon=􀧓  \
                      background.color=0x44ffffff \
                      script="$PLUGIN_DIR/cpu.sh"
