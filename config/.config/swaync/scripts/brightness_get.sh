#!/usr/bin/env bash
# swaync brightness slider: reads current backlight as 0-100.
set -euo pipefail
read -r _ _ cur pct _ < <(brightnessctl -m | tr ',' ' ')
echo "${pct%\%}"
