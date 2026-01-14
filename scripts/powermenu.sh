#!/bin/sh
#
# Power menu script for bspwm (FreeBSD compatible)
# Provides shutdown, reboot, suspend, lock, and logout options via rofi
#
# Usage: powermenu.sh
#

# Define options
LOCK="  Lock"
LOGOUT="  Logout"
SUSPEND="  Suspend"
REBOOT="  Reboot"
SHUTDOWN="  Shutdown"

# Rofi command
rofi_cmd() {
    rofi -dmenu -i -p "Power" -theme-str 'window {width: 15em;}'
}

# Confirmation dialog
confirm_cmd() {
    echo -e "Yes\nNo" | rofi -dmenu -i -p "Are you sure?" -theme-str 'window {width: 10em;}'
}

# Lock screen
lock_screen() {
    if command -v i3lock > /dev/null 2>&1; then
        i3lock -c 2a2f33
    elif command -v xlock > /dev/null 2>&1; then
        xlock -mode blank
    elif command -v slock > /dev/null 2>&1; then
        slock
    else
        notify-send "No screen locker found" "Install i3lock, xlock, or slock"
    fi
}

# Actions
run_cmd() {
    case "$1" in
        "$LOCK")
            lock_screen
            ;;
        "$LOGOUT")
            bspc quit
            ;;
        "$SUSPEND")
            lock_screen &
            sleep 1
            # FreeBSD suspend command
            if [ "$(uname)" = "FreeBSD" ]; then
                sudo acpiconf -s 3 || sudo zzz
            else
                systemctl suspend || sudo pm-suspend
            fi
            ;;
        "$REBOOT")
            # FreeBSD reboot
            if [ "$(uname)" = "FreeBSD" ]; then
                sudo shutdown -r now
            else
                systemctl reboot || sudo reboot
            fi
            ;;
        "$SHUTDOWN")
            # FreeBSD shutdown
            if [ "$(uname)" = "FreeBSD" ]; then
                sudo shutdown -p now
            else
                systemctl poweroff || sudo poweroff
            fi
            ;;
    esac
}

# Show menu
chosen=$(printf '%s\n%s\n%s\n%s\n%s' "$LOCK" "$LOGOUT" "$SUSPEND" "$REBOOT" "$SHUTDOWN" | rofi_cmd)

# If nothing chosen, exit
[ -z "$chosen" ] && exit 0

# For lock, no confirmation needed
if [ "$chosen" = "$LOCK" ]; then
    run_cmd "$chosen"
    exit 0
fi

# Ask for confirmation
confirm=$(confirm_cmd)

if [ "$confirm" = "Yes" ]; then
    run_cmd "$chosen"
fi
