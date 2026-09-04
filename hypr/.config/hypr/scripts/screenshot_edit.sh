#!/bin/bash
grim -g "$(slurp)" - | satty --filename - \
    --output-filename "/tmp/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png" \
    --early-exit \
    --actions-on-enter save-to-clipboard \
    --save-after-copy \
    --copy-command 'wl-copy'