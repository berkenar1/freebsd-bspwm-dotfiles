![Banner](https://user-images.githubusercontent.com/55960554/129024339-894b9a1a-5717-4935-b894-ffa1191585e0.png)
---

These are bspwm dotfiles that work on both Linux and **FreeBSD**. Originally designed for Arch Linux, this repository now includes a fully automated installation script for FreeBSD.

| Program                             | Name                                                                                                                           |
| :---                                | :---                                                                                                                           |
| Operating System                    | [FreeBSD](https://www.freebsd.org/) / [Arch Linux](https://www.archlinux.org/)                                                 |
| Window Manager                      | [bspwm](https://github.com/baskerville/bspwm)                                                                                  |
| Bar                                 | [polybar](https://github.com/jaagr/polybar)                                                                                    |
| Program Launcher                    | [rofi](https://github.com/DaveDavenport/rofi)                                                                                  |
| Wallpaper Setter                    | [feh](https://github.com/derf/feh) / [hsetroot](https://github.com/himdel/hsetroot)                                            |
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
1. ✅ Install all required packages via `pkg`
2. ✅ Backup your existing configurations
3. ✅ Install all dotfiles and themes
4. ✅ Configure X11 (`.xinitrc`)
5. ✅ Set up ZSH with plugins
6. ✅ Install FreeBSD-optimized configs for bspwm, sxhkd, polybar, and picom

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

4. **(Optional) Enable display manager** (SLiM):
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

**Utilities:**
- neofetch, neovim, mpd, ncmpcpp, mpv, zathura, conky, lf, fzf, fd-find, ripgrep, exa

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

| Shortcut | Action |
|----------|--------|
| `Super + Return` | Open terminal (Alacritty) |
| `Super + Shift + Return` | Open terminal with tmux |
| `Alt + Space` | Open application launcher (Rofi) |
| `Super + w` | Window switcher |
| `Super + q` | Close window |
| `Super + Shift + q` | Kill window |
| `Super + f` | Toggle fullscreen |
| `Super + u` | Toggle floating |
| `Super + m` | Toggle monocle layout |
| `Super + 1-9` | Switch to workspace |
| `Super + Shift + 1-9` | Move window to workspace |
| `Super + Arrow Keys` | Focus window in direction |
| `Super + Shift + Arrow Keys` | Swap window in direction |
| `Super + Alt + Arrow Keys` | Resize window |
| `Super + Shift + l` | Lock screen |
| `Print` | Screenshot |

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
| `zsh/.zshrc` | ZSH shell configuration |

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
