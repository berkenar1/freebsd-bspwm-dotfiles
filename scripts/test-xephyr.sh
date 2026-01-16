#!/bin/sh
# scripts/test-xephyr.sh
# Quick helper to run a nested X session (Xephyr) and test bspwm + sxhkd + polybar
# Usage: ./scripts/test-xephyr.sh [DISPLAY=:1] [RESOLUTION=1280x720]

# Parse args: [DISPLAY] [RESOLUTION] [--no-cleanup|--leave-running]
SET_DISPLAY="${1:-:1}"
RESOLUTION="${2:-1280x720}"
LEAVE_RUNNING=false
if [ "${3:-}" = "--no-cleanup" ] || [ "${3:-}" = "--leave-running" ]; then
    LEAVE_RUNNING=true
fi

command -v Xephyr >/dev/null 2>&1 || { echo "Xephyr not found; install it (pkg install xorg)"; exit 1; }

# Prepare log directory
LOGDIR="/tmp/test-xephyr-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$LOGDIR"
XE_LOG="$LOGDIR/xephyr.err"
BSPWM_LOG="$LOGDIR/bspwm.out"
POLY_LOG="$LOGDIR/polybar.out"
SXH_LOG="$LOGDIR/sxhkd.out"

# Start nested X server (log to file)
Xephyr -br -ac -noreset -screen "$RESOLUTION" "$SET_DISPLAY" > "$XE_LOG" 2>&1 &
XE_PID=$!

echo "Started Xephyr (PID $XE_PID) on $SET_DISPLAY with $RESOLUTION"
echo "Logs: $LOGDIR"
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
    DISPLAY="$SET_DISPLAY" sxhkd -c "$HOME/.config/sxhkd/sxhkdrc" > "$SXH_LOG" 2>&1 &
    SXH_PID=$!
    echo "Started sxhkd (PID $SXH_PID)"
else
    echo "sxhkd config not found; skipping sxhkd"
fi

# Start bspwm (log to file)
DISPLAY="$SET_DISPLAY" sh -c 'exec bspwm' > "$BSPWM_LOG" 2>&1 &
BSPWM_PID=$!
echo "Started bspwm (PID $BSPWM_PID)"

# Give bspwm a moment to start and check for common failure modes
sleep 1
# If bspwm exited quickly or logged a configuration execution error, replace with a minimal test config and restart
if ! kill -0 "$BSPWM_PID" 2>/dev/null || ( [ -f "$BSPWM_LOG" ] && grep -q "Couldn't execute the configuration file" "$BSPWM_LOG" 2>/dev/null ); then
    echo "bspwm failed to start or config execution failed - applying fallback minimal bspwmrc (logged in $LOGDIR)"
    # Backup existing config
    if [ -f "$HOME/.config/bspwm/bspwmrc" ]; then
        mkdir -p "$LOGDIR/backup"
        cp -p "$HOME/.config/bspwm/bspwmrc" "$LOGDIR/backup/bspwmrc.before-fallback" 2>/dev/null || true
    fi

    # Write a minimal bspwmrc that sets a background and spawns a simple X client so we see something on screen
    mkdir -p "$HOME/.config/bspwm"
    cat > "$HOME/.config/bspwm/bspwmrc" <<'BSPF'
#!/bin/sh
# Minimal test bspwmrc used by test-xephyr.sh fallback
xsetroot -solid "#222222" &
# Spawn a visible client to ensure mapping - prefer xmessage, then xclock
if command -v xmessage >/dev/null 2>&1; then
    xmessage -buttons OK:0 "bspwm test session" &
elif command -v xclock >/dev/null 2>&1; then
    xclock &
else
    # As a last resort spawn a small loop that keeps a window mapped (if xterm available)
    if command -v xterm >/dev/null 2>&1; then
        xterm -hold -e "echo 'bspwm test session'; sleep 300" &
    fi
