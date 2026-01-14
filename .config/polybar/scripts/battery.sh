#!/bin/sh
# ~/.config/polybar/scripts/battery.sh
# Robust FreeBSD battery status fallback (percent + charging state)

# Prefer acpiconf on FreeBSD
if command -v acpiconf >/dev/null 2>&1; then
    out=$(acpiconf -i 0 2>/dev/null)
    if [ -n "$out" ]; then
        # Extract percent (case-insensitive match supporting different output flavors)
        percent=$(echo "$out" | awk -F': ' 'tolower($0) ~ /remaining capacity/ {gsub(/[^0-9]/, "", $2); print $2; exit}')
        # Extract state
        state=$(echo "$out" | awk -F': ' 'tolower($0) ~ /battery state/ {print $2; exit}')
        # Fallback detection
        if [ -z "$state" ]; then
            if echo "$out" | grep -iq "charging"; then state="charging"; fi
            if echo "$out" | grep -iq "discharg"; then state="discharging"; fi
            if echo "$out" | grep -iq "ac connected"; then state="ac"; fi
        fi

        if [ -n "$percent" ]; then
            if echo "$state" | grep -iq "charge"; then
                echo "⚡ ${percent}%"
            elif echo "$state" | grep -iq "discharg"; then
                echo "🔋 ${percent}%"
            else
                echo "${percent}%"
            fi
            exit 0
        fi
    fi
fi

# Fallback to apm
if command -v apm >/dev/null 2>&1; then
    percent=$(apm -l 2>/dev/null)
    if [ -n "$percent" ]; then
        echo "🔋 ${percent}%"
        exit 0
    fi
fi

# No battery info
echo "BAT N/A"
