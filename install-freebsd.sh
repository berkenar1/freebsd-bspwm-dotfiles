#!/bin/sh
#
# FreeBSD BSPWM Dotfiles - Automated Installation Script
# 
# This script will:
# 1. Install all required packages via pkg
# 2. Backup existing configurations
# 3. Install dotfiles and themes
# 4. Configure display manager and X11
#
# Usage: ./install-freebsd.sh [--no-packages] [--no-backup]
#
# Options:
#   --no-packages  Skip package installation (useful if packages are already installed)
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
INSTALL_PACKAGES=true
CREATE_BACKUP=true

# Component selection flags (enable/disable per-component)
INSTALL_WM=true       # other WM components (polybar, picom, rofi, etc.)
INSTALL_BSPWM=true    # bspwm config
INSTALL_SXHKD=true    # sxhkd keybindings
INSTALL_NVIM=false    # NeoVim configuration (disabled by default)
INSTALL_ZSH=false     # ZSH and plugins (disabled by default)
INSTALL_AUDIO=true    # PipeWire and audio config

# Preserve existing user configurations by default (do not overwrite)
PRESERVE_EXISTING=true

# Optional utilities (install when requested)
INSTALL_OPTIONAL=false
OPTIONAL_PACKAGES="vnstat dunst polkit-gnome libudisks ympd"

# Interactive selection mode
INTERACTIVE_SELECTION=false

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --no-packages)
            INSTALL_PACKAGES=false
            ;;
        --no-backup)
            CREATE_BACKUP=false
            ;;
        --no-wm)
            INSTALL_WM=false
            ;;
        --no-bspwm)
            INSTALL_BSPWM=false
            ;;
        --no-sxhkd)
            INSTALL_SXHKD=false
            ;;
        --no-nvim)
            INSTALL_NVIM=false
            ;;
        --no-zsh)
            INSTALL_ZSH=false
            ;;
        --no-audio)
            INSTALL_AUDIO=false
            ;;
        --no-preserve)
            PRESERVE_EXISTING=false
            ;;
        --install-optional)
            INSTALL_OPTIONAL=true
            ;;
        --no-optional)
            INSTALL_OPTIONAL=false
            ;;
        --select)
            INTERACTIVE_SELECTION=true
            ;;
        --help|-h)
            echo "FreeBSD BSPWM Dotfiles Installer"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --no-packages      Skip package installation"
            echo "  --no-backup        Skip backing up existing configurations"
            echo "  --no-wm            Skip other window manager configs (polybar, picom, rofi, etc.)"
            echo "  --no-bspwm         Skip bspwm configuration"
            echo "  --no-sxhkd         Skip sxhkd keybindings"
            echo "  --no-nvim          Skip NeoVim config installation"
            echo "  --no-zsh           Skip ZSH config and plugin installation"
            echo "  --no-audio         Skip audio (PipeWire) configuration and packages"
            echo "  --install-optional Install additional optional utilities (vnstat, dunst, polkit-gnome, libudisks, ympd)"
            echo "  --no-optional      Do not install optional utilities"
            echo "  --no-preserve      Do not preserve existing configs; allow overwriting targets"
            echo "  --select           Interactively select which components to install"
            echo "  -h, --help         Show this help message"
            echo ""
            echo "Note: By default this installer will not install ZSH or NeoVim and will preserve existing configs. Use --select to enable components, or pass --install-optional to include optional utilities."
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

# Check if running on FreeBSD
check_freebsd() {
    if [ "$(uname)" != "FreeBSD" ]; then
        log_error "This script is designed for FreeBSD only!"
        log_error "Detected OS: $(uname)"
        exit 1
    fi
    log_success "FreeBSD detected: $(freebsd-version)"
}

# Check if running as root for package installation
check_permissions() {
    if [ "$INSTALL_PACKAGES" = true ] && [ "$(id -u)" -ne 0 ]; then
        log_warning "Package installation requires root privileges."
        log_info "You can either:"
        log_info "  1. Run this script as root: sudo $0"
        log_info "  2. Skip package installation: $0 --no-packages"
        exit 1
    fi
}

# Required packages for FreeBSD
# Xorg base
XORG_PACKAGES="
xorg
"

# Window manager / WM-related packages
WM_PACKAGES="
bspwm
sxhkd
polybar
rofi
dunst
picom
feh
hsetroot
"

# NeoVim
NVIM_PACKAGES="
neovim
"

# Terminal and shell (zsh-related)
SHELL_PACKAGES="
alacritty
zsh
zsh-autosuggestions
zsh-syntax-highlighting
tmux
"

# Audio packages (PipeWire for FreeBSD)
AUDIO_PACKAGES="
pipewire
wireplumber
libspa-oss
pulseaudio-utils
pamixer
playerctl
"

