#!/bin/sh
#
# FreeBSD BSPWM Dotfiles - Update Script
#
# This script updates the dotfiles after fetching updates with git pull.
# It re-applies the configuration without reinstalling packages.
#
# Usage: ./update.sh [--no-backup]
#
# Options:
#   --no-backup    Skip backing up existing configurations
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
BACKUP_DIR="$HOME/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# Flags
CREATE_BACKUP=true

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --no-backup)
            CREATE_BACKUP=false
            ;;
        --help|-h)
            echo "FreeBSD BSPWM Dotfiles Updater"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "This script updates dotfiles after running 'git pull'."
            echo "It does NOT reinstall packages - use install-freebsd.sh for full installation."
            echo ""
            echo "Options:"
            echo "  --no-backup    Skip backing up existing configurations"
            echo "  -h, --help     Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg. Use $0 --help for usage information"
            exit 1
            ;;
    esac
done

# Logging functions
log_info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1"
}

log_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"
}

log_warning() {
    printf "${YELLOW}[WARNING]${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

backup_configs() {
    if [ "$CREATE_BACKUP" = false ]; then
        log_info "Skipping backup (--no-backup flag set)"
        return
    fi

    log_info "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$BACKUP_DIR/.config"

    # Backup key .config directories that will be updated
    for config_name in bspwm sxhkd polybar rofi picom; do
        if [ -e "$XDG_CONFIG_HOME/$config_name" ]; then
            log_info "Backing up: $XDG_CONFIG_HOME/$config_name"
            cp -r "$XDG_CONFIG_HOME/$config_name" "$BACKUP_DIR/.config/" 2>/dev/null || true
        fi
    done

    log_success "Backup created at: $BACKUP_DIR"
}

update_dotfiles() {
    log_info "Updating dotfiles..."

    # Update .config directories
    for config_dir in "$DOTFILES_DIR/.config"/*; do
        if [ -d "$config_dir" ]; then
            config_name=$(basename "$config_dir")
            dest="$XDG_CONFIG_HOME/$config_name"
            
            # Remove existing symlink or directory
            if [ -L "$dest" ]; then
                rm "$dest"
            elif [ -d "$dest" ]; then
                rm -rf "$dest"
            fi
            
            log_info "Updating config: $config_name"
            cp -r "$config_dir" "$dest"
        elif [ -f "$config_dir" ]; then
            # Handle individual files in .config (like redshift.conf)
            config_name=$(basename "$config_dir")
            dest="$XDG_CONFIG_HOME/$config_name"
            
            if [ -L "$dest" ] || [ -f "$dest" ]; then
                rm "$dest"
            fi
            
            log_info "Updating config file: $config_name"
            cp "$config_dir" "$dest"
        fi
    done

    # Check if we're on FreeBSD and apply FreeBSD-specific configs
    if [ "$(uname)" = "FreeBSD" ]; then
        log_info "Applying FreeBSD-specific configurations..."
        
        # bspwm FreeBSD config
        if [ -f "$DOTFILES_DIR/.config/bspwm/bspwmrc.freebsd" ]; then
            cp "$DOTFILES_DIR/.config/bspwm/bspwmrc.freebsd" "$XDG_CONFIG_HOME/bspwm/bspwmrc"
            chmod +x "$XDG_CONFIG_HOME/bspwm/bspwmrc"
        fi
        
        if [ -f "$DOTFILES_DIR/.config/bspwm/autostart.freebsd" ]; then
            cp "$DOTFILES_DIR/.config/bspwm/autostart.freebsd" "$XDG_CONFIG_HOME/bspwm/autostart"
            chmod +x "$XDG_CONFIG_HOME/bspwm/autostart"
        fi
        
        # sxhkd FreeBSD config
        if [ -f "$DOTFILES_DIR/.config/sxhkd/sxhkdrc.freebsd" ]; then
            cp "$DOTFILES_DIR/.config/sxhkd/sxhkdrc.freebsd" "$XDG_CONFIG_HOME/sxhkd/sxhkdrc"
        fi
        
        # polybar FreeBSD launch script
        if [ -f "$DOTFILES_DIR/.config/polybar/launch-freebsd.sh" ]; then
            cp "$DOTFILES_DIR/.config/polybar/launch-freebsd.sh" "$XDG_CONFIG_HOME/polybar/launch.sh"
            chmod +x "$XDG_CONFIG_HOME/polybar/launch.sh"
        fi
        
        # picom FreeBSD config
        if [ -f "$DOTFILES_DIR/.config/picom/picom-freebsd.conf" ]; then
            cp "$DOTFILES_DIR/.config/picom/picom-freebsd.conf" "$XDG_CONFIG_HOME/picom/picom.conf"
        fi
    fi

    # Update fonts if present
    if [ -d "$DOTFILES_DIR/.fonts" ]; then
        log_info "Updating fonts..."
        mkdir -p "$HOME/.fonts"
        for font in "$DOTFILES_DIR/.fonts"/*; do
            font_name=$(basename "$font")
            cp "$font" "$HOME/.fonts/" 2>/dev/null || true
        done
        # Update font cache
        if command -v fc-cache > /dev/null 2>&1; then
            fc-cache -f "$HOME/.fonts" 2>/dev/null || true
        fi
    fi

    # Update .Xresources
    if [ -f "$DOTFILES_DIR/.Xresources" ]; then
        log_info "Updating .Xresources..."
        cp "$DOTFILES_DIR/.Xresources" "$HOME/.Xresources"
        # Reload Xresources if X is running
        if [ -n "$DISPLAY" ] && command -v xrdb > /dev/null 2>&1; then
            xrdb -merge "$HOME/.Xresources" 2>/dev/null || true
        fi
    fi

    # Update .tmux.conf
    if [ -f "$DOTFILES_DIR/.tmux.conf" ]; then
        log_info "Updating .tmux.conf..."
        cp "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
    fi

    log_success "Dotfiles updated!"
}

update_zsh_config() {
    log_info "Updating ZSH configuration..."

    # Copy zsh files
    for zsh_file in "$DOTFILES_DIR/zsh"/.*; do
        if [ -f "$zsh_file" ]; then
            file_name=$(basename "$zsh_file")
            case "$file_name" in
                .zsh-plugins)
                    ;;
                .*)
                    log_info "Updating: $file_name"
                    cp "$zsh_file" "$HOME/$file_name"
                    ;;
            esac
        fi
    done

    # Handle .zsh-plugins directory
    if [ -d "$DOTFILES_DIR/zsh/.zsh-plugins" ]; then
        log_info "Updating zsh plugins..."
        if [ -d "$HOME/.zsh-plugins" ]; then
            rm -rf "$HOME/.zsh-plugins"
        fi
        cp -r "$DOTFILES_DIR/zsh/.zsh-plugins" "$HOME/"
    fi
    
    # Apply FreeBSD-specific zsh configuration if on FreeBSD
    if [ "$(uname)" = "FreeBSD" ]; then
        if [ -f "$DOTFILES_DIR/zsh/.zshrc.freebsd" ]; then
            cp "$DOTFILES_DIR/zsh/.zshrc.freebsd" "$HOME/.zshrc"
        fi
        
        if [ -f "$DOTFILES_DIR/zsh/.zprofile.freebsd" ]; then
            cp "$DOTFILES_DIR/zsh/.zprofile.freebsd" "$HOME/.zprofile"
        fi
    fi

    log_success "ZSH configuration updated!"
}

make_scripts_executable() {
    log_info "Making scripts executable..."

    # bspwm scripts
    if [ -d "$XDG_CONFIG_HOME/bspwm" ]; then
        [ -f "$XDG_CONFIG_HOME/bspwm/bspwmrc" ] && chmod +x "$XDG_CONFIG_HOME/bspwm/bspwmrc"
        [ -f "$XDG_CONFIG_HOME/bspwm/autostart" ] && chmod +x "$XDG_CONFIG_HOME/bspwm/autostart"
    fi

    # sxhkd config
    if [ -f "$XDG_CONFIG_HOME/sxhkd/sxhkdrc" ]; then
        chmod +x "$XDG_CONFIG_HOME/sxhkd/sxhkdrc"
    fi

    # polybar scripts
    if [ -d "$XDG_CONFIG_HOME/polybar" ]; then
        [ -f "$XDG_CONFIG_HOME/polybar/launch.sh" ] && chmod +x "$XDG_CONFIG_HOME/polybar/launch.sh"
        [ -d "$XDG_CONFIG_HOME/polybar/scripts" ] && chmod +x "$XDG_CONFIG_HOME/polybar/scripts"/* 2>/dev/null || true
    fi

    # sx scripts
    if [ -f "$XDG_CONFIG_HOME/sx/sxrc" ]; then
        chmod +x "$XDG_CONFIG_HOME/sx/sxrc"
    fi

    # .xinitrc
    if [ -f "$HOME/.xinitrc" ]; then
        chmod +x "$HOME/.xinitrc"
    fi

    log_success "Scripts are now executable!"
}

reload_configs() {
    log_info "Reloading configurations..."
    
    # Reload sxhkd if running
    if pgrep -x sxhkd > /dev/null 2>&1; then
        log_info "Reloading sxhkd..."
        pkill -USR1 -x sxhkd 2>/dev/null || true
    fi
    
    # Restart polybar if running
    if pgrep -x polybar > /dev/null 2>&1; then
        log_info "Restarting polybar..."
        if [ -x "$XDG_CONFIG_HOME/polybar/launch.sh" ]; then
            "$XDG_CONFIG_HOME/polybar/launch.sh" &
        fi
    fi
    
    # Reload bspwm if running
    if pgrep -x bspwm > /dev/null 2>&1; then
        log_info "Reloading bspwm..."
        bspc wm -r 2>/dev/null || true
    fi
    
    log_success "Configurations reloaded!"
}

print_post_update() {
    echo ""
    echo "=============================================="
    printf "${GREEN}Update Complete!${NC}\n"
    echo "=============================================="
    echo ""
    if [ "$CREATE_BACKUP" = true ]; then
        echo "Your previous configuration was backed up to:"
        echo "  $BACKUP_DIR"
        echo ""
    fi
    echo "If running X11, you may want to:"
    echo "  - Press Super + Alt + r to restart bspwm"
    echo "  - Or log out and log back in"
    echo ""
}

# Main update flow
main() {
    echo ""
    echo "=============================================="
    echo " FreeBSD BSPWM Dotfiles Updater"
    echo "=============================================="
    echo ""

    log_info "Starting update..."
    log_info "Dotfiles directory: $DOTFILES_DIR"
    log_info "Config directory: $XDG_CONFIG_HOME"
    echo ""

    backup_configs
    update_dotfiles
    update_zsh_config
    make_scripts_executable
    reload_configs
    print_post_update
}

# Run main function
main
