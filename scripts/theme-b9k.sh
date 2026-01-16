#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEME_DIR="$ROOT_DIR/third_party/beyond9thousand-dotfiles/.config"
BACKUP_PREFIX="$ROOT_DIR/backups/b9k"

usage() {
  cat <<'USAGE'
Usage: theme-b9k.sh apply|revert|update [--home]

Commands:
  apply    Apply the b9k theme to the target (default target is $HOME/.config)
  revert   Revert the last b9k install from backups (restores $HOME/.config/*)
  update   Pull the latest b9k theme from the bundled git repo and re-apply it

Options:
  --home   Target $HOME/.config (default)
  --dry    Print what would be done (no changes)
USAGE
}

TARGET_HOME=true
DRY=false

# parse optional flags
for arg in "$@"; do
  case "$arg" in
    --home) TARGET_HOME=true ;;
    --dry) DRY=true ;;
  esac
done

TARGET_DIR="$HOME/.config"

do_backup() {
  timestamp=$(date +%Y%m%d-%H%M%S)
  backup_dir="$BACKUP_PREFIX-$timestamp"
  mkdir -p "$backup_dir"
  files=(bspwm sxhkd rofi polybar alacritty picom eww Kvantum)
  for d in "${files[@]}"; do
    if [ -d "$TARGET_DIR/$d" ]; then
      echo "Backing up $TARGET_DIR/$d -> $backup_dir/";
      if [ "$DRY" = false ]; then
        mv "$TARGET_DIR/$d" "$backup_dir/"
      fi
    fi
  done
  echo "$backup_dir"
}

apply() {
  if [ ! -d "$THEME_DIR" ]; then
    echo "Theme files not found at $THEME_DIR" >&2
    exit 1
  fi

  echo "Applying b9k theme to $TARGET_DIR"
  if [ "$DRY" = false ]; then
    backup_dir=$(do_backup)
    cp -a "$THEME_DIR/." "$TARGET_DIR/"

    # Ensure namespaced polybar color file is installed
    mkdir -p "$TARGET_DIR/bspwm/polybar"
    if [ -f "$THEME_DIR/not_in_use/polybar/colors.ini" ]; then
      cp -f "$THEME_DIR/not_in_use/polybar/colors.ini" "$TARGET_DIR/bspwm/polybar/colors-b9k.ini"
      echo "Installed namespaced polybar colors: $TARGET_DIR/bspwm/polybar/colors-b9k.ini"
      # Also copy other bundled polybar fragments (modules/decor/system) into namespaced dir
      for f in modules.ini decor.ini system.ini; do
        if [ -f "$THEME_DIR/not_in_use/polybar/$f" ]; then
          cp -f "$THEME_DIR/not_in_use/polybar/$f" "$TARGET_DIR/bspwm/polybar/$f"
          echo "Installed polybar fragment: $TARGET_DIR/bspwm/polybar/$f"
        fi
      done
    elif [ -f "$THEME_DIR/bspwm/polybar/colors-b9k.ini" ]; then
      cp -f "$THEME_DIR/bspwm/polybar/colors-b9k.ini" "$TARGET_DIR/bspwm/polybar/colors-b9k.ini"
      echo "Installed namespaced polybar colors: $TARGET_DIR/bspwm/polybar/colors-b9k.ini"
      for f in modules.ini decor.ini system.ini; do
        if [ -f "$THEME_DIR/bspwm/polybar/$f" ]; then
          cp -f "$THEME_DIR/bspwm/polybar/$f" "$TARGET_DIR/bspwm/polybar/$f"
          echo "Installed polybar fragment: $TARGET_DIR/bspwm/polybar/$f"
        fi
      done
    else
      echo "Warning: no polybar colors found in theme to install (expected colors.ini or colors-b9k.ini)"
    fi

    echo "Applied. Backup created at: $backup_dir"
  else
    echo "Dry run: would backup and copy files from $THEME_DIR to $TARGET_DIR and install namespaced polybar colors (colors-b9k.ini)"
  fi
}

revert() {
  last_backup=$(ls -d "$BACKUP_PREFIX-"* 2>/dev/null || true | sort | tail -n1)
  if [ -z "$last_backup" ]; then
    echo "No b9k backup found to revert." >&2
    exit 1
  fi
  echo "Reverting using backup: $last_backup"
  for d in bspwm sxhkd rofi polybar alacritty picom eww Kvantum; do
    if [ -d "$last_backup/$d" ]; then
      echo "Restoring $d -> $TARGET_DIR/$d"
      if [ "$DRY" = false ]; then
        rm -rf "$TARGET_DIR/$d"
        mv "$last_backup/$d" "$TARGET_DIR/$d"
      fi
    fi
  done
  echo "Revert complete (used $last_backup)."
}

update() {
  repo="$ROOT_DIR/third_party/beyond9thousand-dotfiles"
  if [ ! -d "$repo" ]; then
    echo "Theme repo not found at $repo" >&2
    exit 1
  fi

  echo "Updating b9k theme repository at: $repo"
  if [ -d "$repo/.git" ]; then
    if [ "$DRY" = false ]; then
      git -C "$repo" fetch --all --prune
      headbranch=$(git -C "$repo" remote show origin | awk -F': ' '/HEAD branch/ {print $2}')
      if [ -n "$headbranch" ]; then
        git -C "$repo" checkout "$headbranch" || true
        git -C "$repo" pull --ff-only origin "$headbranch" || git -C "$repo" reset --hard "origin/$headbranch"
      else
        git -C "$repo" pull --ff-only || true
      fi
    else
      echo "Dry run: would fetch and pull in $repo"
    fi
  else
    echo "Not a git repository: $repo (skipping fetch/pull)"
  fi

  echo "Re-applying theme from updated repo (will create a backup)"
  apply
}

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

case "$1" in
  apply)
    apply
    ;;
  revert)
    revert
    ;;
  update)
    update
    ;;
  *)
    usage
    exit 1
    ;;
esac