# Utilities
# Note: 'mpd' (Music Player Daemon) may not be available as a binary package on
# all FreeBSD repositories; it is optional. The installer will not break if a
# package is unavailable, but you can install MPD manually or use web/GUI
# clients (e.g., 'ympd') if you prefer.
UTIL_PACKAGES="
neofetch
ncmpcpp
ympd
mpv
zathura
zathura-pdf-poppler
conky
vnstat
lf
fzf
fd-find
ripgrep
exa
xautolock
xdotool
xclip
xsel-conrad
scrot
i3lock
"
# DE-like utilities (optional but recommended)
# Note: some packages like 'lxpolkit', 'blueman', and 'udiskie' may not exist
# in FreeBSD pkg repositories; prefer available alternatives when possible.
DE_PACKAGES="
polkit-gnome
pcmanfm
arandr
pavucontrol
libudisks
redshift
nitrogen
clipmenu
rofi-emoji
"

# Fonts
FONT_PACKAGES="
terminus-font
nerd-fonts
font-awesome
noto
"

# Display manager (optional)
DM_PACKAGES="
slim
"

install_packages() {
    if [ "$INSTALL_PACKAGES" = false ]; then
        log_info "Skipping package installation (--no-packages flag set)"
        return
    fi

    log_info "Updating pkg repository..."
    pkg update -f

    # Always install Xorg base
    if [ -n "$XORG_PACKAGES" ]; then
        log_info "Installing Xorg packages..."
        for pkg in $XORG_PACKAGES; do
            if pkg info -e "$pkg" > /dev/null 2>&1; then
                log_info "Package already installed: $pkg"
            else
                log_info "Installing: $pkg"
                pkg install -y "$pkg" || log_warning "Failed to install: $pkg"
            fi
        done
    fi

    # Window manager packages (install per component)
    if [ -n "$WM_PACKAGES" ]; then
        log_info "Installing window manager packages (per selection)..."
        for pkg in $WM_PACKAGES; do
            case "$pkg" in
                bspwm)
                    if [ "$INSTALL_BSPWM" = true ]; then
                        install_pkg="$pkg"
                    else
                        log_info "Skipping package: $pkg (--no-bspwm)"
                        continue
                    fi
                    ;;
                sxhkd)
                    if [ "$INSTALL_SXHKD" = true ]; then
                        install_pkg="$pkg"
                    else
                        log_info "Skipping package: $pkg (--no-sxhkd)"
                        continue
                    fi
                    ;;
                *)
                    # other WM-related packages follow INSTALL_WM
                    if [ "$INSTALL_WM" = true ]; then
                        install_pkg="$pkg"
                    else
                        log_info "Skipping package: $pkg (--no-wm)"
                        continue
                    fi
                    ;;
            esac

            if pkg info -e "$install_pkg" > /dev/null 2>&1; then
                log_info "Package already installed: $install_pkg"
            else
                log_info "Installing: $install_pkg"
                pkg install -y "$install_pkg" || log_warning "Failed to install: $install_pkg"
            fi
        done
    fi

    # NeoVim
    if [ "$INSTALL_NVIM" = true ] && [ -n "$NVIM_PACKAGES" ]; then
        log_info "Installing NeoVim..."
        for pkg in $NVIM_PACKAGES; do
            if pkg info -e "$pkg" > /dev/null 2>&1; then
                log_info "Package already installed: $pkg"
            else
                log_info "Installing: $pkg"
                pkg install -y "$pkg" || log_warning "Failed to install: $pkg"
            fi
        done
    else
        log_info "Skipping NeoVim packages (disabled)"
    fi

    # Shell packages (zsh)
    if [ "$INSTALL_ZSH" = true ] && [ -n "$SHELL_PACKAGES" ]; then
        log_info "Installing shell packages..."
        for pkg in $SHELL_PACKAGES; do
            if pkg info -e "$pkg" > /dev/null 2>&1; then
                log_info "Package already installed: $pkg"
            else
                log_info "Installing: $pkg"
                pkg install -y "$pkg" || log_warning "Failed to install: $pkg"
            fi
        done
    else
        log_info "Skipping shell packages (--no-zsh)"
    fi

    log_info "Installing utility packages..."
    for pkg in $UTIL_PACKAGES; do
        if pkg info -e "$pkg" > /dev/null 2>&1; then
            log_info "Package already installed: $pkg"
        else
            log_info "Installing: $pkg"
            pkg install -y "$pkg" || log_warning "Failed to install: $pkg"
        fi
    done

    log_info "Installing font packages..."
    for pkg in $FONT_PACKAGES; do
        if pkg info -e "$pkg" > /dev/null 2>&1; then
            log_info "Package already installed: $pkg"
        else
            log_info "Installing: $pkg"
            pkg install -y "$pkg" || log_warning "Failed to install: $pkg"
        fi
    done

    # Audio packages
    if [ "$INSTALL_AUDIO" = true ]; then
        log_info "Installing audio packages (PipeWire)..."
        for pkg in $AUDIO_PACKAGES; do
            if pkg info -e "$pkg" > /dev/null 2>&1; then
                log_info "Package already installed: $pkg"
            else
                log_info "Installing: $pkg"
                pkg install -y "$pkg" || log_warning "Failed to install: $pkg"
            fi
        done
    else
        log_info "Skipping audio packages (--no-audio)"
    fi

    log_info "Installing DE-like utility packages..."
    for pkg in $DE_PACKAGES; do
        if pkg info -e "$pkg" > /dev/null 2>&1; then
            log_info "Package already installed: $pkg"
        else
            log_info "Installing: $pkg"
            pkg install -y "$pkg" || log_warning "Failed to install: $pkg (optional)"
        fi
    done

    # Optional utilities (user-requested)
    if [ "$INSTALL_OPTIONAL" = true ]; then
        log_info "Installing optional utilities..."
        for pkg in $OPTIONAL_PACKAGES; do
            if pkg info -e "$pkg" > /dev/null 2>&1; then
                log_info "Package already installed: $pkg"
            else
                log_info "Installing optional: $pkg"
                pkg install -y "$pkg" || log_warning "Failed to install optional package: $pkg"
            fi
        done
    else
        log_info "Skipping optional utilities (not requested)"
    fi

    log_success "Package installation complete!"
}

