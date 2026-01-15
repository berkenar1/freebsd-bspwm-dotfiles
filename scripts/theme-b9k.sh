#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEME_DIR="$ROOT_DIR/third_party/beyond9thousand-dotfiles/.config"
BACKUP_PREFIX="$ROOT_DIR/backups/b9k"

usage() {
  cat <<'USAGE'
Usage: theme-b9k.sh apply|revert [--home]

Commands:
  apply    Apply the b9k theme to the target (default target is $HOME/.config)
  revert   Revert the last b9k install from backups (restores $HOME/.config/*)

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
    echo "Applied. Backup created at: $backup_dir"
  else
    echo "Dry run: would backup and copy files from $THEME_DIR to $TARGET_DIR"
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
  *)
    usage
    exit 1
    ;;
esac
