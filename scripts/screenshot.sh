#!/bin/sh
#
# Screenshot script with multiple modes
# Supports full screen, area selection, and window capture
# Works with scrot, maim, or import (ImageMagick)
#
# Usage: screenshot.sh [full|area|window|edit]
#   screenshot.sh full    # Capture full screen
#   screenshot.sh area    # Select area to capture
#   screenshot.sh window  # Capture focused window
#   screenshot.sh edit    # Capture area and open in editor
#

MODE="${1:-full}"
SCREENSHOT_DIR="${HOME}/Pictures/Screenshots"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
FILENAME="screenshot-${TIMESTAMP}.png"
FILEPATH="${SCREENSHOT_DIR}/${FILENAME}"

# Create screenshot directory if it doesn't exist
mkdir -p "$SCREENSHOT_DIR"

# Notification sound (optional)
play_sound() {
    if command -v paplay > /dev/null 2>&1; then
        paplay /usr/share/sounds/freedesktop/stereo/camera-shutter.oga 2>/dev/null &
    elif command -v aplay > /dev/null 2>&1; then
        aplay /usr/share/sounds/freedesktop/stereo/camera-shutter.wav 2>/dev/null &
    fi
}

# Send notification
notify_screenshot() {
    if command -v notify-send > /dev/null 2>&1; then
        notify-send -i "$FILEPATH" "Screenshot saved" "$FILENAME"
    fi
}

# Copy to clipboard
copy_to_clipboard() {
    # Prefer Wayland tools if available
    if command -v wl-copy >/dev/null 2>&1; then
        wl-copy < "$FILEPATH" || notify-send "Clipboard" "Failed to copy image to clipboard"
        return
    fi

    # X11 clipboard tools (only when DISPLAY is set)
    if [ -n "$DISPLAY" ] && command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard -t image/png < "$FILEPATH" || notify-send "Clipboard" "Failed to copy image to clipboard"
    elif [ -n "$DISPLAY" ] && command -v xsel >/dev/null 2>&1; then
        xsel --clipboard < "$FILEPATH" || notify-send "Clipboard" "Failed to copy image to clipboard"
    else
        notify-send "Clipboard" "No clipboard tool found (wl-copy, xclip, or xsel)"
    fi
}

# Take screenshot with available tool
take_screenshot() {
    mode=$1
    
    case "$mode" in
        full)
            if command -v scrot > /dev/null 2>&1; then
                scrot "$FILEPATH"
            elif command -v maim > /dev/null 2>&1; then
                maim "$FILEPATH"
            elif command -v import > /dev/null 2>&1; then
                import -window root "$FILEPATH"
            else
                notify-send "Error" "No screenshot tool found. Install scrot, maim, or imagemagick."
                exit 1
            fi
            ;;
        area)
            if command -v scrot > /dev/null 2>&1; then
                scrot -s "$FILEPATH"
            elif command -v maim > /dev/null 2>&1; then
                maim -s "$FILEPATH"
            elif command -v import > /dev/null 2>&1; then
                import "$FILEPATH"
            else
                notify-send "Error" "No screenshot tool found."
                exit 1
            fi
            ;;
        window)
            if command -v scrot > /dev/null 2>&1; then
                scrot -u "$FILEPATH"
            elif command -v maim > /dev/null 2>&1; then
                maim -i "$(xdotool getactivewindow)" "$FILEPATH"
            elif command -v import > /dev/null 2>&1; then
                import -window "$(xdotool getactivewindow)" "$FILEPATH"
            else
                notify-send "Error" "No screenshot tool found."
                exit 1
            fi
            ;;
        edit)
            # Take area screenshot and open in editor
            TMP_FILE=$(mktemp /tmp/screenshot-edit-XXXXXX.png)
            if command -v maim > /dev/null 2>&1; then
                maim -s "$TMP_FILE"
            elif command -v scrot > /dev/null 2>&1; then
                scrot -s "$TMP_FILE"
            elif command -v import > /dev/null 2>&1; then
                import "$TMP_FILE"
            fi
            
            if [ -f "$TMP_FILE" ]; then
                # Try to open in an editor
                if command -v swappy > /dev/null 2>&1; then
                    swappy -f "$TMP_FILE" -o "$FILEPATH"
                elif command -v gimp > /dev/null 2>&1; then
                    gimp "$TMP_FILE" &
                elif command -v pinta > /dev/null 2>&1; then
                    pinta "$TMP_FILE" &
                else
                    # Just save it
                    mv "$TMP_FILE" "$FILEPATH"
                fi
            fi
            return
            ;;
    esac
    
    # Post-processing
    if [ -f "$FILEPATH" ]; then
        play_sound
        copy_to_clipboard
        notify_screenshot
    fi
}

# Show menu if no argument
if [ -z "$1" ]; then
    if command -v rofi > /dev/null 2>&1; then
        MODE=$(printf "Full Screen\nSelect Area\nActive Window\nEdit Screenshot" | rofi -dmenu -i -p "Screenshot")
        case "$MODE" in
            "Full Screen") take_screenshot full ;;
            "Select Area") take_screenshot area ;;
            "Active Window") take_screenshot window ;;
            "Edit Screenshot") take_screenshot edit ;;
        esac
    else
        take_screenshot full
    fi
else
    take_screenshot "$MODE"
fi