# Interactive component selection helper
select_components() {
    log_info "Interactive selection: choose components to install (y/n)"

    printf "Install bspwm configuration? [Y/n]: "
    read -r res
    case "$res" in
        n|N) INSTALL_BSPWM=false ;;
        *) INSTALL_BSPWM=true ;;
    esac

    printf "Install sxhkd keybindings? [Y/n]: "
    read -r res
    case "$res" in
        n|N) INSTALL_SXHKD=false ;;
        *) INSTALL_SXHKD=true ;;
    esac

    printf "Install other WM components (polybar, picom, rofi, dunst)? [Y/n]: "
    read -r res
    case "$res" in
        n|N) INSTALL_WM=false ;;
        *) INSTALL_WM=true ;;
    esac

    printf "Install NeoVim configuration? [Y/n]: "
    read -r res
    case "$res" in
        n|N) INSTALL_NVIM=false ;;
        *) INSTALL_NVIM=true ;;
    esac

    printf "Install ZSH configuration and plugins? [Y/n]: "
    read -r res
    case "$res" in
        n|N) INSTALL_ZSH=false ;;
        *) INSTALL_ZSH=true ;;
    esac

    printf "Install audio configuration (PipeWire)? [Y/n]: "
    read -r res
    case "$res" in
        n|N) INSTALL_AUDIO=false ;;
        *) INSTALL_AUDIO=true ;;
    esac

    printf "Install optional utilities (vnstat, dunst, polkit-gnome, libudisks, ympd)? [y/N]: "
    read -r res
    case "$res" in
        y|Y) INSTALL_OPTIONAL=true ;;
        *) INSTALL_OPTIONAL=false ;;
    esac

    log_info "Selection: WM=$INSTALL_WM NVIM=$INSTALL_NVIM ZSH=$INSTALL_ZSH AUDIO=$INSTALL_AUDIO OPTIONAL=$INSTALL_OPTIONAL"
}

