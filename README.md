![Banner](https://user-images.githubusercontent.com/55960554/129024339-894b9a1a-5717-4935-b894-ffa1191585e0.png)
---

These are bspwm dotfiles that work on both Linux and **FreeBSD**. Originally designed for Arch Linux, this repository now includes a fully automated installation script for FreeBSD with a **full DE-like experience**.

## Features

✨ **DE-like Experience** - Full desktop environment features without the bloat:
- 🖼️ Wallpaper selector and randomizer
- 📸 Screenshot tool (full, area, window, with editor)
- 📋 Clipboard manager with history
- 🔊 Volume control with notifications
- 🔆 Brightness control with notifications
- ⚡ Power menu (lock, logout, suspend, reboot, shutdown)
- ⚙️ Quick settings menu
- 🎮 Game mode (disable compositor for gaming)
- ⌨️ Keybind helper/cheatsheet
- 🖱️ Tap-to-click touchpad support
- 🔌 PipeWire audio with OSS support (FreeBSD)
- 🔐 Polkit authentication agent
- 📁 USB auto-mount support
- 🔵 Bluetooth management
- 🌐 Network management

| Program                             | Name                                                                                                                           |
| :---                                | :---                                                                                                                           |
| Operating System                    | [FreeBSD](https://www.freebsd.org/) / [Arch Linux](https://www.archlinux.org/)                                                 |
| Window Manager                      | [bspwm](https://github.com/baskerville/bspwm)                                                                                  |
| Bar                                 | [polybar](https://github.com/jaagr/polybar)                                                                                    |
| Program Launcher                    | [rofi](https://github.com/DaveDavenport/rofi)                                                                                  |
| Wallpaper Setter                    | [feh](https://github.com/derf/feh) / [hsetroot](https://github.com/himdel/hsetroot)                                            |
| Audio System                        | [PipeWire](https://pipewire.org/) with OSS support                                                                             |
| Web Browser                         | [Firefox](https://firefox.com)                                                                                                 |
| Icon theme                          | [Flatery](https://www.pling.com/p/1332404)                                                                                     |
| Text editors/IDE's and Gtk/Qt theme | [Serenade](https://github.com/b4skyx/serenade)                                                                                 |
| Code Editor                         | [Nvim](https://neovim.io/)                                                                                                     |
| Text editors/Terminal font          | [Sarasa](https://github.com/be5invis/Sarasa-Gothic)                                                                            |
| Shell                               | [zsh](https://www.zsh.org/)                                                                                                    |
| Terminal Emulator                   | [Alacritty](https://alacritty.org/) / [st](https://st.suckless.org/)                                                           |
| Document Viewer                     | [Zathura](https://pwmt.org/projects/zathura/)                                                                                  |
| Music Player                        | [ncmpcpp/mpd](https://github.com/ncmpcpp/ncmpcpp)                                                                              |
| GTK Theme                           | [Serenade (Oomox Generated)](https://cdn.discordapp.com/attachments/792698625011482677/813491937041448970/serenade.zip)        |
| Compositor                          | [picom](https://github.com/yshui/picom)                                                                                        |
| Notification Daemon                 | [dunst](https://dunst-project.org/)                                                                                            |

---

## FreeBSD Installation (Fully Automated)

### Quick Install

Clone this repository and run the automated installer:

```sh
git clone https://github.com/berkenar1/freebsd-bspwm-dotfiles.git
cd freebsd-bspwm-dotfiles
sudo sh install-freebsd.sh
```

The installer will:
1. ✅ Install all required packages via `pkg` (including PipeWire audio)
2. ✅ Backup your existing configurations
3. ✅ Install all dotfiles and themes
4. ✅ Configure X11 (`.xinitrc`) with tap-to-click support
5. ✅ Set up ZSH with plugins
6. ✅ Install FreeBSD-optimized configs for bspwm, sxhkd, polybar, and picom
7. ✅ Install utility scripts for DE-like features
8. ✅ Configure PipeWire with OSS support

### Updating Dotfiles

After pulling updates with `git pull`, run the update script:

```sh
./update.sh
```

This will update all configurations while preserving your customizations.

### Installation Options

```sh
# Full installation (requires root)
sudo sh install-freebsd.sh

# Skip package installation (if packages are already installed)
sh install-freebsd.sh --no-packages

# Skip backup of existing configs
sudo sh install-freebsd.sh --no-backup

# Show help
sh install-freebsd.sh --help
```

### Post-Installation Steps

1. **Enable required services** in `/etc/rc.conf`:
   ```sh
   # Add these lines to /etc/rc.conf
   dbus_enable="YES"
   hald_enable="YES"
   moused_enable="YES"
   ```

2. **Add your user to required groups**:
   ```sh
   sudo pw groupmod video -m $(whoami)
   sudo pw groupmod wheel -m $(whoami)
   ```

3. **Start X11**:
   ```sh
   startx
   ```

4. **(Optional) Enable a display manager**:

   **For SDDM** (recommended):
   ```sh
   # Install SDDM
   sudo pkg install sddm
   
   # Install the bspwm session file
   sudo cp bspwm.desktop /usr/local/share/xsessions/
   
   # Enable SDDM in /etc/rc.conf
   sddm_enable="YES"
   ```
   Then select "bspwm" from the session dropdown in SDDM.

   **For SLiM**:
   ```sh
   # Add to /etc/rc.conf
   slim_enable="YES"
   ```

### Required FreeBSD Packages

The installer will automatically install these packages:

**Core:**
- xorg, bspwm, sxhkd, polybar, rofi, dunst, picom, feh, hsetroot

**Terminal & Shell:**
- alacritty, zsh, zsh-autosuggestions, zsh-syntax-highlighting, tmux

**Audio (PipeWire):**
- pipewire, wireplumber, libspa-oss, pamixer, playerctl

**Utilities:**
- neofetch, neovim, ncmpcpp, mpv, zathura, conky, lf, fzf, fd-find, ripgrep, exa, scrot, i3lock

**Note about music (MPD):**
- `ncmpcpp` is a client for `mpd` (Music Player Daemon). `mpd` may not be available as a binary package in some FreeBSD repositories; if you want a web client instead, consider `ympd`, or install `mpd` from ports.

**DE-like Utilities (optional):**
- polkit-gnome, pcmanfm, arandr, pavucontrol, libudisks, redshift, nitrogen, clipmenu, rofi-emoji

**Fonts:**
- terminus-font, nerd-fonts, font-awesome

---

## Linux Installation

For Arch Linux or other Linux distributions, you can use the original installer:

```sh
bash <(curl -s https://raw.githubusercontent.com/b4skyx/dotfiles/master/install.sh)
```

Or manually symlink configurations using:

```sh
sh symlink.sh
```

---

## Keyboard Shortcuts

### Window Management
| Shortcut | Action |
|----------|--------|
| `Super + Return` | Open terminal (Alacritty) |
| `Super + Shift + Return` | Open terminal with tmux |
| `Super + q` | Close window |
| `Super + Shift + q` | Kill window |
| `Super + f` | Toggle fullscreen |
| `Super + u` | Toggle floating |
| `Super + m` | Toggle monocle layout |
| `Super + Arrow Keys` | Focus window in direction |
| `Super + Shift + Arrow Keys` | Swap window in direction |
| `Super + Alt + Arrow Keys` | Resize window |
| `Alt + Left Click (drag)` | Move floating window |
| `Alt + Right Click (drag)` | Resize floating window |

### Workspaces
| Shortcut | Action |
|----------|--------|
| `Super + 1-9` | Switch to workspace |
| `Super + Shift + 1-9` | Move window to workspace |
| `Super + Tab` | Last workspace |
| `Super + [ / ]` | Previous / Next workspace |
| `Alt + Tab` | Cycle occupied workspaces |

### Applications
| Shortcut | Action |
|----------|--------|
| `Alt + Space` | Application launcher (Rofi) |
| `Super + w` | Window switcher |
| `Super + r` | Run prompt |
| `Super + e` | File manager |
| `Super + b` | Web browser |
| `Super + t` | Text editor (nvim) |

### DE-like Utilities
| Shortcut | Action |
|----------|--------|
| `Super + s` | Quick settings menu |
| `Super + x` | Power menu |
| `Super + h` | Keybind helper |
| `Super + v` | Clipboard manager |
| `Super + Shift + w` | Wallpaper selector |
| `Super + Ctrl + w` | Random wallpaper |
| `Super + .` | Emoji picker |
| `Super + F12` | Toggle game mode |

### Screenshots
| Shortcut | Action |
|----------|--------|
| `Print` | Screenshot (full screen) |
| `Shift + Print` | Screenshot (area selection) |
| `Super + Print` | Screenshot (active window) |
| `Super + Shift + Print` | Screenshot menu |

### System
| Shortcut | Action |
|----------|--------|
| `Super + l` | Lock screen |
| `Super + Escape` | Reload sxhkd |
| `Super + Shift + Escape` | Reload polybar |
| `Super + Alt + r` | Restart bspwm |
| `Super + Alt + q` | Quit bspwm |

### Media Controls
| Shortcut | Action |
|----------|--------|
| `XF86AudioRaiseVolume` | Volume up |
| `XF86AudioLowerVolume` | Volume down |
| `XF86AudioMute` | Toggle mute |
| `XF86MonBrightnessUp` | Brightness up |
| `XF86MonBrightnessDown` | Brightness down |
| `XF86AudioPlay` | Play/Pause |
| `XF86AudioNext` | Next track |
| `XF86AudioPrev` | Previous track |

### Notifications
| Shortcut | Action |
|----------|--------|
| `Super + Space` | Close notification |
| `Super + Shift + Space` | Close all notifications |
| `Super + d` | Toggle do not disturb |

---

## Configuration Files

| File | Description |
|------|-------------|
| `.config/bspwm/bspwmrc` | bspwm configuration |
| `.config/sxhkd/sxhkdrc` | Keyboard shortcuts |
| `.config/polybar/` | Polybar status bar |
| `.config/picom/` | Compositor settings |
| `.config/rofi/` | Application launcher |
| `.config/dunst/` | Notification daemon |
| `.config/alacritty/` | Terminal emulator |
| `.config/nvim/` | Neovim configuration |
| `.config/pipewire/` | PipeWire audio configuration |
| `scripts/` | Utility scripts |
| `X11/` | X11 input configuration (tap-to-click) |
| `zsh/.zshrc` | ZSH shell configuration |

---

## Utility Scripts

Located in `~/.local/scripts/` after installation:

| Script | Description |
|--------|-------------|
| `powermenu.sh` | Power menu (lock, logout, suspend, reboot, shutdown) |
| `screenshot.sh` | Screenshot tool with multiple modes |
| `clipboard.sh` | Clipboard manager |
| `wallpaper.sh` | Wallpaper selector and randomizer |
| `volume.sh` | Volume control with notifications |
| `brightness.sh` | Brightness control with notifications |
| `quicksettings.sh` | Quick settings menu |
| `keybinds.sh` | Keybind helper/cheatsheet |
| `gamemode.sh` | Game mode toggle |

---

## PipeWire Audio (FreeBSD)

This setup uses PipeWire with OSS support for FreeBSD. The configuration automatically:
- Starts PipeWire, WirePlumber, and pipewire-pulse
- Provides PulseAudio compatibility (most apps work without changes)
- Uses FreeBSD's native OSS audio backend

To manually control audio:
```sh
# GUI volume control
pavucontrol

# Command line volume
~/.local/scripts/volume.sh up 5
~/.local/scripts/volume.sh down 5
~/.local/scripts/volume.sh mute
```

---

## Related Resources

- [Scripts](https://github.com/b4skyx/unix-scripts): The scripts I use along with my dots
- [Serenade](https://github.com/b4skyx/serenade): Colorscheme
- [Discord Theme](https://github.com/b4skyx/discord-serenade)
- [Gtk Theme](https://cdn.discordapp.com/attachments/792698625011482677/813491937041448970/serenade.zip)

---

## Preview

#### Home
![main](https://user-images.githubusercontent.com/55960554/129024488-53014722-9bce-4b23-b277-b9d137a5c918.png)

#### Floating
![floating](https://user-images.githubusercontent.com/55960554/129025092-102fe492-33ea-4f14-b048-0fbe8818986d.png)

#### Neovim/Rofi
![Code](https://user-images.githubusercontent.com/55960554/129025237-0e002470-7bb6-4570-a1dd-877107815cf9.png)

#### Busy Tiled
![busy](https://user-images.githubusercontent.com/55960554/129025329-f8c9a5a1-3ef4-495a-9d4b-700aef4e5a72.png)

#### Locksceen
![lock](https://user-images.githubusercontent.com/55960554/129025379-a36d9911-4e86-463e-a4ea-52f21bc8e9b7.png)

## Wallpaper
![wallpaper](.config/wallpaper.jpg)
