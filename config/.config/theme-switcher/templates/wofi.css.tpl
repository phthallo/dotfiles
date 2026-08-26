/* Shared palette first - GTK requires @import ahead of every rule. */
@import url("file://{{chrome_css}}");

/* The picker is styled as a small swaync control center: same solid surface,
   same 2px focused-window border, same 12px corner, same 16px gutter, same
   font. swaync pins 0xProto rather than the theme's family because its button
   grid and slider glyphs come from that Nerd Font build; matching it here is
   what makes the two windows read as one system rather than two apps. */

window {
  background: transparent;
  font-family: "0xProto Nerd Font", "0xProto", monospace;
  font-size: 15px;
}

#outer-box {
  background: @chrome_bg;
  color: @chrome_fg;
  border: 2px solid @chrome_border;
  border-radius: 12px;
  padding: 16px;
}

/* 14px below the entry matches swaync's gap between widget blocks. */
#input {
  margin-bottom: 14px;
  padding: 10px 12px;
  border-radius: 12px;
  background: @chrome_surface;
  color: @chrome_fg;
  outline: none;
  box-shadow: none;
  border: 2px solid transparent;
}

#input:focus {
  outline: none;
  box-shadow: none;
  border: 2px solid @chrome_accent;
}

#input image {
  color: @chrome_fg_dim;
}

/* 4px apart, the same rhythm as swaync's sibling cards. */
#entry {
  padding: 8px 10px;
  margin: 2px 0;
  border-radius: 12px;
  color: @chrome_fg;
}

#entry:hover {
  background: @chrome_surface;
}

#entry:selected {
  background: @chrome_accent;
}

#entry:selected #text {
  color: @chrome_bg;
  font-weight: 600;
}

#text {
  margin-left: 8px;
  color: @chrome_fg;
}

#scroll {
  margin: 0;
}
