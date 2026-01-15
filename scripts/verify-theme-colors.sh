#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_ROOT="$HOME/.config"

echo "Verifying theme color isolation for b9k..."

errors=0

check_file() {
  local f=$1
  if [ -e "$f" ]; then
    echo "OK: $f"
  else
    echo "MISSING: $f"; errors=$((errors+1))
  fi
}

# 1) Check polybar include references in not_in_use config
poly_conf="$ROOT_DIR/.config/not_in_use/polybar/config.ini"
if [ -f "$poly_conf" ]; then
  echo "Checking $poly_conf for include-file entries..."
  grep -E "include-file" "$poly_conf" | while read -r line; do
    path="${line#*=}"
    # trim carriage returns and surrounding whitespace
    # strip carriage return characters
    path="${path//$'\r'/}"
    # trim leading whitespace
    path="${path#${path%%[![:space:]]*}}"
    # trim trailing whitespace
    path="${path%${path##*[![:space:]]}}"
    # expand leading ~ to $HOME (parameter expansion)
    path="${path/#\~/$HOME}"
    check_file "$path"
  done
else
  echo "No not_in_use polybar config at $poly_conf (skipping)"
fi

# 2) Check rofi theme referenecs
rofi_conf="$CONFIG_ROOT/rofi/config.rasi"
if [ -f "$rofi_conf" ]; then
  echo "Checking rofi config for @theme references..."
  grep -E "@theme" "$rofi_conf" || echo "No @theme lines found in $rofi_conf"
else
  echo "No rofi config at $rofi_conf"
fi

# 3) Check eww scss import
eww_scss="$CONFIG_ROOT/eww/eww.scss"
if [ -f "$eww_scss" ]; then
  echo "Checking eww scss for imported colors.scss..."
  if grep -q "colors.scss" "$eww_scss"; then
    check_file "$CONFIG_ROOT/eww/scss/colors.scss"
  else
    echo "No colors.scss import in $eww_scss"
  fi
else
  echo "No eww scss at $eww_scss"
fi

# 4) Alacritty YAML parse (soft validate)
alac_conf="$CONFIG_ROOT/alacritty/alacritty.yml"
if [ -f "$alac_conf" ]; then
  echo "Attempting to parse $alac_conf with Python PyYAML (if available)..."
  python - <<PY || echo "Note: could not run strict YAML validation (pyyaml missing or parse error)"
try:
    import sys
    import yaml
    yaml.safe_load(open('$alac_conf'))
    print('OK: alacritty YAML parsed')
except ImportError:
    print('SKIP: PyYAML not installed; skipping strict validation')
except Exception as e:
    print('ERROR: alacritty YAML parse failed:', e)
    sys.exit(2)
PY
fi

# Final status
if [ "$errors" -eq 0 ]; then
  echo "\nAll checks passed (no missing referenced color files)."
  exit 0
else
  echo "\nCompleted with $errors missing files. See above for details."
  exit 1
fi
