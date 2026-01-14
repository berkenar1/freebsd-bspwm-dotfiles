#!/bin/sh
#
# Volume control script with notifications
# Works with PulseAudio (pamixer), ALSA (amixer), or FreeBSD mixer
#
# Usage: volume.sh [up|down|mute|get] [value]
#   volume.sh up 5      # Increase by 5%
#   volume.sh down 5    # Decrease by 5%
#   volume.sh mute      # Toggle mute
#   volume.sh get       # Get current volume
#

ACTION="${1:-get}"
VALUE="${2:-5}"

# Icons for notifications
ICON_MUTED="audio-volume-muted"
ICON_LOW="audio-volume-low"
ICON_MEDIUM="audio-volume-medium"
ICON_HIGH="audio-volume-high"

get_icon() {
    vol=$1
    muted=$2
    if [ "$muted" = "yes" ] || [ "$muted" = "true" ] || [ "$vol" -eq 0 ]; then
        echo "$ICON_MUTED"
    elif [ "$vol" -lt 33 ]; then
        echo "$ICON_LOW"
    elif [ "$vol" -lt 66 ]; then
        echo "$ICON_MEDIUM"
    else
        echo "$ICON_HIGH"
    fi
}

# Get current volume and mute status
get_volume() {
    if command -v pamixer > /dev/null 2>&1; then
        pamixer --get-volume
    elif command -v pactl > /dev/null 2>&1; then
        pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1 | tr -d '%'
    elif command -v amixer > /dev/null 2>&1; then
        amixer sget Master | grep -oP '\d+%' | head -1 | tr -d '%'
    elif command -v mixer > /dev/null 2>&1; then
        # FreeBSD mixer
        mixer vol | awk -F: '{print $2}' | tr -d ' ' | cut -d: -f1
    else
        echo "0"
    fi
}

get_mute() {
    if command -v pamixer > /dev/null 2>&1; then
        pamixer --get-mute && echo "yes" || echo "no"
    elif command -v pactl > /dev/null 2>&1; then
        pactl get-sink-mute @DEFAULT_SINK@ | grep -q "yes" && echo "yes" || echo "no"
    elif command -v amixer > /dev/null 2>&1; then
        amixer sget Master | grep -q '\[off\]' && echo "yes" || echo "no"
    else
        echo "no"
    fi
}

set_volume() {
    direction=$1
    val=$2
    
    if command -v pamixer > /dev/null 2>&1; then
        pamixer -u  # Unmute first
        if [ "$direction" = "up" ]; then
            pamixer -i "$val"
        else
            pamixer -d "$val"
        fi
    elif command -v pactl > /dev/null 2>&1; then
        pactl set-sink-mute @DEFAULT_SINK@ 0
        if [ "$direction" = "up" ]; then
            pactl set-sink-volume @DEFAULT_SINK@ "+${val}%"
        else
            pactl set-sink-volume @DEFAULT_SINK@ "-${val}%"
        fi
    elif command -v amixer > /dev/null 2>&1; then
        amixer sset Master unmute
        if [ "$direction" = "up" ]; then
            amixer sset Master "${val}%+"
        else
            amixer sset Master "${val}%-"
        fi
    elif command -v mixer > /dev/null 2>&1; then
        # FreeBSD mixer
        if [ "$direction" = "up" ]; then
            mixer vol "+$val"
        else
            mixer vol "-$val"
        fi
    fi
}

toggle_mute() {
    if command -v pamixer > /dev/null 2>&1; then
        pamixer -t
    elif command -v pactl > /dev/null 2>&1; then
        pactl set-sink-mute @DEFAULT_SINK@ toggle
    elif command -v amixer > /dev/null 2>&1; then
        amixer sset Master toggle
    elif command -v mixer > /dev/null 2>&1; then
        mixer vol ^mute
    fi
}

send_notification() {
    vol=$(get_volume)
    muted=$(get_mute)
    icon=$(get_icon "$vol" "$muted")
    
    if [ "$muted" = "yes" ]; then
        notify-send -t 1500 -i "$icon" -h string:synchronous:volume "Volume" "Muted"
    else
        notify-send -t 1500 -i "$icon" -h int:value:"$vol" -h string:synchronous:volume "Volume" "${vol}%"
    fi
}

case "$ACTION" in
    get)
        get_volume
        ;;
    up)
        set_volume up "$VALUE"
        send_notification
        ;;
    down)
        set_volume down "$VALUE"
        send_notification
        ;;
    mute)
        toggle_mute
        send_notification
        ;;
    *)
        echo "Usage: $0 [up|down|mute|get] [value]"
        exit 1
        ;;
esac