backup_configs() {
    if [ "$CREATE_BACKUP" = false ]; then
        log_info "Skipping backup (--no-backup flag set)"
        return
    fi

    log_info "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$BACKUP_DIR/.config"
    mkdir -p "$BACKUP_DIR/zsh"

    # Backup .config directories (include hidden entries)
    for config_dir in "$DOTFILES_DIR/.config"/* "$DOTFILES_DIR/.config"/.[!.]* "$DOTFILES_DIR/.config"/..?*; do
        [ -e "$config_dir" ] || continue
        config_name=$(basename "$config_dir")
        if [ -e "$XDG_CONFIG_HOME/$config_name" ]; then
            log_info "Backing up: $XDG_CONFIG_HOME/$config_name"
            cp -Rp "$XDG_CONFIG_HOME/$config_name" "$BACKUP_DIR/.config/" 2>/dev/null || true
        fi
    done

    # Backup zsh files
    for zsh_file in .zshrc .zshenv .zprofile; do
        if [ -f "$HOME/$zsh_file" ]; then
            log_info "Backing up: $HOME/$zsh_file"
            cp "$HOME/$zsh_file" "$BACKUP_DIR/zsh/" 2>/dev/null || true
        fi
    done

    # Backup other files
    if [ -f "$HOME/.Xresources" ]; then
        log_info "Backing up: $HOME/.Xresources"
        cp "$HOME/.Xresources" "$BACKUP_DIR/" 2>/dev/null || true
    fi

    if [ -f "$HOME/.xinitrc" ]; then
        log_info "Backing up: $HOME/.xinitrc"
        cp "$HOME/.xinitrc" "$BACKUP_DIR/" 2>/dev/null || true
    fi

    if [ -f "$HOME/.tmux.conf" ]; then
        log_info "Backing up: $HOME/.tmux.conf"
        cp "$HOME/.tmux.conf" "$BACKUP_DIR/" 2>/dev/null || true
    fi

    log_success "Backup created at: $BACKUP_DIR"
}

create_directories() {
    log_info "Creating necessary directories..."
    
    mkdir -p "$XDG_CONFIG_HOME"
    mkdir -p "$XDG_DATA_HOME"
    mkdir -p "$HOME/.fonts"
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.local/scripts"
    mkdir -p "$HOME/.zsh-plugins"

    log_success "Directories created!"
}

install_dotfiles() {
    log_info "Installing dotfiles..."

    # Ensure the destination exists
    mkdir -p "$XDG_CONFIG_HOME"

    # Copy entire .config tree (preserve attributes, copy hidden files)
    if [ -d "$DOTFILES_DIR/.config" ]; then
        # If all components are enabled, do a fast full copy
        if [ "$INSTALL_WM" = true ] && [ "$INSTALL_NVIM" = true ] && [ "$INSTALL_ZSH" = true ] && [ "$INSTALL_AUDIO" = true ]; then
            log_info "Copying all files from $DOTFILES_DIR/.config to $XDG_CONFIG_HOME"
            if cp -Rp "$DOTFILES_DIR/.config/." "$XDG_CONFIG_HOME/" 2>/dev/null; then
                log_success "All .config files copied to $XDG_CONFIG_HOME"
            else
                log_warning "cp -Rp failed for some files; falling back to per-entry copy"
            fi
        fi

        # Per-entry copy (used if any component is disabled or full copy failed)
        for entry in "$DOTFILES_DIR/.config"/* "$DOTFILES_DIR/.config"/.[!.]* "$DOTFILES_DIR/.config"/..?*; do
            [ -e "$entry" ] || continue
            entry_name=$(basename "$entry")

            case "$entry_name" in
                bspwm)
                    if [ "$INSTALL_BSPWM" = true ]; then
                        log_info "Installing bspwm config: $entry_name"
                        rm -rf "$XDG_CONFIG_HOME/$entry_name" 2>/dev/null || true
                        cp -Rp "$entry" "$XDG_CONFIG_HOME/" 2>/dev/null || log_warning "Failed to copy: $entry"
                    else
                        log_info "Skipping bspwm config: $entry_name"
                    fi
                    ;;
                sxhkd)
                    if [ "$INSTALL_SXHKD" = true ]; then
                        log_info "Installing sxhkd config: $entry_name"
                        rm -rf "$XDG_CONFIG_HOME/$entry_name" 2>/dev/null || true
                        cp -Rp "$entry" "$XDG_CONFIG_HOME/" 2>/dev/null || log_warning "Failed to copy: $entry"
                    else
                        log_info "Skipping sxhkd config: $entry_name"
                    fi
                    ;;
                polybar|picom|rofi|dunst|sx)
                    if [ "$INSTALL_WM" = true ]; then
                        log_info "Installing WM config: $entry_name"
                        rm -rf "$XDG_CONFIG_HOME/$entry_name" 2>/dev/null || true
                        cp -Rp "$entry" "$XDG_CONFIG_HOME/" 2>/dev/null || log_warning "Failed to copy: $entry"
                    else
                        log_info "Skipping WM config: $entry_name"
                    fi
                    ;;
                nvim)
                    if [ "$INSTALL_NVIM" = true ]; then
                        if [ -d "$XDG_CONFIG_HOME/$entry_name" ] && [ "$PRESERVE_EXISTING" = true ]; then
                            log_info "Preserving existing NeoVim config: $XDG_CONFIG_HOME/$entry_name"
                        else
                            log_info "Installing NeoVim config: $entry_name"
                            rm -rf "$XDG_CONFIG_HOME/$entry_name" 2>/dev/null || true
                            cp -Rp "$entry" "$XDG_CONFIG_HOME/" 2>/dev/null || log_warning "Failed to copy: $entry"
                        fi
                    else
                        log_info "Skipping NeoVim config: $entry_name"
                    fi
                    ;;
                pipewire|wireplumber)
                    if [ "$INSTALL_AUDIO" = true ]; then
                        log_info "Installing audio config: $entry_name"
                        rm -rf "$XDG_CONFIG_HOME/$entry_name" 2>/dev/null || true
                        cp -Rp "$entry" "$XDG_CONFIG_HOME/" 2>/dev/null || log_warning "Failed to copy: $entry"
                    else
                        log_info "Skipping audio config: $entry_name"
                    fi
                    ;;
                *)
                    # Copy other configs by default
                    log_info "Installing config: $entry_name"
                    rm -rf "$XDG_CONFIG_HOME/$entry_name" 2>/dev/null || true
                    cp -Rp "$entry" "$XDG_CONFIG_HOME/" 2>/dev/null || log_warning "Failed to copy: $entry"
                    ;;
            esac
        done
    else
        log_warning ".config directory not found in dotfiles; nothing to copy"
    fi

    # Apply FreeBSD-specific overrides (ensure target dirs exist)
    if [ -f "$DOTFILES_DIR/.config/bspwm/bspwmrc.freebsd" ]; then
        mkdir -p "$XDG_CONFIG_HOME/bspwm"
        cp "$DOTFILES_DIR/.config/bspwm/bspwmrc.freebsd" "$XDG_CONFIG_HOME/bspwm/bspwmrc"
        chmod +x "$XDG_CONFIG_HOME/bspwm/bspwmrc"
        log_info "Applied FreeBSD override: bspwmrc"
    fi

    if [ -f "$DOTFILES_DIR/.config/bspwm/autostart.freebsd" ]; then
        mkdir -p "$XDG_CONFIG_HOME/bspwm"
        cp "$DOTFILES_DIR/.config/bspwm/autostart.freebsd" "$XDG_CONFIG_HOME/bspwm/autostart"
        chmod +x "$XDG_CONFIG_HOME/bspwm/autostart"
        log_info "Applied FreeBSD override: autostart"
    fi

    if [ -f "$DOTFILES_DIR/.config/sxhkd/sxhkdrc.freebsd" ]; then
        mkdir -p "$XDG_CONFIG_HOME/sxhkd"
        cp "$DOTFILES_DIR/.config/sxhkd/sxhkdrc.freebsd" "$XDG_CONFIG_HOME/sxhkd/sxhkdrc"
        log_info "Applied FreeBSD override: sxhkdrc"
    fi

    if [ -f "$DOTFILES_DIR/.config/polybar/launch-freebsd.sh" ]; then
        mkdir -p "$XDG_CONFIG_HOME/polybar"
        cp "$DOTFILES_DIR/.config/polybar/launch-freebsd.sh" "$XDG_CONFIG_HOME/polybar/launch.sh"
        chmod +x "$XDG_CONFIG_HOME/polybar/launch.sh"
        log_info "Applied FreeBSD override: polybar launch"
    fi

    if [ -f "$DOTFILES_DIR/.config/picom/picom-freebsd.conf" ]; then
        mkdir -p "$XDG_CONFIG_HOME/picom"
        cp "$DOTFILES_DIR/.config/picom/picom-freebsd.conf" "$XDG_CONFIG_HOME/picom/picom.conf"
        log_info "Applied FreeBSD override: picom.conf"
    fi

    # Install fonts
    if [ -d "$DOTFILES_DIR/.fonts" ]; then
        log_info "Installing fonts..."
        mkdir -p "$HOME/.fonts"
        for font in "$DOTFILES_DIR/.fonts"/*; do
            [ -e "$font" ] || continue
            cp -Rp "$font" "$HOME/.fonts/" 2>/dev/null || true
        done
        # Update font cache if available
        if command -v fc-cache > /dev/null 2>&1; then
            log_info "Updating font cache..."
            fc-cache -f "$HOME/.fonts" || log_warning "Font cache update failed - fonts may not display correctly"
        else
            log_warning "fc-cache not found - install fontconfig to enable font caching"
        fi
    fi

    # Install .Xresources
    if [ -f "$DOTFILES_DIR/.Xresources" ]; then
        log_info "Installing .Xresources..."
        cp "$DOTFILES_DIR/.Xresources" "$HOME/.Xresources"
    fi

    # Install .tmux.conf
    if [ -f "$DOTFILES_DIR/.tmux.conf" ]; then
        log_info "Installing .tmux.conf..."
        cp "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
    fi

    # Install X11 touchpad configuration (for tap-to-click)
    if [ -f "$DOTFILES_DIR/X11/40-libinput.conf" ]; then
        log_info "Installing X11 touchpad configuration..."
        X11_CONF_DIR="/usr/local/etc/X11/xorg.conf.d"
        if [ -d "$X11_CONF_DIR" ] || mkdir -p "$X11_CONF_DIR" 2>/dev/null; then
            if cp "$DOTFILES_DIR/X11/40-libinput.conf" "$X11_CONF_DIR/" 2>/dev/null; then
                log_success "Touchpad tap-to-click configuration installed!"
            else
                log_warning "Could not install X11 config. Run as root or copy manually:"
                log_warning "  sudo cp $DOTFILES_DIR/X11/40-libinput.conf $X11_CONF_DIR/"
            fi
        else
            log_warning "Could not create $X11_CONF_DIR. Copy manually:"
            log_warning "  sudo mkdir -p $X11_CONF_DIR"
            log_warning "  sudo cp $DOTFILES_DIR/X11/40-libinput.conf $X11_CONF_DIR/"
        fi
    fi

    # Install scripts to ~/.local/scripts
    if [ -d "$DOTFILES_DIR/scripts" ]; then
        log_info "Installing scripts..."
        mkdir -p "$HOME/.local/scripts"
        for script in "$DOTFILES_DIR/scripts"/*; do
            if [ -f "$script" ]; then
                script_name=$(basename "$script")
                cp "$script" "$HOME/.local/scripts/"
                chmod +x "$HOME/.local/scripts/$script_name"
                log_info "  Installed: $script_name"
            fi
        done
        log_success "Scripts installed to ~/.local/scripts"

        # Create convenience symlink in ~/.local/bin for scripts that should be on PATH
        if [ -f "$HOME/.local/scripts/caffeine.sh" ]; then
            mkdir -p "$HOME/.local/bin"
            ln -sf "$HOME/.local/scripts/caffeine.sh" "$HOME/.local/bin/caffeine"
            chmod +x "$HOME/.local/scripts/caffeine.sh" || true
            log_info "Created convenience symlink: ~/.local/bin/caffeine -> ~/.local/scripts/caffeine.sh"
        fi
    fi

    # Install FreeBSD-specific PipeWire configuration
    if [ -f "$DOTFILES_DIR/.config/pipewire/pipewire-freebsd.conf" ]; then
        log_info "Installing FreeBSD PipeWire configuration..."
        mkdir -p "$XDG_CONFIG_HOME/pipewire"
        cp "$DOTFILES_DIR/.config/pipewire/pipewire-freebsd.conf" "$XDG_CONFIG_HOME/pipewire/pipewire.conf"
        log_success "PipeWire OSS configuration installed!"
    fi

    log_success "Dotfiles installed!"
}

install_zsh_config() {
    log_info "Installing ZSH configuration..."

    # Copy zsh files
    for zsh_file in "$DOTFILES_DIR/zsh"/.*; do
        if [ -f "$zsh_file" ]; then
            file_name=$(basename "$zsh_file")
            case "$file_name" in
                .zsh-plugins)
                    # Copy plugins directory if not present or overwriting allowed
                    if [ -d "$zsh_file" ]; then
                        if [ -d "$HOME/.zsh-plugins" ] && [ "$PRESERVE_EXISTING" = true ]; then
                            log_info "Preserving existing: $HOME/.zsh-plugins"
                        else
                            log_info "Installing zsh plugins..."
                            cp -r "$zsh_file" "$HOME/"
                        fi
                    fi
                    ;;
                .*)
                    if [ -f "$HOME/$file_name" ] && [ "$PRESERVE_EXISTING" = true ]; then
                        log_info "Preserving existing: $HOME/$file_name"
                    else
                        log_info "Installing: $file_name"
                        cp "$zsh_file" "$HOME/$file_name"
                    fi
                    ;;
            esac
        fi
    done

    # Handle .zsh-plugins directory (legacy handling)
    if [ -d "$DOTFILES_DIR/zsh/.zsh-plugins" ]; then
        if [ -d "$HOME/.zsh-plugins" ] && [ "$PRESERVE_EXISTING" = true ]; then
            log_info "Preserving existing: $HOME/.zsh-plugins"
        else
            log_info "Installing zsh plugins..."
            if [ -d "$HOME/.zsh-plugins" ]; then
                rm -rf "$HOME/.zsh-plugins"
            fi
            cp -r "$DOTFILES_DIR/zsh/.zsh-plugins" "$HOME/"
        fi
    fi
    
    # Install FreeBSD-specific zsh configuration
    log_info "Installing FreeBSD-specific ZSH configuration..."
    
    if [ -f "$DOTFILES_DIR/zsh/.zshrc.freebsd" ]; then
        if [ -f "$HOME/.zshrc" ] && [ "$PRESERVE_EXISTING" = true ]; then
            log_info "Preserving existing: $HOME/.zshrc"
        else
            cp "$DOTFILES_DIR/zsh/.zshrc.freebsd" "$HOME/.zshrc"
        fi
    fi
    
    if [ -f "$DOTFILES_DIR/zsh/.zprofile.freebsd" ]; then
        if [ -f "$HOME/.zprofile" ] && [ "$PRESERVE_EXISTING" = true ]; then
            log_info "Preserving existing: $HOME/.zprofile"
        else
            cp "$DOTFILES_DIR/zsh/.zprofile.freebsd" "$HOME/.zprofile"
        fi
    fi
    
    # Run zsh plugins installer if git is available and not preserving existing plugins
    if command -v git > /dev/null 2>&1; then
        if [ -x "$DOTFILES_DIR/install-zsh-plugins.sh" ]; then
            if [ "$PRESERVE_EXISTING" = true ]; then
                log_info "Skipping plugin installer to avoid modifying existing plugins (use --no-preserve to override)"
            else
                log_info "Installing ZSH plugins from git..."
                sh "$DOTFILES_DIR/install-zsh-plugins.sh" || log_warning "Some ZSH plugins may not have installed correctly"
            fi
        fi
    else
        log_warning "Git not found. ZSH plugins will not be installed from git."
        log_info "Install git and run: $DOTFILES_DIR/install-zsh-plugins.sh"
    fi

    # Set zsh as default shell if not already
    # FreeBSD doesn't have getent by default, so check /etc/passwd directly
    current_shell=$(grep "^$(whoami):" /etc/passwd 2>/dev/null | cut -d: -f7)
    zsh_path=$(command -v zsh 2>/dev/null || echo "/usr/local/bin/zsh")
    
    if [ -x "$zsh_path" ] && [ "$current_shell" != "$zsh_path" ]; then
        log_info "Would you like to set zsh as your default shell? (y/n)"
        read -r response
        if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
            chsh -s "$zsh_path" || log_warning "Failed to change shell. You may need to run: chsh -s $zsh_path"
        fi
    fi

    log_success "ZSH configuration installed!"
}

setup_xinitrc() {
    log_info "Setting up X11 initialization..."

    # Create .xinitrc for FreeBSD
    cat > "$HOME/.xinitrc" << 'XINITRC'
#!/bin/sh
#
# FreeBSD .xinitrc for bspwm
#

# Source Xresources
if [ -f "$HOME/.Xresources" ]; then
    xrdb -merge "$HOME/.Xresources"
fi

# Set keyboard layout
setxkbmap -option caps:backspace

# Set cursor
xsetroot -cursor_name left_ptr &

# Start dbus session if available
if command -v dbus-launch > /dev/null 2>&1 && [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval "$(dbus-launch --sh-syntax --exit-with-session)"
fi

# Start bspwm
exec bspwm
XINITRC

    chmod +x "$HOME/.xinitrc"
    log_success "X11 initialization configured!"
}

make_scripts_executable() {
    log_info "Making scripts executable..."

    # bspwm scripts (REQUIRED for bspwm to work)
    if [ -d "$XDG_CONFIG_HOME/bspwm" ]; then
        if [ -f "$XDG_CONFIG_HOME/bspwm/bspwmrc" ]; then
            chmod +x "$XDG_CONFIG_HOME/bspwm/bspwmrc"
            log_info "  Made executable: bspwmrc"
        else
            log_warning "  bspwmrc not found - bspwm may not start correctly!"
        fi
        
        if [ -f "$XDG_CONFIG_HOME/bspwm/autostart" ]; then
            chmod +x "$XDG_CONFIG_HOME/bspwm/autostart"
            log_info "  Made executable: autostart"
        fi
    else
        log_warning "  bspwm config directory not found!"
    fi

    # sxhkd config (REQUIRED for keybindings to work)
    if [ -d "$XDG_CONFIG_HOME/sxhkd" ]; then
        if [ -f "$XDG_CONFIG_HOME/sxhkd/sxhkdrc" ]; then
            chmod +x "$XDG_CONFIG_HOME/sxhkd/sxhkdrc"
            log_info "  Made executable: sxhkdrc"
        else
            log_warning "  sxhkdrc not found - keybindings may not work!"
        fi
    else
        log_warning "  sxhkd config directory not found!"
    fi

    # polybar scripts
    if [ -d "$XDG_CONFIG_HOME/polybar" ]; then
        if [ -f "$XDG_CONFIG_HOME/polybar/launch.sh" ]; then
            chmod +x "$XDG_CONFIG_HOME/polybar/launch.sh"
            log_info "  Made executable: polybar/launch.sh"
        fi
        if [ -d "$XDG_CONFIG_HOME/polybar/scripts" ]; then
            chmod +x "$XDG_CONFIG_HOME/polybar/scripts"/* 2>/dev/null || true
            log_info "  Made executable: polybar/scripts/*"
        fi
    fi

    # sx scripts
    if [ -d "$XDG_CONFIG_HOME/sx" ]; then
        if [ -f "$XDG_CONFIG_HOME/sx/sxrc" ]; then
            chmod +x "$XDG_CONFIG_HOME/sx/sxrc"
            log_info "  Made executable: sx/sxrc"
        fi
    fi

    # .xinitrc
    if [ -f "$HOME/.xinitrc" ]; then
        chmod +x "$HOME/.xinitrc"
        log_info "  Made executable: .xinitrc"
    fi

    # Ensure script-like files are executable (detect shebang)
    log_info "Ensuring script-like files are executable (shebang detection)..."
    # Find files under config and ~/.local/scripts and add +x if the first line is a shebang
    find "$XDG_CONFIG_HOME" "$HOME/.local/scripts" -type f 2>/dev/null | while IFS= read -r f; do
        if head -n 1 "$f" 2>/dev/null | grep -E '^#!' >/dev/null 2>&1; then
            chmod +x "$f" 2>/dev/null || true
            # Log relative path for readability
            rel=${f#$HOME/}
            log_info "  Made executable: $rel"
        fi
    done

    log_success "Scripts are now executable!"
}

print_post_install() {
    echo ""
    echo "=============================================="
    printf "${GREEN}Installation Complete!${NC}\n"
    echo "=============================================="
    echo ""
    echo "Post-installation steps:"
    echo ""
    echo "1. Enable required services in /etc/rc.conf:"
    echo "   Add the following lines:"
    echo "     dbus_enable=\"YES\""
    echo "     hald_enable=\"YES\""
    echo "     moused_enable=\"YES\""
    echo ""
    echo "2. Add your user to required groups:"
    echo "   pw groupmod video -m \$(whoami)"
    echo "   pw groupmod wheel -m \$(whoami)"
    echo ""
    echo "3. Configure your display:"
    echo "   Edit /etc/X11/xorg.conf or create:"
    echo "   /usr/local/etc/X11/xorg.conf.d/driver.conf"
    echo ""
    echo "4. Start X11:"
    echo "   startx"
    echo ""
    echo "5. If using a display manager:"
    echo ""
    echo "   For SDDM:"
    echo "     sudo pkg install sddm"
    echo "     sudo cp $DOTFILES_DIR/bspwm.desktop /usr/local/share/xsessions/"
    echo "     Add to /etc/rc.conf:"
    echo "       sddm_enable=\"YES\""
    echo "     Then select 'bspwm' from the session menu in SDDM"
    echo ""
    echo "   For SLiM:"
    echo "     Add to /etc/rc.conf:"
    echo "       slim_enable=\"YES\""
    echo ""
    echo "Optional packages you may want to install:"
    echo "  mpd ncmpcpp (music) — mpd may not be available as a binary package; see README"
    echo "  vnstat (network stats)"
    echo "  dunst (notifications)"
    echo "  polkit-gnome (polkit agent)"
    echo "  libudisks (udisksctl support)"
    echo "  ympd (MPD web client)"
    echo "Install with: sudo pkg install mpd ncmpcpp vnstat dunst polkit-gnome libudisks ympd"
    echo ""
    if [ "$CREATE_BACKUP" = true ]; then
        echo "Your previous configuration was backed up to:"
        echo "  $BACKUP_DIR"
        echo ""
    fi
    echo "Enjoy your new bspwm setup on FreeBSD!"
    echo ""
    echo "Caffeine mode: prevent auto-suspend and auto-lock"
    echo "  Toggle with keybinding: Super+Ctrl+C"
    echo "  Or run: ~/.local/bin/caffeine toggle"
    echo "  Status: ~/.local/bin/caffeine status"
    echo ""
}

# Main installation flow
main() {
    echo ""
    echo "=============================================="
    echo " FreeBSD BSPWM Dotfiles Installer"
    echo "=============================================="
    echo ""

    check_freebsd
    check_permissions

    # If interactive selection was requested, prompt now
    if [ "$INTERACTIVE_SELECTION" = true ]; then
        select_components
    fi

    log_info "Starting installation..."
    log_info "Dotfiles directory: $DOTFILES_DIR"
    log_info "Config directory: $XDG_CONFIG_HOME"
    echo ""

    install_packages
    backup_configs
    create_directories
    install_dotfiles
    if [ "$INSTALL_ZSH" = true ]; then
        install_zsh_config
    else
        log_info "Skipping ZSH configuration (disabled)"
    fi
    setup_xinitrc
    make_scripts_executable
    print_post_install
}

# Run main function
main
