#!/bin/sh
# ~/.config/polybar/scripts/caffeine_status.sh
FLAG="$HOME/.config/bspwm/caffeine"
if [ -f "$FLAG" ]; then
    echo "☕ ON"
else
    echo "☕ OFF"
fi