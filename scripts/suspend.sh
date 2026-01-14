#!/bin/sh
# scripts/suspend.sh
# Lock the screen and suspend (FreeBSD)
# Usage: suspend.sh

# Lock screen if lockers are available
if command -v i3lock >/dev/null 2>&1; then
    i3lock -c 000000
elif command -v slock >/dev/null 2>&1; then
    slock
elif command -v xlock >/dev/null 2>&1; then
    xlock -mode blank
fi

# small delay to allow lock to engage
sleep 1

# Suspend the system (requires root)
SUSPEND_CMD="/usr/sbin/acpiconf -s 3"
if [ "$(id -u)" -eq 0 ]; then
    $SUSPEND_CMD
else
    # Prefer sudo; user may add NOPASSWD sudoers entry for this command
    if command -v sudo >/dev/null 2>&1; then
        sudo $SUSPEND_CMD
    else
        echo "Cannot suspend: sudo not found and not running as root"
    fi
fi
