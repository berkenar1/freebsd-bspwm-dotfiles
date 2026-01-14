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

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --no-packages)
            INSTALL_PACKAGES=false
            ;;
        --no-backup)
            CREATE_BACKUP=false
            ;;
        --help|-h)
            echo "FreeBSD BSPWM Dotfiles Installer"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --no-packages  Skip package installation"
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
# Core packages
CORE_PACKAGES="
xorg
bspwm
sxhkd
polybar
rofi
dunst
picom
feh
hsetroot
"

# Terminal and shell
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
UTIL_PACKAGES="
neofetch
neovim
mpd
ncmpcpp
mpv
zathura
zathura-pdf-poppler
conky
lf
fzf
fd-find
ripgrep
exa
xautolock
xdotool
xclip
xsel
scrot
i3lock
"

# DE-like utilities (optional but recommended)
DE_PACKAGES="
lxpolkit
pcmanfm
arandr
pavucontrol
blueman
udiskie
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

    log_info "Installing core packages..."
    for pkg in $CORE_PACKAGES; do
        if pkg info -e "$pkg" > /dev/null 2>&1; then
            log_info "Package already installed: $pkg"
        else
            log_info "Installing: $pkg"
            pkg install -y "$pkg" || log_warning "Failed to install: $pkg"
        fi
    done

    log_info "Installing shell packages..."
    for pkg in $SHELL_PACKAGES; do
        if pkg info -e "$pkg" > /dev/null 2>&1; then
            log_info "Package already installed: $pkg"
        else
            log_info "Installing: $pkg"
            pkg install -y "$pkg" || log_warning "Failed to install: $pkg"
        fi
    done

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

    log_info "Installing audio packages (PipeWire)..."
    for pkg in $AUDIO_PACKAGES; do
        if pkg info -e "$pkg" > /dev/null 2>&1; then
            log_info "Package already installed: $pkg"
        else
            log_info "Installing: $pkg"
            pkg install -y "$pkg" || log_warning "Failed to install: $pkg"
        fi
    done

    log_info "Installing DE-like utility packages..."
    for pkg in $DE_PACKAGES; do
        if pkg info -e "$pkg" > /dev/null 2>&1; then
            log_info "Package already installed: $pkg"
        else
            log_info "Installing: $pkg"
            pkg install -y "$pkg" || log_warning "Failed to install: $pkg (optional)"
        fi
    done

    log_success "Package installation complete!"
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

    # Backup .config directories
    for config_dir in "$DOTFILES_DIR/.config"/*; do
        config_name=$(basename "$config_dir")
        if [ -e "$XDG_CONFIG_HOME/$config_name" ]; then
            log_info "Backing up: $XDG_CONFIG_HOME/$config_name"
            cp -r "$XDG_CONFIG_HOME/$config_name" "$BACKUP_DIR/.config/" 2>/dev/null || true
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

    # Install .config directories
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
            
            log_info "Installing config: $config_name"
            cp -r "$config_dir" "$dest"
        elif [ -f "$config_dir" ]; then
            # Handle individual files in .config (like redshift.conf)
            config_name=$(basename "$config_dir")
            dest="$XDG_CONFIG_HOME/$config_name"
            
            if [ -L "$dest" ] || [ -f "$dest" ]; then
                rm "$dest"
            fi
            
            log_info "Installing config file: $config_name"
            cp "$config_dir" "$dest"
        fi
    done

    # Install FreeBSD-specific configurations
    log_info "Installing FreeBSD-specific configurations..."
    
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

    # Install fonts
    if [ -d "$DOTFILES_DIR/.fonts" ]; then
        log_info "Installing fonts..."
        for font in "$DOTFILES_DIR/.fonts"/*; do
            font_name=$(basename "$font")
            cp "$font" "$HOME/.fonts/" 2>/dev/null || true
        done
        # Update font cache
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
                    # Copy plugins directory
                    if [ -d "$zsh_file" ]; then
                        log_info "Installing zsh plugins..."
                        cp -r "$zsh_file" "$HOME/"
                    fi
                    ;;
                .*)
                    log_info "Installing: $file_name"
                    cp "$zsh_file" "$HOME/$file_name"
                    ;;
            esac
        fi
    done

    # Handle .zsh-plugins directory
    if [ -d "$DOTFILES_DIR/zsh/.zsh-plugins" ]; then
        log_info "Installing zsh plugins..."
        if [ -d "$HOME/.zsh-plugins" ]; then
            rm -rf "$HOME/.zsh-plugins"
        fi
        cp -r "$DOTFILES_DIR/zsh/.zsh-plugins" "$HOME/"
    fi
    
    # Install FreeBSD-specific zsh configuration
    log_info "Installing FreeBSD-specific ZSH configuration..."
    
    if [ -f "$DOTFILES_DIR/zsh/.zshrc.freebsd" ]; then
        cp "$DOTFILES_DIR/zsh/.zshrc.freebsd" "$HOME/.zshrc"
    fi
    
    if [ -f "$DOTFILES_DIR/zsh/.zprofile.freebsd" ]; then
        cp "$DOTFILES_DIR/zsh/.zprofile.freebsd" "$HOME/.zprofile"
    fi
    
    # Run zsh plugins installer if git is available
    if command -v git > /dev/null 2>&1; then
        if [ -x "$DOTFILES_DIR/install-zsh-plugins.sh" ]; then
            log_info "Installing ZSH plugins from git..."
            sh "$DOTFILES_DIR/install-zsh-plugins.sh" || log_warning "Some ZSH plugins may not have installed correctly"
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
    if [ "$CREATE_BACKUP" = true ]; then
        echo "Your previous configuration was backed up to:"
        echo "  $BACKUP_DIR"
        echo ""
    fi
    echo "Enjoy your new bspwm setup on FreeBSD!"
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
    
    log_info "Starting installation..."
    log_info "Dotfiles directory: $DOTFILES_DIR"
    log_info "Config directory: $XDG_CONFIG_HOME"
    echo ""

    install_packages
    backup_configs
    create_directories
    install_dotfiles
    install_zsh_config
    setup_xinitrc
    make_scripts_executable
    print_post_install
}

# Run main function
main
