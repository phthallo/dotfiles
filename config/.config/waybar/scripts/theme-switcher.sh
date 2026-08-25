#!/usr/bin/env bash
# Cycles the desktop wallpaper and points hyprlock at the same image.
#
# Driven by the  button in waybar: left click steps to the next wallpaper,
# right click picks one at random. hyprpaper does the drawing, so there are no
# transitions to configure - it swaps the image immediately.

WALLPAPER_DIR="$HOME/dotfiles/assets"
CURRENT_WALLPAPER_FILE="$HOME/.cache/current_wallpaper"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"
HYPRLOCK_CONF="$HOME/.config/hypr/hyprlock.conf"

mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | sort)

if [ ${#WALLPAPERS[@]} -eq 0 ]; then
  notify-send "Theme Switcher" "No wallpapers found in $WALLPAPER_DIR"
  exit 1
fi

get_current_index() {
  [[ -f "$CURRENT_WALLPAPER_FILE" ]] && cat "$CURRENT_WALLPAPER_FILE" || echo "0"
}

apply_theme() {
  local wallpaper_path="$1" index="$2"
  local wallpaper_name
  wallpaper_name=$(basename "$wallpaper_path")

  # hyprpaper 0.8 accepts an empty monitor field and then quietly ignores the
  # request, so name every output explicitly instead
  local applied=0 monitor
  while read -r monitor; do
    hyprctl hyprpaper wallpaper "${monitor},${wallpaper_path}" >/dev/null && applied=1
  done < <(hyprctl monitors -j | jq -r '.[].name')

  if [ "$applied" -eq 0 ]; then
    notify-send "Theme Switcher" "hyprpaper refused ${wallpaper_name} - is ipc = 1 set in hyprpaper.conf?"
    return 1
  fi
  hyprctl hyprpaper unload unused >/dev/null 2>&1 || true

  echo "$index" > "$CURRENT_WALLPAPER_FILE"
  # rewrite both configs so the choice survives a restart or a lock screen
  update_conf_path "$HYPRPAPER_CONF" "$wallpaper_path"
  update_conf_path "$HYPRLOCK_CONF" "$wallpaper_path"
  notify-send "Theme Switcher" "Applied: $wallpaper_name"
}

# update_conf_path <file> <wallpaper> - swaps the path inside the first
# wallpaper/background block, leaving the rest of the file alone.
#
# The path is written back ~-relative and the backup goes to ~/.cache, because
# both of these files are stowed out of the dotfiles repo: an absolute
# /home/<user> path or a stray .backup would show up as a dirty working tree
# every time the wallpaper changes.
update_conf_path() {
  local conf="$1" wallpaper_path="${2/#$HOME/\~}"
  [[ -f "$conf" ]] || return 0
  local backup="$HOME/.cache/theme-switcher/$(basename "$conf").backup"
  mkdir -p "$(dirname "$backup")"
  [[ -f "$backup" ]] || cp "$conf" "$backup"
  sed -i "/\(background\|wallpaper\) {/,/}/{s|path = .*|path = ${wallpaper_path}|}" "$conf"
}

case "${1:-next}" in
"next")
  next_index=$((($(get_current_index) + 1) % ${#WALLPAPERS[@]}))
  apply_theme "${WALLPAPERS[$next_index]}" "$next_index"
  ;;
"random")
  random_index=$((RANDOM % ${#WALLPAPERS[@]}))
  apply_theme "${WALLPAPERS[$random_index]}" "$random_index"
  ;;
"restore")
  index=$(get_current_index)
  apply_theme "${WALLPAPERS[$index]}" "$index"
  ;;
"list")
  selected=$(printf "%s\n" "${WALLPAPERS[@]##*/}" | wofi --dmenu --prompt "Choose Wallpaper" --insensitive)
  if [ -n "$selected" ]; then
    for i in "${!WALLPAPERS[@]}"; do
      if [[ "${WALLPAPERS[$i]##*/}" == "$selected" ]]; then
        apply_theme "${WALLPAPERS[$i]}" "$i"
        break
      fi
    done
  else
    notify-send "Theme Switcher" "No wallpaper selected."
  fi
  ;;
esac
