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
    # Try to find wireless interface (FreeBSD common names)
    for iface in wlan0 wlan1 iwn0 iwm0 ath0 ral0 rum0 run0 urtwn0; do
        if ifconfig "$iface" > /dev/null 2>&1; then
            DEFAULT_NETWORK_INTERFACE="$iface"
            break
        fi
    done
fi

# Fallback to ethernet if no wireless found (FreeBSD common names)
if [ -z "$DEFAULT_NETWORK_INTERFACE" ]; then
    for iface in em0 em1 igb0 igb1 ix0 ixl0 re0 bge0 bce0 msk0 age0 alc0 ale0 fxp0 dc0 rl0 sis0 sk0 ste0 tl0 tx0 vr0 wb0 xl0; do
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
