#!/bin/sh
#
# Game mode toggle script
# Disables compositor effects, notifications, and other distractions for gaming
#
# Usage: gamemode.sh [on|off|toggle]
#

GAMEMODE_FILE="/tmp/gamemode_active"
ACTION="${1:-toggle}"

gamemode_on() {
    # Already on?
    if [ -f "$GAMEMODE_FILE" ]; then
        notify-send "Game Mode" "Already active"
        return
    fi
    
    # Mark as active
    touch "$GAMEMODE_FILE"
    
    # Disable compositor
    if pgrep -x picom > /dev/null 2>&1; then
        pkill picom
        echo "picom" >> "$GAMEMODE_FILE"
    fi
    
    # Disable notifications (pause dunst)
    if pgrep -x dunst > /dev/null 2>&1; then
        dunstctl set-paused true 2>/dev/null
        echo "dunst" >> "$GAMEMODE_FILE"
    fi
    
    # Disable screen locker
    if pgrep -x xautolock > /dev/null 2>&1; then
        pkill xautolock
        echo "xautolock" >> "$GAMEMODE_FILE"
    fi
    
    # Disable redshift
    if pgrep -x redshift > /dev/null 2>&1; then
        pkill redshift
        echo "redshift" >> "$GAMEMODE_FILE"
    fi
    
    # Set performance mode if available (FreeBSD)
    if [ "$(uname)" = "FreeBSD" ]; then
        sysctl dev.cpu.0.freq_levels > /dev/null 2>&1 && \
            sudo sysctl dev.cpu.0.freq=999999 2>/dev/null
    fi
    
    # Disable animations in bspwm (set faster response)
    bspc config border_width 1
    bspc config window_gap 0
    
    notify-send -u low "Game Mode" "Enabled - Compositor and distractions disabled"
}

gamemode_off() {
    # Not active?
    if [ ! -f "$GAMEMODE_FILE" ]; then
        notify-send "Game Mode" "Not active"
        return
    fi
    
    # Restore compositor
    if grep -q "picom" "$GAMEMODE_FILE" 2>/dev/null; then
        picom &
    fi
    
    # Resume notifications
    if grep -q "dunst" "$GAMEMODE_FILE" 2>/dev/null; then
        dunstctl set-paused false 2>/dev/null
    fi
    
    # Restore screen locker
    if grep -q "xautolock" "$GAMEMODE_FILE" 2>/dev/null; then
        if command -v i3lock > /dev/null 2>&1; then
            xautolock -detectsleep -time 5 -locker "i3lock -c 2a2f33" &
        elif command -v xlock > /dev/null 2>&1; then
            xautolock -detectsleep -time 5 -locker "xlock -mode blank" &
        fi
    fi
    
    # Restore redshift
    if grep -q "redshift" "$GAMEMODE_FILE" 2>/dev/null; then
        redshift &
    fi
    
    # Restore bspwm settings
    bspc config border_width 2
    bspc config window_gap 8
    
    # Remove marker
    rm -f "$GAMEMODE_FILE"
    
    notify-send -u low "Game Mode" "Disabled - Normal desktop restored"
}

toggle_gamemode() {
    if [ -f "$GAMEMODE_FILE" ]; then
        gamemode_off
    else
        gamemode_on
    fi
}

case "$ACTION" in
    on)
        gamemode_on
        ;;
    off)
        gamemode_off
        ;;
    toggle)
        toggle_gamemode
        ;;
    status)
        if [ -f "$GAMEMODE_FILE" ]; then
            echo "Game mode is ON"
        else
            echo "Game mode is OFF"
        fi
        ;;
    *)
        echo "Usage: $0 [on|off|toggle|status]"
        exit 1
        ;;
esac
