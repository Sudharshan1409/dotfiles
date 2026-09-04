#!/bin/bash

# Scratchpad terminal: toggle a floating Ghostty on the "scratch" special workspace.
#
# Existence is detected by workspace membership rather than class — ghostty's
# single-instance mode may ignore --class, so a class-based check is unreliable.
# Inline dispatcher rules ([workspace special:scratch; float; size; center])
# guarantee placement even if windowrules don't match the resulting class.
# --gtk-single-instance=false forces a fresh process so those rules can apply.

if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.workspace.name == "special:scratch")' > /dev/null 2>&1; then
    hyprctl dispatch togglespecialworkspace scratch
else
    hyprctl dispatch exec "[workspace special:scratch; float; size 85% 80%; center] ghostty --gtk-single-instance=false --class=scratchpad-terminal"
fi
