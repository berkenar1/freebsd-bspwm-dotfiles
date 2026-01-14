#!/bin/sh
#
# Brightness control script for FreeBSD
# Works with backlight-utils, intel_backlight, or ACPI
#
# Usage: brightness.sh [inc|dec|set] [value]
#   brightness.sh inc 5    # Increase by 5%
#   brightness.sh dec 5    # Decrease by 5%
#   brightness.sh set 50   # Set to 50%
#   brightness.sh get      # Get current brightness
#

ACTION="${1:-get}"
VALUE="${2:-5}"

# Get current brightness (returns 0-100)
get_brightness() {
    if command -v backlight > /dev/null 2>&1; then
        backlight
    elif command -v intel_backlight > /dev/null 2>&1; then
        intel_backlight | grep -o '[0-9]*'
    elif [ -f /sys/class/backlight/*/brightness ]; then
        # Linux sysfs method
        max=$(cat /sys/class/backlight/*/max_brightness 2>/dev/null | head -1)
        cur=$(cat /sys/class/backlight/*/brightness 2>/dev/null | head -1)
        if [ -n "$max" ] && [ -n "$cur" ]; then
            echo $((cur * 100 / max))
        fi
    else
        # FreeBSD ACPI method
        sysctl -n hw.acpi.video.lcd0.brightness 2>/dev/null || echo "0"
    fi
}

# Set brightness (accepts 0-100)
set_brightness() {
    level="$1"
    
    # Clamp to valid range
    [ "$level" -lt 1 ] && level=1
    [ "$level" -gt 100 ] && level=100
    
    if command -v backlight > /dev/null 2>&1; then
        backlight "$level"
    elif command -v intel_backlight > /dev/null 2>&1; then
        intel_backlight "$level"
    elif [ -f /sys/class/backlight/*/brightness ]; then
        # Linux sysfs method
        max=$(cat /sys/class/backlight/*/max_brightness 2>/dev/null | head -1)
        if [ -n "$max" ]; then
            new_val=$((level * max / 100))
            echo "$new_val" | sudo tee /sys/class/backlight/*/brightness > /dev/null
        fi
    else
        # FreeBSD ACPI method
        sudo sysctl hw.acpi.video.lcd0.brightness="$level" > /dev/null 2>&1
    fi
    
    # Send notification
    if command -v notify-send > /dev/null 2>&1; then
        notify-send -t 1000 -h int:value:"$level" -h string:synchronous:brightness "Brightness: ${level}%"
    fi
}

case "$ACTION" in
    get)
        get_brightness
        ;;
    inc)
        current=$(get_brightness)
        new_level=$((current + VALUE))
        set_brightness "$new_level"
        ;;
    dec)
        current=$(get_brightness)
        new_level=$((current - VALUE))
        set_brightness "$new_level"
        ;;
    set)
        set_brightness "$VALUE"
        ;;
    *)
        echo "Usage: $0 [inc|dec|set|get] [value]"
        exit 1
        ;;
esac
