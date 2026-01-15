#!/bin/sh
# scripts/test-xephyr.sh
# Quick helper to run a nested X session (Xephyr) and test bspwm + sxhkd + polybar
# Usage: ./scripts/test-xephyr.sh [DISPLAY=:1] [RESOLUTION=1280x720]

SET_DISPLAY="${1:-:1}"
RESOLUTION="${2:-1280x720}"

command -v Xephyr >/dev/null 2>&1 || { echo "Xephyr not found; install it (pkg install xorg)"; exit 1; }

# Start nested X server
Xephyr -br -ac -noreset -screen "$RESOLUTION" "$SET_DISPLAY" &
XE_PID=$!

echo "Started Xephyr (PID $XE_PID) on $SET_DISPLAY with $RESOLUTION"
# Give Xephyr a moment to start
sleep 1

# Start a dbus session if available (some polybar modules require it)
if command -v dbus-launch >/dev/null 2>&1; then
    eval "$(dbus-launch --sh-syntax --exit-with-session)" || true
    echo "Started dbus session"
fi

export DISPLAY="$SET_DISPLAY"

# Start sxhkd if config exists
if [ -f "$HOME/.config/sxhkd/sxhkdrc" ]; then
    DISPLAY="$SET_DISPLAY" sxhkd -c "$HOME/.config/sxhkd/sxhkdrc" &
    SXH_PID=$!
    echo "Started sxhkd (PID $SXH_PID)"
else
    echo "sxhkd config not found; skipping sxhkd"
fi

# Start bspwm
DISPLAY="$SET_DISPLAY" bspwm &
BSPWM_PID=$!
echo "Started bspwm (PID $BSPWM_PID)"

# Start polybar via launch script or direct call
if [ -x "$HOME/.config/polybar/launch.sh" ]; then
    DISPLAY="$SET_DISPLAY" "$HOME/.config/polybar/launch.sh" &
    POLY_PID=$!
    echo "Started polybar via launch.sh (PID $POLY_PID)"
elif [ -f "$HOME/.config/polybar/config.ini" ]; then
    DISPLAY="$SET_DISPLAY" polybar -c "$HOME/.config/polybar/config.ini" main &
    POLY_PID=$!
    echo "Started polybar (direct) (PID $POLY_PID)"
else
    echo "Polybar config not found; skipping polybar"
fi

# Cleanup handler
cleanup() {
    echo "Cleaning up nested session..."
    [ -n "$POLY_PID" ] && kill "$POLY_PID" 2>/dev/null || true
    [ -n "$BSPWM_PID" ] && kill "$BSPWM_PID" 2>/dev/null || true
    [ -n "$SXH_PID" ] && kill "$SXH_PID" 2>/dev/null || true
    [ -n "$XE_PID" ] && kill "$XE_PID" 2>/dev/null || true
    exit 0
}
trap cleanup INT TERM EXIT

# Wait for Xephyr to exit (user closes the window) — trap will fire
wait "$XE_PID"