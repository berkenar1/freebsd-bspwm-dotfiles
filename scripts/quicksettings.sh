#!/bin/sh
#
# Quick settings menu for bspwm
# Access common system settings via rofi
#
# Usage: quicksettings.sh
#

# Menu options
show_menu() {
    echo "󰍹  Display Settings"
    echo "󰕾  Audio Settings"
    echo "󰂯  Bluetooth"
    echo "󰤨  Network"
    echo "  Appearance"
    echo "  Wallpaper"
    echo "󰌌  Keyboard"
    echo "󰟸  Power Settings"
    echo "  System Info"
}

# Open display settings
display_settings() {
    if command -v arandr > /dev/null 2>&1; then
        arandr &
    elif command -v lxrandr > /dev/null 2>&1; then
        lxrandr &
    elif command -v xfce4-display-settings > /dev/null 2>&1; then
        xfce4-display-settings &
    else
        notify-send "Display Settings" "Install arandr or lxrandr for display configuration"
        # Show basic xrandr info
        xrandr --query | rofi -dmenu -p "Display Info" > /dev/null
    fi
}

# Open audio settings
audio_settings() {
    if command -v pavucontrol > /dev/null 2>&1; then
        pavucontrol &
    elif command -v pavucontrol-qt > /dev/null 2>&1; then
        pavucontrol-qt &
    elif command -v alsamixer > /dev/null 2>&1; then
        alacritty -e alsamixer &
    elif command -v mixer > /dev/null 2>&1; then
        # FreeBSD mixer
        alacritty -e mixer &
    else
        notify-send "Audio Settings" "Install pavucontrol for audio settings"
    fi
}

# Open bluetooth settings
bluetooth_settings() {
    if command -v blueman-manager > /dev/null 2>&1; then
        blueman-manager &
    elif command -v blueberry > /dev/null 2>&1; then
        blueberry &
    elif command -v bluetoothctl > /dev/null 2>&1; then
        alacritty -e bluetoothctl &
    else
        notify-send "Bluetooth" "Install blueman for Bluetooth management"
    fi
}

# Open network settings
network_settings() {
    if command -v nm-connection-editor > /dev/null 2>&1; then
        nm-connection-editor &
    elif command -v connman-gtk > /dev/null 2>&1; then
        connman-gtk &
    elif command -v iwgtk > /dev/null 2>&1; then
        iwgtk &
    elif command -v wifimgr > /dev/null 2>&1; then
        # FreeBSD wifimgr
        wifimgr &
    else
        notify-send "Network" "Install nm-connection-editor or iwgtk"
        # Show basic network info
        if command -v nmcli > /dev/null 2>&1; then
            nmcli device status | rofi -dmenu -p "Network" > /dev/null
        fi
    fi
}

# Open appearance settings
appearance_settings() {
    if command -v lxappearance > /dev/null 2>&1; then
        lxappearance &
    elif command -v xfce4-appearance-settings > /dev/null 2>&1; then
        xfce4-appearance-settings &
    elif command -v qt5ct > /dev/null 2>&1; then
        qt5ct &
    else
        notify-send "Appearance" "Install lxappearance for GTK theme settings"
    fi
}

# Open wallpaper selector
wallpaper_menu() {
    if [ -x "$HOME/.local/scripts/wallpaper.sh" ]; then
        "$HOME/.local/scripts/wallpaper.sh" select
    elif [ -x "$(dirname "$0")/wallpaper.sh" ]; then
        "$(dirname "$0")/wallpaper.sh" select
    elif command -v nitrogen > /dev/null 2>&1; then
        nitrogen &
    else
        notify-send "Wallpaper" "Opening file manager to select wallpaper"
        if command -v pcmanfm > /dev/null 2>&1; then
            pcmanfm "$HOME/Pictures" &
        elif command -v thunar > /dev/null 2>&1; then
            thunar "$HOME/Pictures" &
        fi
    fi
}

