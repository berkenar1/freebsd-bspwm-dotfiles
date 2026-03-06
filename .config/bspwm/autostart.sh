#!/usr/bin/env bash

#                __             __             __
#   ____ ___  __/ /_____  _____/ /_____ ______/ /_
#  / __ `/ / / / __/ __ \/ ___/ __/ __ `/ ___/ __/
# / /_/ / /_/ / /_/ /_/ (__  ) /_/ /_/ / /  / /_
# \__,_/\__,_/\__/\____/____/\__/\__,_/_/   \__/
#

# Restart default apps (skip any that are not installed)
declare -a restart=(xfce4-power-manager picom sxhkd xbanish
        copyq playerctld plank flameshot touchegg dunst)
for i in "${restart[@]}"; do
        command -v "$i" >/dev/null 2>&1 || continue
        pgrep -x "$i" | xargs kill 2>/dev/null || true
	sleep 0.5
	eval "$i" &
done

# Exclusive apps
if command -v stalonetray >/dev/null 2>&1 && [[ ! $(pidof stalonetray) ]]; then
	sleep 0.5
	xdo hide -N stalonetray
	touch "/tmp/syshide.lock"
fi

# Unlock keepass database
if [[ $(pgrep --exact keepassxc) ]]; then
	sleep 0.5

	_unlock_db() {
		tmp_passwd=$(secret-tool lookup keepass Passwords)
		database="$HOME/Documents/Sync/Backup_Database/application settings files/Password/Passwords.kdbx"
		dbus-send --print-reply --dest=org.keepassxc.KeePassXC.MainWindow /keepassxc org.keepassxc.KeePassXC.MainWindow.openDatabase string:"$database" string:"$tmp_passwd" >/dev/null 2>&1
	}

	_unlock_db &
fi

if command -v eww >/dev/null 2>&1; then
        pgrep -x "eww" | xargs kill 2>/dev/null || true
fi
if command -v control_box >/dev/null 2>&1; then
        control_box -ewwopen
fi

# Launch polybar
if command -v polybar >/dev/null 2>&1; then
        _polybar_launch="${XDG_CONFIG_HOME:-$HOME/.config}/polybar/launch-freebsd.sh"
        [ ! -x "$_polybar_launch" ] && _polybar_launch="${XDG_CONFIG_HOME:-$HOME/.config}/polybar/launch.sh"
        if [ -x "$_polybar_launch" ]; then
                "$_polybar_launch" &
        else
                killall -q polybar 2>/dev/null
                polybar -c "${XDG_CONFIG_HOME:-$HOME/.config}/polybar/config.ini" main &
        fi
fi

dunstify -i window_list "BSPWM" "Completed autostarting all apps"
