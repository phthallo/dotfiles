#!/usr/bin/env bash
# Cycles the desktop theme through ~/.config/theme-switcher.
#
# Driven by the  button in waybar: left click opens a picker, right click
# jumps to a random theme. Each switch reruns apply-theme.sh, which restyles
# waybar, swaync, hyprlock, kitty, wofi, starship and the rest in one pass and
# reloads them, so the whole desktop changes together.
#
#   theme-switcher.sh menu     open a wofi picker listing every theme
#   theme-switcher.sh next     step to the next theme in the list
#   theme-switcher.sh prev     step back one
#   theme-switcher.sh random   pick a random theme that is not the current one
#   theme-switcher.sh <name>   jump straight to a named theme
#
# The previous wallpaper-only version of this script is kept alongside as
# wallpaper-cycler.sh - it swaps the image without touching the palette.
set -euo pipefail

BASE="$HOME/.config/theme-switcher"
APPLY="$BASE/apply-theme.sh"
STATE="$BASE/current-theme.json"

[[ -x "$APPLY" ]] || { notify-send "Theme Switcher" "apply-theme.sh not found in $BASE"; exit 1; }

# "dynamic" generates its palette from a wallpaper you choose, so with no
# argument it opens a rofi picker and blocks. That is the opposite of a
# one-click cycle, so it is reachable by name only.
mapfile -t THEMES < <(find "$BASE/themes" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' \
                      | grep -vx dynamic | sort)
[[ ${#THEMES[@]} -gt 0 ]] || { notify-send "Theme Switcher" "No themes found"; exit 1; }

current=$(jq -r '.theme // empty' "$STATE" 2>/dev/null || true)

index_of() {
  local want=$1 i
  for i in "${!THEMES[@]}"; do
    [[ "${THEMES[$i]}" == "$want" ]] && { printf '%s' "$i"; return 0; }
  done
  return 1
}

cur_i=$(index_of "$current" || printf '%s' -1)

case "${1:-menu}" in
  menu)
    # A second click on the waybar button should dismiss the picker rather than
    # stack another one, so treat an already-open wofi as "close and stop".
    if pkill -x wofi 2>/dev/null; then exit 0; fi

    # wofi --dmenu hands back the line it was given, so keep a display -> dir
    # map instead of trying to parse the pretty name back out.
    # Read every theme.json in ONE jq call. Spawning jq per theme cost ~10
    # processes before wofi was even launched, and wofi is already cold-started
    # on each open - unlike swaync, which is a daemon whose panel simply maps.
    # Every millisecond here is dead air before the open animation begins.
    declare -A BY_LABEL=() PRETTY=()
    _files=()
    for t in "${THEMES[@]}" dynamic; do
      [[ -f "$BASE/themes/$t/theme.json" ]] && _files+=("$BASE/themes/$t/theme.json")
    done
    if [[ ${#_files[@]} -gt 0 ]]; then
      while IFS=$'\t' read -r _file _name; do
        PRETTY["$(basename "$(dirname "$_file")")"]=$_name
      done < <(jq -r '[input_filename, (.name // "")] | @tsv' "${_files[@]}" 2>/dev/null)
    fi

    lines=()
    for t in "${THEMES[@]}" dynamic; do
      [[ -d "$BASE/themes/$t" ]] || continue
      label="${PRETTY[$t]:-$t}"
      [[ "$t" == dynamic ]] && label="$label  (wallpaper)"
      # Mark the active theme so the modal is also a status readout.
      if [[ "$t" == "$current" ]]; then label="● $label"; else label="  $label"; fi
      BY_LABEL["$label"]=$t
      lines+=("$label")
    done

    # No --cache-file default means wofi reorders by usage over time; pinning it
    # to /dev/null keeps the list in a stable, predictable order. --lines sizes
    # the window to exactly the number of themes, so adding one never puts an
    # entry behind the hidden scrollbar.
    #
    # Anchored top-left as the mirror of swaync's top-right panel: both use a
    # 20px offset, which is gaps_out in hyprland.conf, so each sits off its
    # edge by the same amount a tiled window does. wofi honours waybar's
    # exclusive zone, so the 20 is measured from below the bar, not the screen
    # top - the corner lands at (20, 70) against swaync's (1672, 70).
    # close_on_focus_loss makes a click anywhere else dismiss the picker, the
    # way swaync's panel does. It is off by default in wofi and is not exposed
    # as a long flag, so it goes through -D. Verified against a control run:
    # without it the window survives another surface taking focus, with it the
    # window exits.
    choice=$(printf '%s\n' "${lines[@]}" | wofi --dmenu \
      -D close_on_focus_loss=true \
      --prompt "Theme" --cache-file=/dev/null \
      --width 340 --lines "${#lines[@]}" \
      --location top_left --xoffset 20 --yoffset 20 \
      --insensitive --hide-scroll --no-actions) || exit 0
    [[ -n "$choice" ]] || exit 0
    target=${BY_LABEL["$choice"]:-}
    [[ -n "$target" ]] || exit 0
    # Choosing the theme that is already applied is a no-op, not a re-render.
    [[ "$target" == "$current" ]] && exit 0
    ;;
  next)   target=${THEMES[$(( (cur_i + 1) % ${#THEMES[@]} ))]} ;;
  prev)   target=${THEMES[$(( (cur_i - 1 + ${#THEMES[@]}) % ${#THEMES[@]} ))]} ;;
  random)
    # Reroll until it differs from the current theme, unless there is only one.
    target=$current
    while [[ "$target" == "$current" && ${#THEMES[@]} -gt 1 ]]; do
      target=${THEMES[$((RANDOM % ${#THEMES[@]}))]}
    done
    ;;
  *)
    target=$1
    [[ -d "$BASE/themes/$target" ]] || { notify-send "Theme Switcher" "No such theme: $target"; exit 1; }
    ;;
esac

# apply-theme.sh writes current-theme.json itself, so there is no state to
# track here. Its own reloads (waybar, swaync, hyprctl) happen inside.
if out=$("$APPLY" "$target" 2>&1); then
  pretty=$(jq -r '.name // empty' "$BASE/themes/$target/theme.json" 2>/dev/null || true)
  notify-send -a theme-switcher "Theme Switcher" "Applied: ${pretty:-$target}"
else
  notify-send -a theme-switcher -u critical "Theme Switcher" "Failed on $target: $(printf '%s' "$out" | tail -1)"
  exit 1
fi
