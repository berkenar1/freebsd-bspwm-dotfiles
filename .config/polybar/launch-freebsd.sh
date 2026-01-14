#!/bin/sh
#
# Polybar launch script for FreeBSD
#

# Terminate already running bar instances
killall -q polybar 2>/dev/null

# Wait until the processes have been shut down
while pgrep -u "$(id -u)" -x polybar > /dev/null; do sleep 1; done

# Get network interface
# FreeBSD uses route command which is always available
DEFAULT_NETWORK_INTERFACE=$(route -n get default 2>/dev/null | grep interface | awk '{print $2}')

# Fallback: try to find a wireless or ethernet interface
if [ -z "$DEFAULT_NETWORK_INTERFACE" ]; then
    # Try to find wireless interface
    for iface in wlan0 iwn0 ath0 ral0; do
        if ifconfig "$iface" > /dev/null 2>&1; then
            DEFAULT_NETWORK_INTERFACE="$iface"
            break
        fi
    done
fi

# Fallback to ethernet if no wireless found
if [ -z "$DEFAULT_NETWORK_INTERFACE" ]; then
    for iface in em0 re0 bge0 igb0 ix0; do
        if ifconfig "$iface" > /dev/null 2>&1; then
            DEFAULT_NETWORK_INTERFACE="$iface"
            break
        fi
    done
fi

# Final fallback
if [ -z "$DEFAULT_NETWORK_INTERFACE" ]; then
    DEFAULT_NETWORK_INTERFACE="wlan0"
fi

export DEFAULT_NETWORK_INTERFACE

# Detect external monitor
external_monitor=$(xrandr --query 2>/dev/null | grep 'HDMI.*connected')

if [ -n "$external_monitor" ]; then
    # Get the external monitor name
    ext_name=$(echo "$external_monitor" | awk '{print $1}')
    MONITOR="$ext_name" polybar -c "$HOME/.config/polybar/config.ini" secondary &
fi

# Load bar on primary monitor
polybar -c "$HOME/.config/polybar/config.ini" main &

echo "Polybar launched..."
