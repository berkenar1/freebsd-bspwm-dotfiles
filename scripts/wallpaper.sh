#!/bin/sh
#
# Wallpaper selector and randomizer script
# Supports feh, hsetroot, nitrogen, and xwallpaper
#
# Usage: wallpaper.sh [select|random|set <path>]
#   wallpaper.sh select     # Open rofi menu to select wallpaper
#   wallpaper.sh random     # Set random wallpaper from directory
#   wallpaper.sh set <path> # Set specific wallpaper
#

ACTION="${1:-select}"
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
CONFIG_WALLPAPER="$HOME/.config/wallpaper.jpg"

# Create wallpaper directory if it doesn't exist
mkdir -p "$WALLPAPER_DIR"

# Set wallpaper using available tool
set_wallpaper() {
    image="$1"
    
    if [ ! -f "$image" ]; then
        notify-send "Error" "Wallpaper not found: $image"
        return 1
    fi
    
    # Copy to config location for persistence
    cp "$image" "$CONFIG_WALLPAPER"
    
    # Apply wallpaper with available tool (prefer feh)
    if command -v feh > /dev/null 2>&1; then
        feh --bg-fill "$image"
    elif command -v hsetroot > /dev/null 2>&1; then
        hsetroot -cover "$image"
    elif command -v nitrogen > /dev/null 2>&1; then
        nitrogen --set-zoom-fill "$image"
    elif command -v xwallpaper > /dev/null 2>&1; then
        xwallpaper --zoom "$image"
    elif command -v xsetroot > /dev/null 2>&1; then
        # xsetroot doesn't support images directly, but we tried
        notify-send "Warning" "Install feh or hsetroot for image wallpapers"
    fi
    
    notify-send -i "$image" "Wallpaper Changed" "$(basename "$image")"
}

# Select wallpaper via rofi
select_wallpaper() {
    # Check if wallpaper directory exists and has files
    if [ ! -d "$WALLPAPER_DIR" ] || [ -z "$(ls -A "$WALLPAPER_DIR" 2>/dev/null)" ]; then
        # Fall back to config wallpaper or Pictures
        if [ -f "$CONFIG_WALLPAPER" ]; then
            WALLPAPER_DIR=$(dirname "$CONFIG_WALLPAPER")
        else
            WALLPAPER_DIR="$HOME/Pictures"
        fi
    fi
    
    # Find all image files
    images=$(find "$WALLPAPER_DIR" -maxdepth 2 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) 2>/dev/null)
    
    if [ -z "$images" ]; then
        notify-send "Wallpaper" "No images found in $WALLPAPER_DIR"
        return 1
    fi
    
    # Show in rofi
    if command -v rofi > /dev/null 2>&1; then
        selected=$(echo "$images" | while read -r img; do basename "$img"; done | rofi -dmenu -i -p "Wallpaper")
        if [ -n "$selected" ]; then
            # Find full path
            full_path=$(echo "$images" | grep -F "/$selected" | head -1)
            if [ -n "$full_path" ]; then
                set_wallpaper "$full_path"
            fi
        fi
    else
        # Fallback: just set random
        random_wallpaper
    fi
}

# Set random wallpaper
random_wallpaper() {
    if [ ! -d "$WALLPAPER_DIR" ]; then
        notify-send "Error" "Wallpaper directory not found: $WALLPAPER_DIR"
        return 1
    fi
    
    # Find random image using a more efficient method
    # Count files first, then select random index
    image_count=$(find "$WALLPAPER_DIR" -maxdepth 2 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | wc -l)
    
    if [ "$image_count" -eq 0 ]; then
        notify-send "Error" "No wallpapers found in $WALLPAPER_DIR"
        return 1
    fi
    
    # Use awk for random selection (more portable than shuf)
    random_image=$(find "$WALLPAPER_DIR" -maxdepth 2 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | awk -v seed="$RANDOM" 'BEGIN{srand(seed)} {a[NR]=$0} END{print a[int(rand()*NR)+1]}')
    
    if [ -n "$random_image" ]; then
        set_wallpaper "$random_image"
    else
        notify-send "Error" "No wallpapers found in $WALLPAPER_DIR"
    fi
}

case "$ACTION" in
    select)
        select_wallpaper
        ;;
    random)
        random_wallpaper
        ;;
    set)
        if [ -n "$2" ]; then
            set_wallpaper "$2"
        else
            echo "Usage: $0 set <path-to-image>"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 [select|random|set <path>]"
        exit 1
        ;;
esac
