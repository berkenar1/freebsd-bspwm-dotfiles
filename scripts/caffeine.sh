#!/bin/sh
# scripts/caffeine.sh
# Toggle 'caffeine' mode to prevent auto-lock / auto-suspend and disable DPMS
# Usage: caffeine.sh [on|off|toggle|status]

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
CFG_DIR="$XDG_CONFIG_HOME/bspwm"
FLAG_FILE="$CFG_DIR/caffeine"
STATE_FILE="$XDG_CACHE_HOME/caffeine/state"

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Caffeine" "$1"
    else
        echo "$1"
    fi
}

enable() {
    mkdir -p "$CFG_DIR" "$XDG_CACHE_HOME/caffeine"
    # Save current DPMS and screensaver settings (best-effort)
    xset q > "$STATE_FILE" 2>/dev/null || true

    # Disable screensaver and DPMS
    if command -v xset >/dev/null 2>&1; then
        xset s off >/dev/null 2>&1 || true
        xset -dpms >/dev/null 2>&1 || true
    fi

    # Stop autolock services
    pgrep -x xautolock >/dev/null 2>&1 && pkill -x xautolock
    pgrep -x xss-lock >/dev/null 2>&1 && pkill -x xss-lock

    touch "$FLAG_FILE"
    notify "Caffeine mode enabled — auto-sleep and auto-lock disabled"
}

restore_defaults() {
    # Apply sane defaults used by autostart (best-effort restore)
    if command -v xset >/dev/null 2>&1; then
        xset s 300 300 >/dev/null 2>&1 || true
        xset +dpms >/dev/null 2>&1 || true
        xset dpms 600 900 1200 >/dev/null 2>&1 || true
    fi
}

start_autolock() {
    # Start xss-lock or xautolock like autostart
    if command -v xss-lock >/dev/null 2>&1 && command -v i3lock >/dev/null 2>&1; then
        xss-lock -- i3lock -c 000000 &
    elif command -v xautolock >/dev/null 2>&1; then
        xautolock -detectsleep -time 30 -locker "$HOME/.local/scripts/suspend.sh" &
    fi
}

disable() {
    rm -f "$FLAG_FILE" || true
    restore_defaults
    start_autolock
    notify "Caffeine mode disabled — auto-sleep and auto-lock restored"
}

status() {
    if [ -f "$FLAG_FILE" ]; then
        echo "enabled"
    else
        echo "disabled"
    fi
}

case "$1" in
    on|enable)
        enable
        ;;
    off|disable)
        disable
        ;;
    toggle)
        if [ -f "$FLAG_FILE" ]; then
            disable
        else
            enable
        fi
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 [on|off|toggle|status]"
        exit 1
        ;;
esac
