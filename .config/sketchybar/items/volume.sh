#!/bin/bash

sketchybar --add item volume right \
           --set volume script="$PLUGIN_DIR/volume.sh" \
                 background.color=0x44ffffff \
           --subscribe volume volume_change \
