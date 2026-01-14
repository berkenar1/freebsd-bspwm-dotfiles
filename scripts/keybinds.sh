#!/bin/sh
#
# Keybind helper - displays all keybindings in a rofi menu
# Parses sxhkdrc to show available keyboard shortcuts
#
# Usage: keybinds.sh
#

SXHKD_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/sxhkd/sxhkdrc"

# Parse sxhkdrc and format for display
parse_keybinds() {
    if [ ! -f "$SXHKD_CONFIG" ]; then
        echo "sxhkdrc not found at $SXHKD_CONFIG"
        return 1
    fi
    
    awk '
    BEGIN { 
        keybind = ""
        comment = ""
    }
    
    # Skip empty lines
    /^[[:space:]]*$/ { next }
    
    # Capture comments as descriptions
    /^#/ {
        # Remove # and leading/trailing spaces
        gsub(/^#[[:space:]]*/, "")
        gsub(/[[:space:]]*$/, "")
        if (length($0) > 0 && $0 !~ /^-+$/ && $0 !~ /^=+$/) {
            comment = $0
        }
        next
    }
    
    # Capture keybind (lines starting with super, alt, ctrl, or XF86)
    /^(super|alt|ctrl|shift|XF86|Print)/ {
        keybind = $0
        # Clean up the keybind
        gsub(/[[:space:]]+/, " ", keybind)
        next
    }
    
    # Capture command (indented lines after keybind)
    /^[[:space:]]+[^#]/ && keybind != "" {
        command = $0
        # Clean up command
        gsub(/^[[:space:]]+/, "", command)
        gsub(/[[:space:]]+$/, "", command)
        
        # Format output
        if (comment != "") {
            printf "%-35s │ %s\n", keybind, comment
        } else {
            printf "%-35s │ %s\n", keybind, command
        }
        
        keybind = ""
        comment = ""
        next
    }
    ' "$SXHKD_CONFIG"
}

# Show keybinds organized by category
show_categorized() {
    echo "═══════════════════════════════════════════════════════════════"
    echo "                    BSPWM KEYBOARD SHORTCUTS                    "
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                     WINDOW MANAGEMENT                         ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    echo "║ Super + Q                 │ Close window                      ║"
    echo "║ Super + Shift + Q         │ Kill window                       ║"
    echo "║ Super + F                 │ Toggle fullscreen                 ║"
    echo "║ Super + U                 │ Toggle floating                   ║"
    echo "║ Super + M                 │ Toggle monocle layout             ║"
    echo "║ Super + Arrow Keys        │ Focus window in direction         ║"
    echo "║ Super + Shift + Arrows    │ Swap window in direction          ║"
    echo "║ Super + Alt + Arrows      │ Resize window                     ║"
    echo "║ Alt + Left Click (drag)   │ Move floating window              ║"
    echo "║ Alt + Right Click (drag)  │ Resize floating window            ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    echo "║                      WORKSPACES                               ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    echo "║ Super + 1-9               │ Switch to workspace               ║"
    echo "║ Super + Shift + 1-9       │ Move window to workspace          ║"
    echo "║ Super + Tab               │ Last workspace                    ║"
    echo "║ Super + [ / ]             │ Previous / Next workspace         ║"
    echo "║ Alt + Tab                 │ Cycle occupied workspaces         ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    echo "║                     APPLICATIONS                              ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    echo "║ Super + Return            │ Open terminal                     ║"
    echo "║ Super + Shift + Return    │ Open terminal with tmux           ║"
    echo "║ Alt + Space               │ Application launcher (rofi)       ║"
    echo "║ Super + W                 │ Window switcher                   ║"
    echo "║ Super + E                 │ File manager                      ║"
    echo "║ Super + B                 │ Web browser                       ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    echo "║                      SYSTEM                                   ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    echo "║ Super + Shift + L         │ Lock screen                       ║"
    echo "║ Super + Escape            │ Reload sxhkd                      ║"
    echo "║ Super + Shift + Escape    │ Reload polybar                    ║"
    echo "║ Super + Alt + R           │ Restart bspwm                     ║"
    echo "║ Super + Alt + Q           │ Quit bspwm                        ║"
    echo "║ Super + X                 │ Power menu                        ║"
    echo "║ Super + S                 │ Quick settings                    ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    echo "║                     UTILITIES                                 ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    echo "║ Print                     │ Screenshot (full)                 ║"
    echo "║ Shift + Print             │ Screenshot (selection)            ║"
    echo "║ Super + Print             │ Screenshot menu                   ║"
    echo "║ Super + V                 │ Clipboard manager                 ║"
    echo "║ Super + Period            │ Emoji picker                      ║"
    echo "║ Super + Shift + W         │ Wallpaper selector                ║"
    echo "║ Super + H                 │ This help menu                    ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    echo "║                   MEDIA CONTROLS                              ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    echo "║ XF86AudioRaiseVolume      │ Volume up                         ║"
    echo "║ XF86AudioLowerVolume      │ Volume down                       ║"
    echo "║ XF86AudioMute             │ Toggle mute                       ║"
    echo "║ XF86MonBrightnessUp       │ Brightness up                     ║"
    echo "║ XF86MonBrightnessDown     │ Brightness down                   ║"
    echo "║ XF86AudioPlay             │ Play/Pause                        ║"
    echo "║ XF86AudioNext             │ Next track                        ║"
    echo "║ XF86AudioPrev             │ Previous track                    ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
}

# Main
main() {
    if command -v rofi > /dev/null 2>&1; then
        show_categorized | rofi -dmenu -i -p "Keybinds" -theme-str 'window {width: 70%;} listview {lines: 30;}'
    else
        show_categorized | less
    fi
}

main
