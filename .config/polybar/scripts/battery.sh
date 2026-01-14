#!/bin/sh
# ~/.config/polybar/scripts/battery.sh
# Simple FreeBSD battery status fallback

# Try acpiconf (FreeBSD)
if command -v acpiconf >/dev/null 2>&1; then
    out=$(acpiconf -i 0 2>/dev/null)
    if echo "$out" | grep -iq 'remaining capacity'; then
        percent=$(echo "$out" | awk -F': ' '/Remaining capacity/ {print $2}' | tr -d '%')
        echo "$percent%"
        exit 0
    fi
fi

# Try apm
if command -v apm >/dev/null 2>&1; then
    if apm -l >/dev/null 2>&1; then
        percent=$(apm -l 2>/dev/null)
        echo "$percent%"
        exit 0
    fi
fi

# If no battery info, print N/A
echo "BAT N/A"