# Keyboard settings
keyboard_settings() {
    current_layout=$(setxkbmap -query | grep layout | awk '{print $2}')
    
    new_layout=$(printf "us\nus (colemak)\nus (dvorak)\nde\nfr\nes\ngb\nru" | rofi -dmenu -p "Keyboard Layout (current: $current_layout)")
    
    if [ -n "$new_layout" ]; then
        case "$new_layout" in
            "us (colemak)")
                setxkbmap us -variant colemak
                ;;
            "us (dvorak)")
                setxkbmap us -variant dvorak
                ;;
            *)
                setxkbmap "$new_layout"
                ;;
        esac
        notify-send "Keyboard" "Layout changed to: $new_layout"
    fi
}

# Power settings
power_settings() {
    if [ -x "$HOME/.local/scripts/powermenu.sh" ]; then
        "$HOME/.local/scripts/powermenu.sh"
    elif [ -x "$(dirname "$0")/powermenu.sh" ]; then
        "$(dirname "$0")/powermenu.sh"
    elif command -v xfce4-power-manager-settings > /dev/null 2>&1; then
        xfce4-power-manager-settings &
    else
        # Simple power menu
        action=$(printf "Lock\nLogout\nSuspend\nReboot\nShutdown" | rofi -dmenu -p "Power")
        case "$action" in
            Lock) i3lock -c 2a2f33 || xlock -mode blank ;;
            Logout) bspc quit ;;
            Suspend) 
                if [ "$(uname)" = "FreeBSD" ]; then
                    sudo acpiconf -s 3
                else
                    systemctl suspend
                fi
                ;;
            Reboot)
                if [ "$(uname)" = "FreeBSD" ]; then
                    sudo shutdown -r now
                else
                    systemctl reboot
                fi
                ;;
            Shutdown)
                if [ "$(uname)" = "FreeBSD" ]; then
                    sudo shutdown -p now
                else
                    systemctl poweroff
                fi
                ;;
        esac
    fi
}

# System info
system_info() {
    # Get system information with proper fallbacks for FreeBSD
    sys_name=$(uname -sr)
    host_name=$(hostname)
    uptime_info=$(uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
    
    # CPU info - FreeBSD first, then Linux fallback (with trimming)
    cpu_info=$(sysctl -n hw.model 2>/dev/null)
    if [ -z "$cpu_info" ]; then
        cpu_info=$(grep 'model name' /proc/cpuinfo 2>/dev/null | head -1 | cut -d: -f2 | sed 's/^[[:space:]]*//')
    fi
    
    # Memory info - FreeBSD first, then Linux fallback
    if command -v sysctl > /dev/null 2>&1 && [ "$(uname)" = "FreeBSD" ]; then
        physmem=$(sysctl -n hw.physmem 2>/dev/null)
        if [ -n "$physmem" ]; then
            mem_gb=$(echo "$physmem" | awk '{printf "%.1fG", $1/1024/1024/1024}')
            mem_info="$mem_gb total"
        else
            mem_info="Unknown"
        fi
    else
        mem_info=$(free -h 2>/dev/null | awk '/^Mem:/ {print $3 "/" $2}')
    fi
    
    disk_info=$(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')
    
    info="System: $sys_name
Hostname: $host_name
Uptime: $uptime_info
CPU: $cpu_info
Memory: $mem_info
Disk: $disk_info"

    echo "$info" | rofi -dmenu -p "System Info" > /dev/null
    
    # Also run neofetch if available
    if command -v neofetch > /dev/null 2>&1; then
        alacritty -e sh -c "neofetch; read -p 'Press Enter to close...'" &
    fi
}

# Main menu
main() {
    choice=$(show_menu | rofi -dmenu -i -p "Quick Settings")
    
    case "$choice" in
        *"Display"*)
            display_settings
            ;;
        *"Audio"*)
            audio_settings
            ;;
        *"Bluetooth"*)
            bluetooth_settings
            ;;
        *"Network"*)
            network_settings
            ;;
        *"Appearance"*)
            appearance_settings
            ;;
        *"Wallpaper"*)
            wallpaper_menu
            ;;
        *"Keyboard"*)
            keyboard_settings
            ;;
        *"Power"*)
            power_settings
            ;;
        *"System Info"*)
            system_info
            ;;
    esac
}

main
