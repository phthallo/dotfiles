#!/usr/bin/env bash
# swaync brightness slider: applies a 0-100 value. Floored at 5 so the
# screen never goes fully black and strands you with no way to see the slider.
set -euo pipefail
v="${1:-50}"
v="${v%.*}"
(( v < 5 )) && v=5
(( v > 100 )) && v=100
brightnessctl -q set "${v}%"
