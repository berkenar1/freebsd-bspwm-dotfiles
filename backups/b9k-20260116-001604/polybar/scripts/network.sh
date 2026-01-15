#!/bin/sh
# ~/.config/polybar/scripts/network.sh
# Robust network status script for FreeBSD

# Determine default interface (tries routing table first)
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

# Get basic status and IP
status=$(ifconfig "$IF" 2>/dev/null | awk '/status:/{print $2; exit}')
if [ -z "$status" ]; then
    if ifconfig "$IF" 2>/dev/null | awk '/inet /{print; exit}' >/dev/null 2>&1; then
        status="up"
    else
        status="down"
    fi
fi

if [ "$status" != "up" ]; then
    echo " $IF:down"
    exit 0
fi

# Try to get SSID (wireless)
ssid=$(ifconfig "$IF" 2>/dev/null | awk -F': ' '/ssid:/{print $2; exit}')
# Try to get IP
ip=$(ifconfig "$IF" 2>/dev/null | awk '/inet /{print $2; exit}')

if [ -n "$ssid" ]; then
    echo " $ssid"
elif [ -n "$ip" ]; then
    echo " $ip"
else
    echo " $IF:up"
fi
