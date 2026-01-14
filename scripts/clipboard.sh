#!/bin/sh
#
# Clipboard manager script
# Shows clipboard history and allows selection via rofi
# Works with clipmenu/clipmenud, greenclip, or xclip history
#
# Usage: clipboard.sh [show|clear|copy]
#

ACTION="${1:-show}"

show_clipboard() {
    # Try clipmenu first (best experience)
    if command -v clipmenu > /dev/null 2>&1; then
        clipmenu
        return
    fi
    
    # Try greenclip
    if command -v greenclip > /dev/null 2>&1; then
        rofi -modi "clipboard:greenclip print" -show clipboard
        return
    fi
    
    # Try cliphist (works on Wayland/X)
    if command -v cliphist > /dev/null 2>&1; then
        cliphist list | rofi -dmenu -p "Clipboard" | cliphist decode | xclip -selection clipboard
        return
    fi

    # Wayland clipboard
    if command -v wl-paste >/dev/null 2>&1; then
        content=$(wl-paste -n 2>/dev/null)
        if [ -n "$content" ]; then
            notify-send "Current Clipboard" "$content"
        else
            notify-send "Clipboard" "Clipboard is empty"
        fi
        return
    fi
    
    # Fallback: show current X11 clipboard content
    if [ -n "$DISPLAY" ] && command -v xclip > /dev/null 2>&1; then
        content=$(xclip -selection clipboard -o 2>/dev/null)
        if [ -n "$content" ]; then
            notify-send "Current Clipboard" "$content"
        else
            notify-send "Clipboard" "Clipboard is empty"
        fi
    elif [ -n "$DISPLAY" ] && command -v xsel > /dev/null 2>&1; then
        content=$(xsel --clipboard -o 2>/dev/null)
        if [ -n "$content" ]; then
            notify-send "Current Clipboard" "$content"
        else
            notify-send "Clipboard" "Clipboard is empty"
        fi
    else
        notify-send "Clipboard" "No clipboard tool found"
    fi
}

clear_clipboard() {
    if command -v greenclip > /dev/null 2>&1; then
        greenclip clear
        notify-send "Clipboard" "History cleared"
        return
    fi
    
    if command -v clipdel > /dev/null 2>&1; then
        clipdel -d '.*'
        notify-send "Clipboard" "History cleared"
        return
    fi

    # Wayland
    if command -v wl-copy >/dev/null 2>&1; then
        echo -n "" | wl-copy
        notify-send "Clipboard" "Clipboard cleared"
        return
    fi
    
    # Clear current X11 clipboard
    if [ -n "$DISPLAY" ] && command -v xclip > /dev/null 2>&1; then
        echo -n "" | xclip -selection clipboard
        notify-send "Clipboard" "Clipboard cleared"
    elif [ -n "$DISPLAY" ] && command -v xsel > /dev/null 2>&1; then
        xsel --clipboard --clear
        notify-send "Clipboard" "Clipboard cleared"
    else
        notify-send "Clipboard" "No clipboard tool found"
    fi
}

copy_selection() {
    # Copy primary selection to clipboard
    if command -v wl-paste >/dev/null 2>&1 && command -v wl-copy >/dev/null 2>&1; then
        wl-paste | wl-copy && notify-send "Clipboard" "Selection copied to clipboard"
        return
    fi

    if [ -n "$DISPLAY" ] && command -v xclip > /dev/null 2>&1; then
        xclip -selection primary -o | xclip -selection clipboard
        notify-send "Clipboard" "Selection copied to clipboard"
    elif [ -n "$DISPLAY" ] && command -v xsel > /dev/null 2>&1; then
        xsel --primary | xsel --clipboard
        notify-send "Clipboard" "Selection copied to clipboard"
    else
        notify-send "Clipboard" "No clipboard tool found"
    fi
}

case "$ACTION" in
    show)
        show_clipboard
        ;;
    clear)
        clear_clipboard
        ;;
    copy)
        copy_selection
        ;;
    *)
        echo "Usage: $0 [show|clear|copy]"
        exit 1
        ;;
esac
