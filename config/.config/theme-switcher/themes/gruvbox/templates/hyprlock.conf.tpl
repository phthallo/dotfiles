#source = $HOME/.cache/wal/colors-hyprland.conf

# BACKGROUND
background {
    monitor =
    #path = screenshot
    path = ~/dotfiles/assets/background.jpg
    #color = $background
    blur_passes = 2
    contrast = 1
    brightness = 0.5
    vibrancy = 0.2
    vibrancy_darkness = 0.2
}

# GENERAL
general {
    no_fade_in = false
    no_fade_out = false
    hide_cursor = false
    grace = 0
    disable_loading_bar = true
}

# AUTH
auth {
   fingerprint:enabled = true
}


# INPUT FIELD
input-field {
    monitor =
    size = 250, 60
    outline_thickness = 2
    dots_size = 0.2 # Scale of input-field height, 0.2 - 0.8
    dots_spacing = 0.35 # Scale of dots' absolute size, 0.0 - 1.0
    dots_center = true
    # 2px accent ring around the password field - the one part of the lock
    # screen that is chrome rather than photo, so it follows the theme.
    outer_color = {{border}}
    inner_color = rgba(0, 0, 0, 0.2)
    font_color = rgba(255, 255, 255, 1)
    fade_on_empty = false
    rounding = 10
    check_color = {{accent}}
    placeholder_text = <i><span foreground="#{{fg_hex}}">password...</span></i>
    hide_input = false
    position = 0, -200
    halign = center
    valign = center
}

# DATE
label {
  monitor =
  text = cmd[update:1000] echo "$(date +"%A, %B %d")"
  color = rgba(242, 243, 244, 0.75)
  font_size = 22
  font_family = 0xProto Nerd Font Mono
  position = 0, 300
  halign = center
  valign = center
}

# TIME
label {
  monitor = 
  text = cmd[update:1000] echo "$(date +"%-I:%M")"
  color = rgba(242, 243, 244, 0.75)
  font_size = 95
  font_family = 0xProto Nerd Font Mono
  position = 0, 200
  halign = center
  valign = center
}

# BATTERY
label {
  monitor =
  text = cmd[update:1000] echo "$($HOME/dotfiles/assets/scripts/battery.sh)"
  color = rgba(242, 243, 244, 0.60)
  font_size = 18
  font_family = 0xProto Nerd Font Mono
  position = 0, 350
  halign = center
  valign = center
}



# Profile Picture
image {
    monitor =
    path = $HOME/dotfiles/assets/profilepicture.jpg
    size = 100
    border_size = 2
    border_color = {{border}}
    position = 0, -100
    halign = center
    valign = center
}

# Bottom-right badge. Upstream pointed this at the config author's own machine
# (/home/justin/...), so it silently rendered nothing.
image {
    monitor =
    path = $HOME/dotfiles/assets/profilepicture.jpg
    size = 75
    border_size = 2
    border_color = {{border}}
    position = -50, 50
    halign = right
    valign = bottom
}

# CURRENT SONG
label {
    monitor =
    text = cmd[update:1000] echo "$($HOME/dotfiles/assets/scripts/music.sh)" 
    color = rgba(255, 255, 255, 1)
    #color = rgba(255, 255, 255, 0.6)
    font_size = 18
    font_family = 0xProto Nerd Font Mono, Font Awesome 7 Free Solid
    position = 0, 50
    halign = center
    valign = bottom
}

label {
    monitor =
    text = cmd[update:1000] echo "$($HOME/dotfiles/assets/scripts/whoami.sh)"
    color = rgba(255, 255, 255, 1)
    font_size = 14
    font_family = 0xProto Nerd Font Mono
    position = 0, -10
    halign = center
    valign = top
}

#label {
#    monitor =
#    text = cmd[update:1000] echo "$($HOME/dotfiles/assets/scripts/battery.sh)"
#    color = $foreground
#    font_size = 24
#    font_family = JetBrains Mono
#    position = -90, -10
#    halign = right
#    valign = top
#}

label {
    monitor =
    text = cmd[update:1000] echo "$($HOME/dotfiles/assets/scripts/network-status.sh)"
    color = rgba(255, 255, 255, 1)
    font_size = 24
    font_family = 0xProto Nerd Font Mono
    position = -20, -10
    halign = right
    valign = top
}