fi
# Keep script short - bspwm runs independently
BSPF
    chmod +x "$HOME/.config/bspwm/bspwmrc"

    # If previous bspwm process still exists, kill it, then restart
    kill "$BSPWM_PID" 2>/dev/null || true
    sleep 0.4
    DISPLAY="$SET_DISPLAY" sh -c 'exec bspwm' > "$BSPWM_LOG" 2>&1 &
    BSPWM_PID=$!
    echo "Restarted bspwm with minimal test config (PID $BSPWM_PID). Logs: $BSPWM_LOG"

    # Wait a short while for windows to map, then check for any mapped clients
    sleep 1
    if ! xlsclients -display "$SET_DISPLAY" >/dev/null 2>&1 || [ "$(xlsclients -display "$SET_DISPLAY" | wc -l)" -eq 0 ]; then
        echo "No clients detected on $SET_DISPLAY; launching a guaranteed test client (xmessage/xclock/xterm)"
        if command -v xmessage >/dev/null 2>&1; then
            DISPLAY="$SET_DISPLAY" xmessage -center -buttons OK:0 "bspwm test session (forced)" > "$LOGDIR/forced-client.out" 2>&1 &
            FC_PID=$!
        elif command -v xclock >/dev/null 2>&1; then
            DISPLAY="$SET_DISPLAY" xclock > "$LOGDIR/forced-client.out" 2>&1 &
            FC_PID=$!
        elif command -v xterm >/dev/null 2>&1; then
            DISPLAY="$SET_DISPLAY" xterm -hold -e "echo 'bspwm test session' ; sleep 300" > "$LOGDIR/forced-client.out" 2>&1 &
            FC_PID=$!
        else
            echo "No GUI fallback client available to force a window"
            FC_PID=0
        fi
        echo "Forced client PID: $FC_PID (logs $LOGDIR/forced-client.out)"
    else
        echo "Client(s) detected on $SET_DISPLAY" 
    fi
fi
# Start polybar via launch script or direct call (log to file)
if [ -x "$HOME/.config/polybar/launch.sh" ]; then
    DISPLAY="$SET_DISPLAY" "$HOME/.config/polybar/launch.sh" > "$POLY_LOG" 2>&1 &
    POLY_PID=$!
    echo "Started polybar via launch.sh (PID $POLY_PID)"
elif [ -f "$HOME/.config/polybar/config.ini" ]; then
    DISPLAY="$SET_DISPLAY" polybar -c "$HOME/.config/polybar/config.ini" main > "$POLY_LOG" 2>&1 &
    POLY_PID=$!
    echo "Started polybar (direct) (PID $POLY_PID)"
else
    echo "Polybar config not found; skipping polybar"
fi

# Cleanup handler
cleanup() {
    echo "Cleaning up nested session..."
    echo "Logs are at: $LOGDIR"
    [ -n "$POLY_PID" ] && kill "$POLY_PID" 2>/dev/null || true
    [ -n "$BSPWM_PID" ] && kill "$BSPWM_PID" 2>/dev/null || true
    [ -n "$SXH_PID" ] && kill "$SXH_PID" 2>/dev/null || true
    [ -n "$XE_PID" ] && kill "$XE_PID" 2>/dev/null || true
    exit 0
}

if [ "$LEAVE_RUNNING" = "true" ]; then
    echo "Leave-running mode enabled; not cleaning up automatically."
    echo "Xephyr PID: $XE_PID"
    echo "bspwm PID: $BSPWM_PID"
    [ -n "$POLY_PID" ] && echo "polybar PID: $POLY_PID"
    [ -n "$SXH_PID" ] && echo "sxhkd PID: $SXH_PID"
    echo "Logs: $LOGDIR"
    echo "To stop the nested session run: kill $BSPWM_PID $POLY_PID $SXH_PID $XE_PID 2>/dev/null || true"
    # Wait for Xephyr (but do not clean up on exit)
    wait "$XE_PID"
else
    trap cleanup INT TERM EXIT
    # Wait for Xephyr to exit (user closes the window) — trap will fire
    wait "$XE_PID"
fi