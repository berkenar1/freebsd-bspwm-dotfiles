#!/bin/sh
# ~/.config/polybar/scripts/network.sh
# Simple network status script for FreeBSD

# Determine interface
IF="${DEFAULT_NETWORK_INTERFACE:-$(route -n get default 2>/dev/null | awk '/interface/ {print $2}' || true)}"
if [ -z "$IF" ]; then
    for i in wlan0 wlan1 iwn0 iwm0 ath0 ral0 run0 urtwn0 em0 em1 igb0 ix0 ixl0 re0 bge0; do
        if ifconfig "$i" >/dev/null 2>&1; then
            IF="$i"
            break
        fi
    done
fi

if [ -z "$IF" ]; then
    echo "NET N/A"
    exit 0
fi

# Get status
status=$(ifconfig "$IF" 2>/dev/null | awk '/status:/{print $2}' | head -1)
if [ -z "$status" ]; then
    if ifconfig "$IF" | grep -q 'inet '; then
        status="up"
    else
        status="down"
    fi
fi

if [ "$status" = "up" ]; then
    ssid=$(ifconfig "$IF" 2>/dev/null | awk -F': ' '/ssid:/{print $2; exit}')
    if [ -n "$ssid" ]; then
        echo "$ssid"
    else
        echo "$IF:up"
    fi
else
    echo "$IF:down"
fi
